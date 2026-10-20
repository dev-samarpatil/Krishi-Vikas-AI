import os
import sys
import unittest
from unittest.mock import patch, MagicMock, AsyncMock
from fastapi.testclient import TestClient

# Ensure backend directory is in sys.path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from main import app
from services.gemini_service import UpstreamAIServiceError

client = TestClient(app)

class TestChatbotRegression(unittest.TestCase):
    """
    Automated regression tests covering the chat endpoint, contract,
    error states, input validation, and provider fallback behavior.
    """

    def setUp(self):
        # Set dummy keys so config verification passes by default
        os.environ["GEMINI_API_KEY"] = "AIzaSyTestKeyDummy1234567890"
        os.environ["GROQ_API_KEY"] = "gsk_testgroqkeydummy1234567890"

    # 1. Simple greeting: "hi"
    @patch("routes.chat.chat_with_farmer")
    def test_01_simple_greeting(self, mock_chat):
        mock_chat.return_value = {
            "reply": "Hello! How can I help your farm today?",
            "response": "Hello! How can I help your farm today?",
            "intent_type": "general",
            "provider": "gemini/gemini-2.5-flash",
            "success": True,
        }
        res = client.post("/api/chat", json={"message": "hi", "language": "en"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertIn("Hello", data.get("reply"))
        self.assertIn("request_id", data)

    # 2. Soybean cultivation query
    @patch("routes.chat.chat_with_farmer")
    def test_02_soybean_cultivation_query(self, mock_chat):
        advice_text = "Problem: Soil preparation\nImmediate Action: Sowing at 3-4 cm depth with Rhizobium treatment."
        mock_chat.return_value = {
            "reply": advice_text,
            "response": advice_text,
            "intent_type": "general",
            "provider": "gemini/gemini-2.5-flash",
            "success": True,
        }
        res = client.post(
            "/api/chat",
            json={
                "message": "steps to grow soybean",
                "language": "en",
                "crop": "Soybean",
                "district": "Nashik"
            }
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertIn("Rhizobium", data.get("response"))
        self.assertEqual(data.get("reply"), data.get("response"))

    # 3. Marathi agricultural query
    @patch("routes.chat.chat_with_farmer")
    def test_03_marathi_agricultural_query(self, mock_chat):
        marathi_text = "सोयाबीन लागवडीसाठी जमीन चांगली भुसभुशीत करा."
        mock_chat.return_value = {
            "reply": marathi_text,
            "response": marathi_text,
            "intent_type": "general",
            "provider": "gemini/gemini-2.5-flash",
            "success": True,
        }
        res = client.post(
            "/api/chat",
            json={
                "message": "सोयाबीनची लागवड कशी करावी?",
                "language": "mr",
                "district": "Pune"
            }
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertIn("सोयाबीन", data.get("reply"))

    # 4. Empty message validation
    def test_04_empty_message_validation(self):
        res = client.post("/api/chat", json={"message": "   ", "language": "en"})
        self.assertEqual(res.status_code, 400)
        data = res.json()
        self.assertFalse(data.get("success"))
        self.assertEqual(data.get("error", {}).get("code"), "EMPTY_MESSAGE")
        self.assertFalse(data.get("error", {}).get("retryable"))

    # 5. Malformed request body
    def test_05_malformed_request_body(self):
        # Missing required 'message' field
        res = client.post("/api/chat", json={"language": "en"})
        self.assertEqual(res.status_code, 422)

    # 6. Missing API keys configuration error
    def test_06_missing_api_keys(self):
        with patch.dict(os.environ, {"GEMINI_API_KEY": "", "GROQ_API_KEY": ""}, clear=True):
            res = client.post("/api/chat", json={"message": "hi", "language": "en"})
            self.assertEqual(res.status_code, 503)
            data = res.json()
            self.assertFalse(data.get("success"))
            self.assertEqual(data.get("error", {}).get("code"), "CONFIG_ERROR")
            self.assertFalse(data.get("error", {}).get("retryable"))

    # 7. Gemini upstream error handling with structured response
    @patch("routes.chat.chat_with_farmer")
    def test_07_gemini_upstream_failure(self, mock_chat):
        mock_chat.side_effect = UpstreamAIServiceError(
            message="The AI assistant is temporarily unavailable. Please try again in a moment.",
            code="UPSTREAM_UNAVAILABLE",
            retryable=True
        )
        res = client.post("/api/chat", json={"message": "steps to grow wheat", "language": "en"})
        self.assertEqual(res.status_code, 503)
        data = res.json()
        self.assertFalse(data.get("success"))
        self.assertEqual(data.get("error", {}).get("code"), "UPSTREAM_UNAVAILABLE")
        self.assertTrue(data.get("error", {}).get("retryable"))
        self.assertIn("request_id", data.get("error", {}))

    # 8. Unhandled server exception returns 500 with request_id without exposing internals
    @patch("routes.chat.chat_with_farmer")
    def test_08_internal_error_hides_secrets(self, mock_chat):
        mock_chat.side_effect = RuntimeError("Critical database driver crash at 10.0.0.1 with secret key xyz")
        res = client.post("/api/chat", json={"message": "test query", "language": "en"})
        self.assertEqual(res.status_code, 500)
        data = res.json()
        self.assertFalse(data.get("success"))
        # Must not expose the raw exception message or server IP/secret
        self.assertNotIn("10.0.0.1", str(data))
        self.assertNotIn("xyz", str(data))
        self.assertEqual(data.get("error", {}).get("code"), "INTERNAL_SERVER_ERROR")

    # 9. Mandi price keyword intercept
    @patch("routes.chat.fetch_mandi_prices")
    @patch("routes.chat.chat_with_farmer")
    def test_09_mandi_price_interceptor(self, mock_chat, mock_mandi):
        mock_mandi.return_value = [
            {"market": "Nashik APMC", "modal_price": 2800, "min_price": 2400, "max_price": 3100}
        ]
        mock_chat.return_value = {
            "reply": "Current market price for Onion in Nashik APMC is ₹2800/Quintal.",
            "response": "Current market price for Onion in Nashik APMC is ₹2800/Quintal.",
            "intent_type": "general",
            "provider": "gemini/gemini-2.5-flash",
            "success": True,
        }
        res = client.post(
            "/api/chat",
            json={
                "message": "what is onion mandi bhav today?",
                "crop": "Onion",
                "district": "Nashik",
                "language": "en"
            }
        )
        self.assertEqual(res.status_code, 200)
        mock_mandi.assert_called_once()

    # 10. Backward compatibility with legacy farm-scoped path
    @patch("routes.chat.chat_with_farmer")
    def test_10_farm_scoped_chat_endpoint(self, mock_chat):
        mock_chat.return_value = {
            "reply": "Farm chat response",
            "response": "Farm chat response",
            "intent_type": "general",
            "provider": "gemini/gemini-2.5-flash",
            "success": True,
        }
        res = client.post("/farms/farm-123/chat", json={"message": "check farm status", "language": "en"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertEqual(data.get("reply"), "Farm chat response")

if __name__ == "__main__":
    unittest.main()
