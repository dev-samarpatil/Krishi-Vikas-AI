# Krishi Vikas AI — Phase 0 Data & Security Inventory

**Document:** `docs/architecture/PHASE_0_DATA_AND_SECURITY_INVENTORY.md`  
**Date:** October 21, 2026  
**Auditor:** Senior Architect & Release Engineer  

---

## 1. Database Schema Inventory (`supabase/migrations/20260603000000_init_schema.sql`)

The database architecture is defined in Supabase PostgreSQL. Eight core relational tables are defined:

| Table Name | Primary Key | Foreign Keys | Key Attributes | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `users` | `id (UUID)` | `auth.users(id)` | `phone`, `full_name`, `preferred_language`, `location_lat`, `location_lon`, `state`, `district` | Farmer identity and localized geo-location |
| `farms` | `id (UUID)` | `user_id -> users(id)` | `farm_name`, `area_acres`, `soil_type`, `primary_crops`, `irrigation_type`, `has_iot_sensors` | Agricultural landholding metadata |
| `diagnoses` | `id (UUID)` | `user_id -> users(id)`, `farm_id -> farms(id)` | `crop_type`, `disease_detected`, `confidence`, `image_url`, `treatment_applied`, `status` | Historical record of crop scans and disease diagnoses |
| `soil_logs` | `id (UUID)` | `farm_id -> farms(id)` | `nitrogen`, `phosphorus`, `potassium`, `ph`, `moisture_pct`, `source` | Soil test card entries and telemetry logs |
| `chat_sessions` | `id (UUID)` | `user_id -> users(id)` | `title`, `created_at` | Metadata for conversational chat histories |
| `farm_timeline` | `id (UUID)` | `farm_id -> farms(id)` | `event_type`, `description`, `event_date` | Crop lifecycle events (sowing, spraying, harvesting) |
| `push_tokens` | `id (UUID)` | `user_id -> users(id)` | `fcm_token`, `platform`, `updated_at` | Mobile push notification device registry |
| `weather_alerts_log` | `id (UUID)` | None | `district`, `alert_type`, `severity`, `advisory`, `sent_at` | Historical log of district-level extreme weather warnings |

---

## 2. Row Level Security (RLS) Policies

All tables have Row Level Security enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`):
1. **User Isolation:** All SELECT, INSERT, and UPDATE policies verify `auth.uid() = user_id`. Farmers cannot query or view other farmers' crop scans, soil data, or farm profiles.
2. **Farm Association:** Farm resources (`soil_logs`, `farm_timeline`) enforce ownership by verifying `farm_id IN (SELECT id FROM farms WHERE user_id = auth.uid())`.
3. **Backend Service Role:** The FastAPI backend utilizes the Supabase `SERVICE_KEY` only when executing trusted administrative tasks or background alert generation.

---

## 3. Storage Bucket Configuration

- **Bucket Name:** `crop-images`
- **Visibility:** Private (`public = false`).
- **Access Policies:**
  - `INSERT`: Allowed only for authenticated farmers uploading to their own path prefix (`auth.uid()/*`).
  - `SELECT`: Allowed only for the image owner or backend service role.
  - Image URLs stored in `diagnoses.image_url` use time-limited signed URLs or secure backend proxy endpoints.

---

## 4. Vector Search & RAG Infrastructure Audit

- **Audit Finding:** **NOT IMPLEMENTED.**
- Neither `pgvector` nor vector column types exist in the current database schema.
- There are no tables for agricultural document chunks, embeddings, or semantic similarity indices.
- Any future RAG implementation (Phase 2) will require provisioning the `vector` extension and defining chunk/embedding tables.

---

## 5. IoT & Automated Irrigation Schema Audit

- **Audit Finding:** **NOT IMPLEMENTED.**
- The `farms` table contains a boolean attribute `has_iot_sensors`, but no telemetry tables (e.g., streaming time-series sensor tables, pump relay actuation logs, valve state tables) exist in the current schema.
- Automatic irrigation and ESP32 hardware support remain future roadmap items.
