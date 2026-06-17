from fastapi import APIRouter, Request, Query
from pydantic import BaseModel
from services.gemini_service import generate_scheme_guide

router = APIRouter()

def _scheme_matches(scheme: dict, state_clean: str, crop: str = "", size: str = "") -> bool:
    """Check if a scheme matches the farmer's state, crop, and farm size."""
    # ── State filter ─────────────────────────────────────────────────────
    states_raw = scheme.get("states", [])
    if states_raw:
        states = [s.lower() for s in states_raw]
        if "all" not in states and state_clean not in states:
            return False

    # ── Crop filter (optional — only filter if scheme specifies crops) ───
    scheme_crops = scheme.get("crops", [])
    if scheme_crops and crop:
        crop_lower = crop.strip().lower()
        scheme_crops_lower = [c.lower() for c in scheme_crops]
        if "all" not in scheme_crops_lower and crop_lower not in scheme_crops_lower:
            return False

    # ── Farm size filter (optional) ─────────────────────────────────────
    # size is like "1-2", "2-5", "5+" acres
    # Scheme may have "max_acres" field to restrict to marginal/small farmers
    max_acres = scheme.get("max_acres")
    if max_acres is not None and size:
        try:
            # Parse the lower bound of the farmer's size range
            farmer_min = float(size.split("-")[0].replace("+", "").strip())
            if farmer_min > float(max_acres):
                return False
        except (ValueError, IndexError):
            pass  # If parsing fails, don't filter

    return True


@router.get("/schemes")
async def get_schemes_query(
    request: Request,
    crop: str = Query("Tomato"),
    state: str = Query("Maharashtra"),
    size: str = Query("1-2")
):
    """Get government schemes filtered by state, crop, and farm size."""
    all_schemes = getattr(request.app.state, "schemes", [])
    state_clean = state.strip().lower()
    filtered = [s for s in all_schemes if _scheme_matches(s, state_clean, crop, size)]
    return {"schemes": filtered}


class SchemesRequest(BaseModel):
    state: str
    crop_type: str


class SchemeGuideRequest(BaseModel):
    scheme_name: str
    benefit_description: str
    district: str
    state: str
    language: str


@router.post("/api/schemes")
async def schemes(req: SchemesRequest, request: Request):
    """Government scheme filtering from loaded JSON data."""
    all_schemes = getattr(request.app.state, "schemes", [])
    state_clean = req.state.strip().lower()
    filtered = [s for s in all_schemes if _scheme_matches(s, state_clean, req.crop_type)]
    return {"schemes": filtered}

@router.post("/api/scheme-guide")
async def scheme_guide(req: SchemeGuideRequest):
    """Generate localized scheme application guide via Gemini."""
    guide = await generate_scheme_guide(
        scheme_name=req.scheme_name,
        benefit_description=req.benefit_description,
        district=req.district,
        state=req.state,
        language=req.language
    )
    return guide
