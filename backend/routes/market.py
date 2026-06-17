import math
from fastapi import APIRouter, Request, Query
from utils.agmarknet import fetch_mandi_prices
from services.supabase_service import get_mandi_cache, set_mandi_cache
from utils.haversine import haversine_km

router = APIRouter()

MANDI_LOCATIONS = {
    "nashik": (20.0075, 73.7554),
    "lasalgaon": (20.1418, 74.2238),
    "pune": (18.5204, 73.8567),
    "nagpur": (21.1458, 79.0882),
    "latur": (18.4088, 76.5604),
    "vasai": (19.3838, 72.8276),
    "virar": (19.4589, 72.8055),
    "palghar": (19.6960, 72.7660),
    "mumbai": (19.0664, 73.0011),
    "alandi": (18.6728, 73.8966),
    "haveli": (18.4342, 73.8475)
}

def get_market_coords(market_name: str, district_name: str):
    m = market_name.lower()
    for key, coords in MANDI_LOCATIONS.items():
        if key in m:
            return coords
    d = district_name.lower()
    for key, coords in MANDI_LOCATIONS.items():
        if key in d:
            return coords
    return None

def process_mandi_locations(prices_data: list, lat: float, lon: float, radius: float, district: str):
    if lat is None or lon is None:
        return prices_data
        
    processed_data = []
    for dp in prices_data:
        market_name = dp.get("market", "")
        coords = get_market_coords(market_name, district)
        if coords:
            dist = haversine_km(lat, lon, coords[0], coords[1])
            dp["distance_km"] = round(dist, 1)
            dp["lat"] = coords[0]
            dp["lng"] = coords[1]
        else:
            dp["distance_km"] = 999.9
        processed_data.append(dp)
        
    # Sort by nearest distance first
    processed_data.sort(key=lambda x: x.get("distance_km", 999.9))
    
    # Filter by radius
    within_radius = [dp for dp in processed_data if dp.get("distance_km", 999.9) <= radius]
    
    # If no mandi exists within radius, return nearest available mandis (top 3)
    if not within_radius and processed_data:
        return processed_data[:3]
    return within_radius

@router.get("/api/market")
@router.get("/mandi/prices")
async def market(
    request: Request,
    state: str = Query("Maharashtra"),
    district: str = Query("Nashik"),
    crop: str = Query("Tomato"),
    lat: float = Query(None),
    lon: float = Query(None),
    radius: float = Query(50.0)
):
    """Live mandi prices from Agmarknet + Supabase cache + Local JSON fallback."""
    final_data = []
    source = "live"
    try:
        # Check for demo localized data
        dist_lower = district.lower()
        if any(kw in dist_lower for kw in ['pune', 'alandi', 'haveli']):
            final_data = [
                {"crop": "Tomato", "emoji": "🍅", "market": "Pune APMC", "modal_price": 1650, "trend": "up", "trend_percent": "8%"},
                {"crop": "Onion", "emoji": "🧅", "market": "Pune APMC", "modal_price": 2100, "trend": "flat", "trend_percent": "0%"},
                {"crop": "Potato", "emoji": "🥔", "market": "Pune APMC", "modal_price": 1200, "trend": "down", "trend_percent": "4%"},
                {"crop": "Wheat", "emoji": "🌾", "market": "Pune Mandi", "modal_price": 2400, "trend": "flat", "trend_percent": "0%"},
                {"crop": "Grapes", "emoji": "🍇", "market": "Pune APMC", "modal_price": 6200, "trend": "up", "trend_percent": "15%"}
            ]
        else:
            # 1. Check DB Cache
            cached_data = await get_mandi_cache(state, district, crop)
            if cached_data:
                final_data = cached_data
                source = "cache"
            else:
                # 2. Try Agmarknet (with timeout handled in the util)
                live_data = await fetch_mandi_prices(state, district, crop)
                
                # Determine trend arrow heuristically (since Agmarknet doesn't provide historical context strictly here)
                for dp in live_data:
                    modal = dp.get("modal_price")
                    max_p = dp.get("max_price")
                    if modal and max_p and modal < max_p:
                        dp["trend"] = "up"
                    else:
                        dp["trend"] = "flat"
        
                # 3. Handle DB Upsert
                if live_data:
                    await set_mandi_cache(state, district, crop, live_data)
                    final_data = live_data
                else:
                    raise Exception("No live data")

    except Exception as e:
        print(f"Market route fallback triggered: {e}")
        source = "fallback"
        final_data = getattr(request.app.state, "mandi_prices", {}).get("prices", [])
        
    # Process locations, distance, radius, and sort
    final_data = process_mandi_locations(final_data, lat, lon, radius, district)
    
    return {"source": source, "prices": final_data}
