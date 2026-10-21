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
from services.groq_service import UpstreamAIServiceError

client = TestClient(app)

class TestChatbotRegression(unittest.TestCase):
    """
    Automated regression tests covering the chat endpoint, contract,
    error states, input validation, and provider fallback behavior for Phase 1.
    """

    def setUp(self):
        # Set dummy keys so config verification passes by default
        os.environ["CHAT_PROVIDER"] = "groq"
        os.environ["GEMINI_API_KEY"] = "AIzaSyTestKeyDummy1234567890"
        os.environ["GROQ_API_KEY"] = "gsk_testgroqkeydummy1234567890"

    # 1. Simple greeting via Groq primary provider
    @patch("routes.chat.chat_with_groq")
    def test_01_simple_greeting_groq_primary(self, mock_chat_groq):
        mock_chat_groq.return_value = {
            "reply": "Hello! How can I help your farm today?",
            "response": "Hello! How can I help your farm today?",
            "intent_type": "general",
            "provider": "groq/qwen/qwen3.8-27b",
            "success": True,
        }
        res = client.post("/api/chat", json={"message": "hi", "language": "en"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertIn("Hello", data.get("reply"))
        self.assertEqual(data.get("provider"), "groq/qwen/qwen3.8-27b")
        self.assertIn("request_id", data)
        mock_chat_groq.assert_called_once()

    # 2. Soybean cultivation query
    @patch("routes.chat.chat_with_groq")
    def test_02_soybean_cultivation_query(self, mock_chat_groq):
        advice_text = "Problem: Soil preparation\nImmediate Action: Sowing at 3-4 cm depth with Rhizobium treatment."
        mock_chat_groq.return_value = {
            "reply": advice_text,
            "response": advice_text,
            "intent_type": "general",
            "provider": "groq/qwen/qwen3.8-27b",
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
    @patch("routes.chat.chat_with_groq")
    def test_03_marathi_agricultural_query(self, mock_chat_groq):
        marathi_text = "सोयाबीन लागवडीसाठी जमीन चांगली भुसभुशीत करा."
        mock_chat_groq.return_value = {
            "reply": marathi_text,
            "response": marathi_text,
            "intent_type": "general",
            "provider": "groq/qwen/qwen3.8-27b",
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

    # 7. Groq failure with fallback to Gemini
    @patch("routes.chat.chat_with_gemini")
    @patch("routes.chat.chat_with_groq")
    def test_07_groq_failure_fallback_to_gemini(self, mock_groq, mock_gemini):
        mock_groq.side_effect = UpstreamAIServiceError(
            message="Rate limit reached",
            code="RATE_LIMIT_ERROR",
            retryable=True
        )
        mock_gemini.return_value = {
            "reply": "Fallback advice from Gemini",
            "response": "Fallback advice from Gemini",
            "intent_type": "general",
            "provider": "gemini/gemini-2.5-flash",
            "success": True,
        }
        res = client.post("/api/chat", json={"message": "steps to grow wheat", "language": "en"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertIn("Fallback advice from Gemini", data.get("reply"))
        mock_groq.assert_called_once()
        mock_gemini.assert_called_once()

    # 8. Unhandled server exception returns 500 with request_id without exposing internals
    @patch("routes.chat.chat_with_groq")
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
    @patch("routes.chat.chat_with_groq")
    def test_09_mandi_price_interceptor(self, mock_chat, mock_mandi):
        mock_mandi.return_value = [
            {"market": "Nashik APMC", "modal_price": 2800, "min_price": 2400, "max_price": 3100}
        ]
        mock_chat.return_value = {
            "reply": "Current market price for Onion in Nashik APMC is ₹2800/Quintal.",
            "response": "Current market price for Onion in Nashik APMC is ₹2800/Quintal.",
            "intent_type": "general",
            "provider": "groq/qwen/qwen3.8-27b",
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
    @patch("routes.chat.chat_with_groq")
    def test_10_farm_scoped_chat_endpoint(self, mock_chat):
        mock_chat.return_value = {
            "reply": "Farm chat response",
            "response": "Farm chat response",
            "intent_type": "general",
            "provider": "groq/qwen/qwen3.8-27b",
            "success": True,
        }
        res = client.post("/farms/farm-123/chat", json={"message": "check farm status", "language": "en"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertEqual(data.get("reply"), "Farm chat response")

    # 11. Rollback mode: CHAT_PROVIDER=gemini routes directly to Gemini
    @patch("routes.chat.chat_with_gemini")
    @patch("routes.chat.chat_with_groq")
    def test_11_rollback_provider_selection(self, mock_groq, mock_gemini):
        mock_gemini.return_value = {
            "reply": "Gemini rollback response",
            "response": "Gemini rollback response",
            "intent_type": "general",
            "provider": "gemini/gemini-2.5-flash",
            "success": True,
        }
        with patch.dict(os.environ, {"CHAT_PROVIDER": "gemini"}):
            res = client.post("/api/chat", json={"message": "test rollback", "language": "en"})
            self.assertEqual(res.status_code, 200)
            data = res.json()
            self.assertEqual(data.get("reply"), "Gemini rollback response")
            mock_gemini.assert_called_once()
            mock_groq.assert_not_called()

    # 12. Standard REST API v1 endpoint alias verification
    @patch("routes.chat.chat_with_groq")
    def test_12_api_v1_chat_alias_endpoint(self, mock_chat):
        mock_chat.return_value = {
            "reply": "REST v1 response",
            "response": "REST v1 response",
            "intent_type": "general",
            "provider": "groq/qwen/qwen3.8-27b",
            "success": True,
        }
        res = client.post("/api/v1/chat", json={"message": "test v1", "language": "en"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertEqual(data.get("reply"), "REST v1 response")

    # 13. Upstream total failure returns 503 with structured retryable error
    @patch("routes.chat.chat_with_gemini")
    @patch("routes.chat.chat_with_groq")
    def test_13_upstream_total_failure_returns_503(self, mock_groq, mock_gemini):
        mock_groq.side_effect = UpstreamAIServiceError("Groq down", "UPSTREAM_UNAVAILABLE", retryable=True)
        mock_gemini.side_effect = UpstreamAIServiceError("Gemini down", "UPSTREAM_UNAVAILABLE", retryable=True)
        res = client.post("/api/chat", json={"message": "help", "language": "en"})
        self.assertEqual(res.status_code, 503)
        data = res.json()
        self.assertFalse(data.get("success"))
        self.assertEqual(data.get("error", {}).get("code"), "UPSTREAM_UNAVAILABLE")
        self.assertTrue(data.get("error", {}).get("retryable"))

if __name__ == "__main__":
    unittest.main()
