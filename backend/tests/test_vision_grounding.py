import os
import io
import json
import pytest
from dotenv import load_dotenv, dotenv_values
from PIL import Image, ImageDraw
import google.generativeai as genai
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", ".env"), override=True)

def test_gemini_vision_real_call():
    env_vals = dotenv_values(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))
    api_key = env_vals.get("GEMINI_API_KEY") or os.getenv("GEMINI_API_KEY")
    if not api_key or api_key.startswith("test_"):
        pytest.skip("Live GEMINI_API_KEY not configured for live test")
    genai.configure(api_key=api_key, transport="rest")
    model = genai.GenerativeModel("gemini-2.5-flash")

    # Create a simple synthetic image representing a plant leaf
    img = Image.new("RGB", (300, 300), color=(34, 139, 34))
    draw = ImageDraw.Draw(img)
    draw.ellipse((50, 50, 250, 250), fill=(218, 165, 32)) # yellow spot

    prompt = (
        "You are an expert plant pathologist. "
        "Describe this image and indicate if it looks like a healthy leaf, "
        "a leaf with chlorosis/spotting, or a non-plant drawing. "
        "Respond in 1-2 concise sentences."
    )
    response = model.generate_content([prompt, img])
    assert response.text
    print("\n[REAL VISION CALL RESULT]:", response.text.strip())
