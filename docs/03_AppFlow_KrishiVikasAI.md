# App Flow Document — Krishi Vikas AI
**Version:** 2.0 | Every screen, state, and navigation path

---

## Global Navigation (Bottom Tab Bar)
5 tabs always visible (except onboarding):
1. 🏠 Home
2. 🗺️ Map (Sentinel)
3. 📷 Scan (center FAB)
4. 💬 Chat
5. 👤 My Farm

---

## Screen 1: Splash Screen
**On app launch:**
- Show logo + tagline in detected system language
- Check: JWT token in Hive storage?
  - YES → Check token valid → Go to Home
  - NO → Go to Onboarding

---

## Screen 2: Onboarding / Phone Auth
**States:**
- Empty: Phone number input field + "Get OTP" button
- Loading: Spinner, "Sending OTP..."
- OTP Screen: 6-digit OTP input + 60s resend timer
- Error: "Invalid OTP. Try again." (red inline)
- Success: Go to Farm Setup

**Actions:**
- Enter phone → tap "Get OTP" → Supabase Auth sends SMS OTP
- Enter OTP → tap "Verify" → JWT stored → proceed
- "Resend OTP" → enabled after 60s
- Guest mode link: "Continue without account" → skip to Farm Setup (localStorage only)

---

## Screen 3: Farm Setup (First Time)
**Shown once after auth, or when no farms exist.**

**Step 1 — Language:**
- 4 pills: English / हिन्दी / मराठी / தமிழ்
- Tap to select → all subsequent screens in that language

**Step 2 — Add Your First Farm:**
- Farm name (text input, e.g. "मुख्य शेत")
- Primary crop (dropdown: Tomato, Onion, Cotton, Wheat, Soybean, Rice, Potato, Other)
- Farm size (dropdown: <1 acre / 1-2 / 2-5 / 5-10 / 10+)
- Farming type (Organic / Conventional / Mixed)
- Location: "Use My Location" button → GPS → reverse geocode → show "Vasai, Maharashtra" → confirm
  - Fallback: manual district + state dropdown if GPS denied
- Sowing date (optional date picker)

**Step 3 — Done:**
- "Your farm is ready!" screen
- Go to Home

**Error states:**
- GPS denied: show manual input
- No crop selected: inline "Please select a crop"

---

## Screen 4: Home
**Components (top to bottom):**

### Header Bar
- Farm selector pill (if multiple farms): "🌿 मुख्य शेत ▼" → tap → bottom sheet farm switcher
- Language pill (top right): tap → language bottom sheet
- Notification bell → Notification list screen

### Farmer Profile Strip
- "TOMATO | 📍 VASAI | 1-2 ACRES | Stage: Flowering"
- Tap → My Farm tab

### Outbreak Alert Banner (conditional)
- Red card: "⚠️ 6 severe Fall Armyworm cases near you"
- Tap → Sentinel Map, Disease Outbreak view
- Hidden if no outbreaks

### Weather Widget
- Current temp, condition icon, humidity, wind
- 5-day forecast strip
- Climate alert (conditional): "Heavy rain in 12hrs — Cover your tomatoes"
- Tap → full weather detail screen

### Scan Hero Card
- "Scan Your Crop 📷"
- Shows current farm's crop
- Tap → Scan screen

### Market Prices Strip
- 3 commodity cards with price + trend arrow
- "See All →" → Mandi Prices screen

### Voice FAB
- Pulsing green mic button (bottom right)
- Tap → Chat screen with mic active

---

## Screen 5: Scan
**States:**

### Camera State
- Rear camera view with crop overlay guide
- "📷 Take Photo" button
- "Upload from Gallery" link
- Shows current farm + crop: "Scanning for: 🍅 Tomato"

### Preview State
- Full photo preview
- "Use This Photo" (green) + "Retake" (gray) buttons

### Loading State
- Spinner: "Analysing your crop..." (in selected language)
- No model name shown to farmer

### Result State
- Disease name (large, bold)
- Confidence bar (visual only if >70%; else hidden)
- Description (2–3 lines in farmer's language)
- Treatment tabs: "🌿 Organic" | "💊 Chemical" (toggle)
- Step-by-step treatment (numbered list)
- ₹ Cost estimate table
- Prevention tip
- "Nearest KVK" card (top 3 by distance)
- "Save to Farm Log" button → saves to soil/diagnosis log
- "Scan Again" button

### Error States
- API failure: "Could not analyse. Check your connection and try again." + Retry button
- Camera permission denied: "Allow camera access in Settings to use this feature"
- Poor image: "Photo is too blurry. Please retake in good light." (only from model response)

---

## Screen 6: Chat
**Layout:**
- Chat message list (scrollable)
- Bottom input bar: text field + mic button (both always visible)
- Send button appears when text is typed
- Mic button: tap → recording state

**States:**

### Empty State
- "👋 Ask me anything about your farm"
- 3 suggestion chips: "Disease on my crop?" / "When should I irrigate?" / "Best price for onion?"

### Recording State
- Mic button pulses red
- "Listening..." label
- Tap again to stop → STT processes → text appears in input field → auto-send

### Loading State
- Typing indicator (3 dots) in chat bubble

### Response State
- AI response in full detail — numbered steps, specific advice
- TTS play button on each AI message (tap → Sarvam Bulbul reads aloud)
- Farmer can reply immediately (text or voice)

### Error State
- "Connection error. Try again." with retry button inline in chat

**Context always injected (invisible to farmer):**
Farm: {name}, Crop: {crop}, Stage: {stage}, District: {district}, Soil: {soil_type}, Weather: {summary}, Last diagnosis: {diagnosis}

---

## Screen 7: Sentinel Map
**Layout:**
- Full-screen Leaflet/flutter_map
- Toggle pills at top: "🔴 Disease Outbreak" | "🔵 Climate Risk"
- Legend card (bottom left)
- Blue dot: farmer's GPS

**Disease Outbreak View:**
- Red/orange/yellow clusters generated ±0.05–0.15 lat/lng from farmer's GPS
- Tap cluster → popup: "Fall Armyworm — Severe — 3km away — 6 cases"
- Clusters refresh every 24 hours

**Climate Risk View:**
- OpenWeather precipitation tile layer overlay
- Temperature layer toggle
- Wind layer toggle
- Each layer has colour legend

**Empty States:**
- No outbreaks: "No disease outbreaks reported near you ✅"
- No weather data: "Weather data unavailable. Check connection."

---

## Screen 8: Mandi Prices
**Header:** "Live Mandi Prices — [District], [State]" + green "Live" dot

**Commodity Cards:**
- Commodity name + icon
- Current price (₹/quintal)
- Trend arrow (▲/▼/→) + % change
- Nearest APMC name

**"Where to Sell" Section:**
- Top 2 recommended mandis by price + distance score
- Distance + current price shown

**States:**
- Loading: skeleton cards
- Live data: green dot "Live · Agmarknet · Updated today"
- Cached: yellow dot "Cached · Updated X hours ago"
- Error: "Could not fetch prices. Showing last known prices."

---

## Screen 9: My Farm Tab
**Farm selector at top** (if multiple farms):
- Horizontal scroll chips: "मुख्य शेत ✅" | "+ Add Farm"
- Tap farm → switches all content below

**Per-Farm Sections:**

### Farm Info Card
- Crop, size, location, farming type, sowing date
- Edit button → Farm Edit screen

### Farm Lifecycle Timeline
- Horizontal progress: Sowing → Germination → Vegetative → Flowering → Harvest
- Current stage highlighted
- Each stage: tap → tips for that stage

### Soil Health Score
- SVG semi-circle dial (0–100)
- Score label: DEGRADED / FAIR / HEALTHY / EXCELLENT
- "Soil Guardian" badge if >70
- "Used Organic +10" / "Used Chemical +2" buttons
- Score starts at 50 for new farms (not 0)

### Diagnosis Log
- List of past diagnoses for this farm (from Supabase)
- Each entry: date, disease, treatment used, outcome
- Empty state: "No diagnoses yet. Scan your crop to get started."

### Government Schemes
- Personalised for this farm's crop + size + state
- Filter chips: All / Direct Benefit / Crop Insurance / Credit / Irrigation / Organic

**Add Farm Flow:**
- Same as Farm Setup Step 2
- Max 5 farms per account

---

## Screen 10: Government Schemes Detail
- Scheme name + ministry
- Benefit description
- Eligibility criteria (highlighted matches for farmer's profile)
- How to apply (numbered steps)
- Documents needed (checklist)
- "Apply on Government Website" button (opens browser)
- "Call Helpline" button (tel: link)

---

## Screen 11: Weather Detail
- Hourly forecast (24 hours)
- 7-day forecast
- Crop-specific advice card: "For your Tomato at Flowering stage: ..."
- Humidity, UV index, wind speed, visibility

---

## Screen 12: Notifications
- List of past alerts (newest first)
- Each: icon, title, body, timestamp
- Tap → relevant screen (Sentinel Map for outbreak, Home for weather)
- Empty state: "No alerts yet. We'll notify you of important changes."

---

## Screen 13: Settings
- Language selector
- Notification preferences (toggle per alert type)
- Account (phone number, sign out)
- App version
- Privacy policy link

---

## Global Error States
- No internet: persistent top banner "No connection — showing cached data"
- Session expired: auto redirect to phone auth screen
- Server error (500): "Something went wrong. Please try again." toast

---

## Global Empty States
- New user with no data: always show onboarding-style prompt to take action
- No farms: "Add your first farm to get started"

---
