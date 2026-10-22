import io
import json
import os
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from PIL import Image

from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))

os.environ.setdefault("GEMINI_API_KEY", "test_gemini_key")
os.environ.setdefault("SUPABASE_URL", "https://mock.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "mock_key")

from main import app

client = TestClient(app)

def create_test_image_bytes(format="JPEG", color=(34, 139, 34)):
    img = Image.new("RGB", (100, 100), color=color)
    buf = io.BytesIO()
    img.save(buf, format=format)
    return buf.getvalue()

def test_diagnose_empty_image_rejected():
    """Empty or missing image file must be rejected."""
    response = client.post(
        "/api/diagnose",
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 422 # Unprocessable Entity

def test_diagnose_invalid_image_format_rejected():
    """Non-image bytes must return 400 Bad Request."""
    response = client.post(
        "/api/diagnose",
        files={"image": ("bad.txt", b"not an image file", "text/plain")},
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 400
    assert "Invalid image format" in response.json().get("error", "")

@patch("routes.diagnose.get_model")
def test_diagnose_non_crop_detection_not_forced_into_disease(mock_get_model):
    """When vision model detects non-crop image, it must not return a fake crop disease."""
    mock_model = MagicMock()
    mock_response = MagicMock()
    mock_response.text = json.dumps({
        "type": "invalid_image",
        "name": "Non-crop Image Detected",
        "name_local": "फसल की तस्वीर नहीं है",
        "confidence": 0.0,
        "severity": "none",
        "urgency": "none",
        "explanation": "The image does not show a crop leaf.",
        "cause": "Non-agricultural subject.",
        "treatment_steps": [],
        "organic_option": {"description": "N/A", "steps": []},
        "prevention": "Please upload a clear crop photo.",
        "budget_items": [],
        "total_cost_inr": 0,
        "organic_total_cost_inr": 0,
        "low_confidence_note": "Please upload a clear photograph of an agricultural crop leaf."
    })
    mock_model.generate_content.return_value = mock_response
    mock_get_model.return_value = mock_model

    img_bytes = create_test_image_bytes()
    response = client.post(
        "/api/diagnose",
        files={"image": ("test.jpg", img_bytes, "image/jpeg")},
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["type"] == "invalid_image"
    assert data["name"] == "Non-crop Image Detected"
    assert data["confidence"] == 0.0
    # Must NOT have fake disease or treatment cost
    assert data["total_cost_inr"] == 0

@patch("routes.diagnose.get_model")
def test_diagnose_unparseable_gemini_response_returns_502_not_fake_disease(mock_get_model):
    """If Gemini produces unparseable garbage, never return 'Leaf Disease Detected'."""
    mock_model = MagicMock()
    mock_response = MagicMock()
    mock_response.text = "I am an AI and I think this leaf has problems but I won't give JSON"
    mock_model.generate_content.return_value = mock_response
    mock_get_model.return_value = mock_model

    img_bytes = create_test_image_bytes()
    response = client.post(
        "/api/diagnose",
        files={"image": ("test.jpg", img_bytes, "image/jpeg")},
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 502
    data = response.json()
    assert data["success"] is False
    assert data["error"]["code"] == "MODEL_RESPONSE_INVALID"

@patch("routes.diagnose.save_diagnosis", new_callable=AsyncMock)
@patch("routes.diagnose.get_model")
def test_diagnose_valid_disease_parsed_and_saved(mock_get_model, mock_save_diagnosis):
    """Valid diagnosis contains calibrated confidence and is saved."""
    mock_save_diagnosis.return_value = {"id": "diag-123"}
    mock_model = MagicMock()
    mock_response = MagicMock()
    mock_response.text = json.dumps({
        "type": "disease",
        "name": "Early Blight",
        "name_local": "अगेती झुलसा",
        "confidence": 0.88,
        "severity": "medium",
        "urgency": "immediate",
        "explanation": "Concentric rings visible on lower leaves typical of Alternaria solani.",
        "cause": "Alternaria solani fungus",
        "treatment_steps": ["Remove lower infected leaves", "Spray Mancozeb @ 2g/L water"],
        "organic_option": {"description": "Trichoderma viride spray", "steps": ["Spray 5g/L on foliage"]},
        "prevention": "Ensure good spacing and drip irrigation",
        "budget_items": [{"item": "Mancozeb", "quantity": "250g", "price_inr": 120}],
        "total_cost_inr": 120,
        "organic_total_cost_inr": 80,
        "low_confidence_note": None
    })
    mock_model.generate_content.return_value = mock_response
    mock_get_model.return_value = mock_model

    img_bytes = create_test_image_bytes()
    response = client.post(
        "/api/diagnose",
        files={"image": ("leaf.jpg", img_bytes, "image/jpeg")},
        data={"crop_type": "Tomato", "farmer_id": "test_farmer"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Early Blight"
    assert data["confidence"] == 0.88
    assert data["severity"] == "medium"
    assert data["diagnosis_id"] == "diag-123"
    assert mock_save_diagnosis.called

@patch("routes.diagnose.save_diagnosis", new_callable=AsyncMock)
@patch("routes.diagnose.get_model")
def test_diagnose_invalid_image_never_saved_to_supabase(mock_get_model, mock_save_diagnosis):
    """Invalid image results must never be stored as disease records in Supabase."""
    mock_model = MagicMock()
    mock_response = MagicMock()
    mock_response.text = json.dumps({
        "type": "invalid_image",
        "name": "Non-crop Image Detected",
        "name_local": "फसल की तस्वीर नहीं है",
        "confidence": 0.0,
        "severity": "none",
        "urgency": "none",
        "explanation": "No plant detected.",
        "cause": "Non-plant",
        "treatment_steps": [],
        "organic_option": {"description": "", "steps": []},
        "prevention": "",
        "budget_items": [],
        "total_cost_inr": 0,
        "organic_total_cost_inr": 0,
        "low_confidence_note": None
    })
    mock_model.generate_content.return_value = mock_response
    mock_get_model.return_value = mock_model

    img_bytes = create_test_image_bytes()
    response = client.post(
        "/api/diagnose",
        files={"image": ("photo.jpg", img_bytes, "image/jpeg")},
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 200
    assert not mock_save_diagnosis.called, "Invalid image should NOT be saved in farm disease history!"


@patch("routes.diagnose.get_model")
def test_diagnose_gemini_quota_exceeded_returns_429(mock_get_model):
    """When Gemini returns TooManyRequests/429, backend must return 429 rate_limited, not 500."""
    from google.api_core.exceptions import TooManyRequests
    mock_model = MagicMock()
    mock_model.generate_content.side_effect = TooManyRequests("Quota exceeded for model")
    mock_get_model.return_value = mock_model

    img_bytes = create_test_image_bytes()
    response = client.post(
        "/api/diagnose",
        files={"image": ("crop.jpg", img_bytes, "image/jpeg")},
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 429
    data = response.json()
    assert data["success"] is False
    assert data["status"] == "rate_limited"
    assert data["error"]["code"] == "AI_QUOTA_EXCEEDED"
    assert "temporarily busy" in data["error"]["message"]


@patch("routes.diagnose.get_model")
def test_diagnose_gemini_auth_failure_returns_503(mock_get_model):
    """When Gemini auth fails (PermissionDenied/Unauthenticated), backend returns 503 without leaking keys."""
    from google.api_core.exceptions import PermissionDenied
    mock_model = MagicMock()
    mock_model.generate_content.side_effect = PermissionDenied("API key invalid")
    mock_get_model.return_value = mock_model

    img_bytes = create_test_image_bytes()
    response = client.post(
        "/api/diagnose",
        files={"image": ("crop.jpg", img_bytes, "image/jpeg")},
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 503
    data = response.json()
    assert data["success"] is False
    assert data["error"]["code"] == "AI_SERVICE_UNAVAILABLE"
    # Ensure no credentials or keys in error message
    assert "AIza" not in json.dumps(data)
    assert "traceback" not in data


@patch("routes.diagnose.get_model")
def test_diagnose_gemini_network_timeout_returns_503(mock_get_model):
    """When Gemini call times out, backend returns 503 service unavailable."""
    from google.api_core.exceptions import DeadlineExceeded
    mock_model = MagicMock()
    mock_model.generate_content.side_effect = DeadlineExceeded("Deadline exceeded")
    mock_get_model.return_value = mock_model

    img_bytes = create_test_image_bytes()
    response = client.post(
        "/api/diagnose",
        files={"image": ("crop.jpg", img_bytes, "image/jpeg")},
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 503
    data = response.json()
    assert data["success"] is False
    assert data["error"]["code"] == "AI_SERVICE_UNAVAILABLE"


def test_diagnose_payload_too_large_returns_413():
    """Images exceeding the 15MB limit must return 413 Payload Too Large."""
    oversized_bytes = b"0" * (16 * 1024 * 1024)
    response = client.post(
        "/api/diagnose",
        files={"image": ("huge.jpg", oversized_bytes, "image/jpeg")},
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 413
    data = response.json()
    assert data["success"] is False
    assert data["error"]["code"] == "PAYLOAD_TOO_LARGE"


def test_diagnose_live_integration_real_model():
    """Live integration test against configured Gemini Vision service."""
    from dotenv import dotenv_values
    env_vals = dotenv_values(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))
    api_key = env_vals.get("GEMINI_API_KEY")
    if not api_key or api_key.startswith("test_"):
        pytest.skip("Live GEMINI_API_KEY not configured for live test")

    vision_model = env_vals.get("GEMINI_VISION_MODEL") or "gemini-flash-lite-latest"
    with patch.dict(os.environ, {"GEMINI_API_KEY": api_key, "GEMINI_VISION_MODEL": vision_model}):
        img_bytes = create_test_image_bytes(color=(34, 139, 34))
        response = client.post(
            "/api/diagnose",
            files={"image": ("leaf.jpg", img_bytes, "image/jpeg")},
            data={"crop_type": "Tomato", "language": "en"}
        )
        # The response must either be 200 (if model quota available) or 429 (if upstream quota hit)
        # but NEVER 500 internal server error!
        assert response.status_code in (200, 429), f"Unexpected status {response.status_code}: {response.text}"
        if response.status_code == 200:
            data = response.json()
            assert "name" in data
            assert "confidence" in data
        elif response.status_code == 429:
            data = response.json()
            assert data["error"]["code"] == "AI_QUOTA_EXCEEDED"


