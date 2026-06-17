import os
from supabase import create_client, Client

SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "").strip()

_client: Client | None = None


def get_supabase() -> Client | None:
    """Get or create Supabase client (lazy init)."""
    global _client
    if _client is not None:
        return _client
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("[WARNING] Supabase credentials not set — database features disabled")
        return None
    try:
        _client = create_client(SUPABASE_URL, SUPABASE_KEY)
        return _client
    except Exception as e:
        print(f"Supabase init error: {e}")
        return None


async def save_diagnosis(
    farmer_id: str,
    disease_name: str,
    confidence: float,
    lat: float,
    long: float,
    district: str,
    crop_type: str,
    farm_id: str = "",
    treatment_chosen: str = "",
) -> dict | None:
    """Save a diagnosis record to the diagnoses table."""
    client = get_supabase()
    if client is None:
        return None

    try:
        result = (
            client.table("diagnoses")
            .insert(
                {
                    "farmer_id": farmer_id,
                    "disease_name": disease_name,
                    "confidence": confidence,
                    "lat": lat,
                    "long": long,
                    "district": district,
                    "crop_type": crop_type,
                    "farm_id": farm_id if farm_id else None,
                    "treatment_chosen": treatment_chosen,
                }
            )
            .execute()
        )
        return result.data[0] if result.data else None
    except Exception as e:
        print(f"Supabase save_diagnosis error: {e}")
        return None


async def log_treatment(
    farmer_id: str,
    diagnosis_id: str,
    treatment_type: str,
) -> dict | None:
    """Log a treatment choice (organic/chemical) and update soil health score."""
    client = get_supabase()
    if client is None:
        return None

    try:
        # Update the original diagnosis with the chosen treatment
        client.table("diagnoses").update(
            {"treatment_chosen": treatment_type}
        ).eq("id", diagnosis_id).execute()

        # Insert treatment log
        client.table("treatment_logs").insert(
            {
                "farmer_id": farmer_id,
                "diagnosis_id": diagnosis_id,
                "treatment_type": treatment_type,
            }
        ).execute()

        # Recalculate dynamic soil score for the farm
        farm_id_resp = client.table("diagnoses").select("farm_id").eq("id", diagnosis_id).execute()
        farm_id = None
        if farm_id_resp.data and farm_id_resp.data[0].get("farm_id"):
            farm_id = farm_id_resp.data[0]["farm_id"]
            
        new_score = 50
        badges = []
        if farm_id:
            profile = await get_farm_soil_health(farm_id)
            new_score = profile.get("soil_score", 50)
            badges = profile.get("badges", [])
        else:
            profile = await get_farmer_profile(farmer_id)
            new_score = profile.get("soil_health_score", 50)
            badges = profile.get("badges", [])

        return {
            "new_score": new_score,
            "badge_earned": badges[0] if badges else None,
            "treatment_type": treatment_type,
        }

    except Exception as e:
        print(f"Supabase log_treatment error: {e}")
        return {"new_score": 50, "badge_earned": None, "treatment_type": treatment_type}

from datetime import datetime, timedelta, timezone

async def get_mandi_cache(state: str, district: str, commodity: str) -> list[dict] | None:
    """Retrieve Mandi prices from cache if < 6 hours old."""
    client = get_supabase()
    if client is None: return None
    try:
        resp = client.table("mandi_cache")\
            .select("data, created_at")\
            .eq("state", state)\
            .eq("district", district)\
            .eq("commodity", commodity)\
            .maybe_single().execute()
        
        if not resp.data: return None
        
        created_at = datetime.fromisoformat(resp.data["created_at"].replace('Z', '+00:00'))
        if datetime.now(timezone.utc) - created_at < timedelta(hours=6):
            return resp.data["data"]
        return None
    except Exception as e:
        print(f"Supabase cache error: {e}")
        return None

async def set_mandi_cache(state: str, district: str, commodity: str, data: list[dict]):
    """Upsert Mandi prices to cache."""
    client = get_supabase()
    if client is None: return
    try:
        # Check if row exists for upsert behavior (supabase-py sometimes struggles with native upsert)
        resp = client.table("mandi_cache").select("id").eq("state", state).eq("district", district).eq("commodity", commodity).maybe_single().execute()
        if resp.data:
            client.table("mandi_cache").update({"data": data, "created_at": "now()"}).eq("id", resp.data["id"]).execute()
        else:
            client.table("mandi_cache").insert({"state": state, "district": district, "commodity": commodity, "data": data}).execute()
    except Exception as e:
        print(f"Supabase cache set error: {e}")

async def get_farmer_profile(farmer_id: str) -> dict:
    """Calculate soil health score dynamically based on diagnosis history."""
    client = get_supabase()
    # Mock data fallback if DB fails
    mock = {"soil_health_score": 60, "badges": ["🌱 Soil Guardian"]}
    if client is None: return mock
    
    try:
        score = 60 # Base score
        
        # Get history of last 10 diagnoses
        resp = client.table("diagnoses")\
            .select("disease_name, treatment_chosen")\
            .eq("farmer_id", farmer_id)\
            .order("created_at", desc=True)\
            .limit(10)\
            .execute()
            
        if resp.data:
            for diag in resp.data:
                name = diag.get("disease_name", "").lower()
                treatment = diag.get("treatment_chosen", "")
                if treatment:
                    treatment = treatment.lower()
                
                # Deduct based on disease/deficiency type
                if "deficiency" in name:
                    if "nitrogen" in name or "phosphorous" in name or "potassium" in name:
                        score -= 15
                    else:
                        score -= 10
                elif "blight" in name or "rust" in name or "virus" in name or "wilt" in name:
                    score -= 10
                elif "pest" in name or "borer" in name or "hopper" in name or "mite" in name or "aphid" in name:
                    score -= 5
                else:
                    score -= 2 # Generic penalty
                    
                # Add based on treatment
                if treatment == "organic":
                    score += 10
                elif treatment == "chemical":
                    score += 2
                    
        # Clamp score between 10 and 100
        score = max(10, min(100, score))
        
        badges = []
        if score >= 80: badges.append("🌿 Organic Champion")
        elif score >= 60: badges.append("🌱 Soil Guardian")
        
        # Save updated score back to profile
        try:
            profile_resp = client.table("farmer_profiles").select("id").eq("id", farmer_id).maybe_single().execute()
            if profile_resp.data:
                client.table("farmer_profiles").update({"soil_health_score": score}).eq("id", farmer_id).execute()
            else:
                client.table("farmer_profiles").insert({"id": farmer_id, "soil_health_score": score}).execute()
        except:
            pass

        return {"soil_health_score": score, "badges": badges}
    except Exception as e:
        print(f"Supabase get_farmer_profile error: {e}")
        return mock

async def get_farm_soil_health(farm_id: str) -> dict:
    """Calculate dynamic soil health score based on real farm activity.
    
    Scoring model:
      Base Score    = 70
      Healthy scan  = +2 per scan
      Mild disease  = -5  (confidence < 0.70)
      Moderate      = -10 (confidence 0.70–0.84)
      Severe        = -20 (confidence >= 0.85)
      Treatment logged (organic/chemical) = +5
      Repeated disease occurrence = -5 additional
      Bounds: 0–100
    """
    client = get_supabase()
    mock = {"soil_score": 70, "badges": ["🌱 Soil Guardian"]}
    if client is None:
        return mock

    try:
        score = 70  # Base score

        # Fetch last 10 diagnoses for this farm
        resp = (
            client.table("diagnoses")
            .select("disease_name, confidence, treatment_chosen")
            .eq("farm_id", farm_id)
            .order("created_at", desc=True)
            .limit(10)
            .execute()
        )

        disease_counts: dict[str, int] = {}

        if resp.data:
            for diag in resp.data:
                name = str(diag.get("disease_name") or "").lower().strip()
                treatment = str(diag.get("treatment_chosen") or "").lower().strip()
                conf = float(diag.get("confidence") or 0.0)

                is_healthy = not name or "healthy" in name

                if is_healthy:
                    score += 2  # Healthy scan bonus
                else:
                    # Repeated disease penalty
                    disease_counts[name] = disease_counts.get(name, 0) + 1
                    if disease_counts[name] > 1:
                        score -= 5

                    # Severity penalty based on AI confidence
                    if conf >= 0.85:
                        score -= 20  # Severe
                    elif conf >= 0.70:
                        score -= 10  # Moderate
                    else:
                        score -= 5   # Mild

                # Treatment bonus
                if treatment in ("organic", "chemical"):
                    score += 5

        # Hard bounds
        score = max(0, min(100, score))

        badges = []
        if score >= 81:
            badges.append("🌿 Organic Champion")
        elif score >= 61:
            badges.append("🌱 Soil Guardian")

        # Persist updated score back to the farm row
        try:
            client.table("farms").update({"soil_score": score}).eq("id", farm_id).execute()
        except Exception:
            pass

        return {"soil_score": score, "badges": badges}

    except Exception as e:
        print(f"Supabase get_farm_soil_health error: {e}")
        return mock

async def get_farm_history(farmer_id: str) -> list[dict]:
    """Fetch the last 10 diagnoses."""
    client = get_supabase()
    if client is None: return []
    try:
        resp = client.table("diagnoses")\
            .select("id, disease_name, crop_type, created_at, treatment_chosen")\
            .eq("farmer_id", farmer_id)\
            .order("created_at", desc=True)\
            .limit(10)\
            .execute()
        return resp.data or []
    except Exception as e:
        print(f"Supabase get_farm_history error: {e}")
        return []
