# Backend Schema — Krishi Vikas AI
**Version:** 2.0 | Supabase PostgreSQL

---

## Table 1: users
```sql
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT auth.uid(),
  phone         TEXT UNIQUE NOT NULL,
  name          TEXT,
  language      TEXT NOT NULL DEFAULT 'en', -- 'en' | 'hi' | 'mr' | 'ta'
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access own row"
  ON users FOR ALL USING (auth.uid() = id);
```

---

## Table 2: farms
```sql
CREATE TABLE farms (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,                        -- "मुख्य शेत"
  crop          TEXT NOT NULL,                        -- "tomato"
  crop_variety  TEXT,                                 -- "Hybrid F1"
  farm_size     TEXT NOT NULL,                        -- "1-2"
  size_unit     TEXT DEFAULT 'acres',
  farming_type  TEXT DEFAULT 'conventional',          -- 'organic' | 'conventional' | 'mixed'
  district      TEXT,
  state         TEXT,
  lat           DECIMAL(9,6),
  lng           DECIMAL(9,6),
  soil_type     TEXT,                                 -- from soil_types.json lookup
  sowing_date   DATE,
  expected_harvest_date DATE,
  current_stage TEXT DEFAULT 'sowing',               -- 'sowing'|'germination'|'vegetative'|'flowering'|'harvest'
  soil_score    INTEGER DEFAULT 50 CHECK (soil_score BETWEEN 0 AND 100),
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_farms_user_id ON farms(user_id);

-- RLS
ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their farms"
  ON farms FOR ALL USING (auth.uid() = user_id);
```

---

## Table 3: diagnoses
```sql
CREATE TABLE diagnoses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id         UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  image_url       TEXT,                               -- Supabase Storage path
  crop            TEXT NOT NULL,
  disease_name    TEXT,
  confidence      DECIMAL(5,2),                       -- e.g. 87.50
  model_used      TEXT,                               -- 'roboflow' | 'gemini'
  severity        TEXT,                               -- 'low' | 'medium' | 'high'
  treatment_type  TEXT,                               -- 'organic' | 'chemical'
  treatment_steps JSONB,                              -- [{step: 1, action: "...", product: "..."}]
  cost_estimate   JSONB,                              -- [{item: "neem oil", qty: "100ml", price: 80}]
  prevention_tip  TEXT,
  language        TEXT DEFAULT 'en',
  weather_at_scan JSONB,                              -- snapshot of weather at time of scan
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_diagnoses_farm_id ON diagnoses(farm_id);
CREATE INDEX idx_diagnoses_user_id ON diagnoses(user_id);
CREATE INDEX idx_diagnoses_created_at ON diagnoses(created_at DESC);

-- RLS
ALTER TABLE diagnoses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their diagnoses"
  ON diagnoses FOR ALL USING (auth.uid() = user_id);
```

---

## Table 4: soil_logs
```sql
CREATE TABLE soil_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id       UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action        TEXT NOT NULL,                        -- 'organic_treatment' | 'chemical_treatment' | 'diagnosis'
  score_change  INTEGER NOT NULL,                     -- +10, +2, -5 etc.
  score_after   INTEGER NOT NULL,
  note          TEXT,                                 -- diagnosis disease name or treatment name
  diagnosis_id  UUID REFERENCES diagnoses(id),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_soil_logs_farm_id ON soil_logs(farm_id);

-- RLS
ALTER TABLE soil_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their soil logs"
  ON soil_logs FOR ALL USING (auth.uid() = user_id);
```

---

## Table 5: chat_sessions
```sql
CREATE TABLE chat_sessions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id     UUID REFERENCES farms(id) ON DELETE SET NULL,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  messages    JSONB NOT NULL DEFAULT '[]',            -- [{role: "user"|"assistant", content: "...", ts: "..."}]
  language    TEXT DEFAULT 'en',
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX idx_chat_sessions_farm_id ON chat_sessions(farm_id);

-- RLS
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their chats"
  ON chat_sessions FOR ALL USING (auth.uid() = user_id);
```

---

## Table 6: farm_timeline
```sql
CREATE TABLE farm_timeline (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id     UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stage       TEXT NOT NULL,                          -- 'sowing'|'germination'|'vegetative'|'flowering'|'harvest'
  started_at  DATE,
  completed_at DATE,
  notes       TEXT,
  tasks       JSONB,                                  -- [{task: "Apply urea", due: "2026-06-10", done: false}]
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_farm_timeline_farm_id ON farm_timeline(farm_id);

-- RLS
ALTER TABLE farm_timeline ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their timeline"
  ON farm_timeline FOR ALL USING (auth.uid() = user_id);
```

---

## Table 7: push_tokens
```sql
CREATE TABLE push_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fcm_token   TEXT NOT NULL,
  platform    TEXT DEFAULT 'android',                 -- 'android' | 'ios'
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

-- RLS
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their tokens"
  ON push_tokens FOR ALL USING (auth.uid() = user_id);
```

---

## Table 8: weather_alerts_log
```sql
CREATE TABLE weather_alerts_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  farm_id       UUID REFERENCES farms(id),
  alert_type    TEXT NOT NULL,                        -- 'heavy_rain' | 'frost' | 'heat_wave' | 'strong_wind'
  message       TEXT NOT NULL,
  advice        TEXT,
  weather_data  JSONB,
  sent_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_weather_alerts_user_id ON weather_alerts_log(user_id);
CREATE INDEX idx_weather_alerts_sent_at ON weather_alerts_log(sent_at DESC);

-- RLS
ALTER TABLE weather_alerts_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own alerts"
  ON weather_alerts_log FOR ALL USING (auth.uid() = user_id);
```

---

## Supabase Storage Buckets

```
bucket: crop-images
  - path: {user_id}/{farm_id}/{diagnosis_id}.jpg
  - access: private (signed URLs only)
  - max size: 5MB
  - allowed types: image/jpeg, image/png
```

---

## Key Relationships Diagram

```
users
  └── farms (1:many)
        ├── diagnoses (1:many)
        ├── soil_logs (1:many)
        ├── farm_timeline (1:many)
        └── weather_alerts_log (1:many, via user_id also)
  └── chat_sessions (1:many, optionally linked to farm)
  └── push_tokens (1:many)
```

---

## FastAPI — Key Endpoints

```
POST   /auth/verify-otp
POST   /farms                    → create farm
GET    /farms                    → list user's farms
PUT    /farms/{farm_id}          → update farm
DELETE /farms/{farm_id}

POST   /scan                     → image + context → diagnosis result
GET    /farms/{farm_id}/diagnoses

POST   /chat                     → message + farm_id → AI response
GET    /farms/{farm_id}/chat

GET    /mandi/prices?district=   → live + fallback prices
GET    /weather?lat=&lng=        → current + forecast
GET    /schemes?crop=&state=&size=

POST   /push/register            → save FCM token
POST   /push/send (internal cron use only)

GET    /farms/{farm_id}/soil
POST   /farms/{farm_id}/soil/log

GET    /kvk/nearest?lat=&lng=    → top 3 KVKs by distance
```

---
