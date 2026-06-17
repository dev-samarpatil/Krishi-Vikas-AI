"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import SentinelAlertCard from "@/components/home/SentinelAlertCard";
import ScanHeroCard from "@/components/home/ScanHeroCard";
import WeatherWidget from "@/components/home/WeatherWidget";
import QuickAccessGrid from "@/components/home/QuickAccessGrid";
import PhotoPreview from "@/components/diagnosis/PhotoPreview";
import DiagnosisResultCard from "@/components/diagnosis/DiagnosisResultCard";
import { compressImage } from "@/lib/compress-image";
import { getFarmerContext, updateFarmerContext } from "@/lib/farmer-context";
import { diagnoseCrop } from '@/lib/gemini-diagnose';
import { MandiPrice } from "@/types/mandi";
import { cropEmojis, getLocationBasedPrices } from "@/lib/mandi";
import { TrendingUp, ArrowUpRight, ArrowDownRight, Minus } from "lucide-react";

/* eslint-disable @typescript-eslint/no-explicit-any */

interface AlertData {
  alert: boolean;
  disease: string;
  count: number;
  message: string;
}

type ViewState = "home" | "preview" | "analyzing" | "result" | "rate_limit";

const haversine = (lat1: number, lng1: number, lat2: number, lng2: number) => {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) *
    Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.asin(Math.sqrt(a));
};

const generateDemoClusters = (farmerLat: number, farmerLng: number) => [
  { lat: farmerLat + 0.072, lng: farmerLng + 0.072, cases: 6, severity: 'severe', disease: 'Fall Armyworm' },
  { lat: farmerLat + 0.065, lng: farmerLng - 0.090, cases: 3, severity: 'moderate', disease: 'Early Blight' },
  { lat: farmerLat - 0.045, lng: farmerLng + 0.010, cases: 1, severity: 'low', disease: 'Powdery Mildew' }
];

export default function HomePage() {
  const [isMounted, setIsMounted] = useState(false);
  const [viewState, setViewState] = useState<ViewState>("home");
  const [isBackendWaking, setIsBackendWaking] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [imagePreviewUrl, setImagePreviewUrl] = useState<string>("");
  const [compressedBlob, setCompressedBlob] = useState<Blob | null>(null);
  const [diagnosisResult, setDiagnosisResult] = useState<any>(null);
  const [alertData, setAlertData] = useState<AlertData | null>(null);
  const [climateAlert, setClimateAlert] = useState<{
    alert_level: "urgent" | "advisory" | null;
    message: string;
  } | null>(null);
  const [mandiData, setMandiData] = useState<MandiPrice[] | null>(null);
  const [currentDistrict, setCurrentDistrict] = useState<string | null>("Pune");
  const [location, setLocation] = useState<string | null>(() => {
    if (typeof window !== 'undefined') {
      const d = localStorage.getItem('kv_district')
      const s = localStorage.getItem('kv_state')
      if (d && s) return `${d}, ${s}`
    }
    return null
  });
  const [crop, setCrop] = useState<string | null>("Tomato");
  const [farmSize, setFarmSize] = useState<string | null>("1-2 Acres");
  const router = useRouter();

  const API_BASE =
    typeof window !== "undefined"
      ? process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8000"
      : "http://localhost:8000";

  useEffect(() => {
    setIsMounted(true);
    const key = process.env.NEXT_PUBLIC_GEMINI_API_KEY
    console.log("Gemini key present:", !!key,
      key ? key.substring(0, 8) + "..." : "MISSING")
  }, [])

  // Check for sentinel alerts and backend health on load
  useEffect(() => {
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL;
    if (backendUrl) {
      setIsBackendWaking(true);
      fetch(`${backendUrl}/api/health`, {
        method: "GET",
        signal: AbortSignal.timeout(30000),
      })
        .then(() => {
          console.log("Backend is awake");
          setIsBackendWaking(false);
        })
        .catch(() => {
          console.log("Backend waking up...");
          setIsBackendWaking(false);
        });
    }

    // Request GPS with fast settings
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          const { latitude: lat, longitude: lng } = pos.coords
          localStorage.setItem('kv_lat', lat.toString())
          localStorage.setItem('kv_lng', lng.toString())
          
          try {
            const res = await fetch(
              `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json`,
              { headers: { "Accept-Language": "en-US", 'User-Agent': 'KrishiVikasAI/1.0' } }
            )
            const data = await res.json()
            const addr = data.address || {}
            const district = (addr.county || addr.city_district || 
                             addr.city || addr.town || 'Your Area')
                             .replace(' District', '')
                             .replace(' Subdistrict', '')
                             .trim()
            const state = addr.state || 'Maharashtra'
            
            localStorage.setItem('kv_district', district)
            localStorage.setItem('kv_state', state)
            setLocation(`${district}, ${state}`)
            setCurrentDistrict(district)
          } catch {
            // Use coordinates directly if geocoding fails
            setLocation(`${lat.toFixed(2)}°N, ${lng.toFixed(2)}°E`)
          }
        },
        () => {
          // GPS denied or failed — use cached or default
          if (!location) setLocation('Maharashtra')
        },
        { 
          timeout: 6000,
          maximumAge: 600000,   // Accept 10 min old cache
          enableHighAccuracy: false  // Faster response
        }
      )
    }

    const checkAlerts = async () => {
      try {
        const ctx = getFarmerContext();

        // Load Location and Profile
        const savedDistrict = localStorage.getItem('kv_district') || ctx.district || "Nashik";
        const savedState = localStorage.getItem('kv_state') || ctx.state || "Maharashtra";
        setCurrentDistrict(savedDistrict);

        const savedProfile = localStorage.getItem('kv_farmer_profile');
        if (savedProfile) {
          try {
            const profile = JSON.parse(savedProfile);
            if (profile.primary_crop) setCrop(profile.primary_crop);
            if (profile.farm_size) setFarmSize(profile.farm_size);
          } catch (e) { }
        }

        const fetchMandi = async () => {
          try {
            const primaryCrop = ctx.crop_types?.[0] || "Tomato";
            const res = await fetch(`${API_BASE}/api/market?state=${savedState}&district=${savedDistrict}&crop=${primaryCrop}`);
            if (res.ok) {
              const data = await res.json();
              if (data?.prices?.length > 0) {
                setMandiData(data.prices.slice(0, 3));
                return;
              }
            }
          } catch (e) {
            console.warn("Home Mandi fetch failed");
          }
          setMandiData(getLocationBasedPrices(savedDistrict, savedState).slice(0, 3));
        };
        fetchMandi();

        const [alertResp, climateResp] = await Promise.allSettled([
          fetch(`${API_BASE}/api/check-alerts`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ lat: ctx.lat, long: ctx.long }),
          }),
          fetch(`${API_BASE}/api/climate-alert`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              lat: ctx.lat,
              long: ctx.long,
              crop: ctx.crop_types[0] || "Unknown",
              crop_stage: "mature", // Mocking mature stage for testing harvest_urgent rule
              language: localStorage.getItem("kv_language") || ctx.language || "en"
            }),
          })
        ]);

        if (alertResp.status === "fulfilled" && alertResp.value.ok) {
          const data = await alertResp.value.json();
          if (data.alert) setAlertData(data);
        }

        if (climateResp.status === "fulfilled" && climateResp.value.ok) {
          const data = await climateResp.value.json();
          if (data.alert_level) setClimateAlert(data);
        }

        // Local check for consistent Sentinel alert using Demo data
        let currentLat = ctx.lat || 19.99;
        let currentLng = ctx.long || 73.79;
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition((pos) => {
            currentLat = pos.coords.latitude;
            currentLng = pos.coords.longitude;
            const clusters = generateDemoClusters(currentLat, currentLng);
            const nearby = clusters.filter(c => {
              const dist = haversine(currentLat, currentLng, c.lat, c.lng);
              return dist < 15 && c.cases >= 5;
            });

            if (nearby.length > 0) {
              setAlertData({
                alert: true,
                disease: nearby[0].disease,
                count: nearby[0].cases,
                message: `High risk: ${nearby[0].cases} severe cases of ${nearby[0].disease} detected near you.`
              });
            }
          });
        }
      } catch {
        // Silent — alerts are optional
      }
    };
    checkAlerts();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [API_BASE]);

  // ── Photo Selected ────────────────────────────────────────────────
  const handleFileSelected = useCallback(async (file: File) => {
    setSelectedFile(file);

    // Create preview URL
    const url = URL.createObjectURL(file);
    setImagePreviewUrl(url);

    // Compress in background
    try {
      const blob = await compressImage(file);
      setCompressedBlob(blob);
    } catch {
      // Use original if compression fails
      setCompressedBlob(file);
    }

    setViewState("preview");
  }, []);

  // ── Confirm & Send to API ─────────────────────────────────────────
  const handleConfirm = useCallback(async () => {
    if (!compressedBlob) return;
    setViewState("analyzing");

    try {
      const ctx = getFarmerContext();

      // Get GPS from browser (with fallback to context defaults)
      let lat = ctx.lat;
      let lng = ctx.long;
      try {
        const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
          navigator.geolocation.getCurrentPosition(resolve, reject, {
            timeout: 5000,
            maximumAge: 60000,
          })
        );
        lat = pos.coords.latitude;
        lng = pos.coords.longitude;
      } catch {
        // Use defaults from farmer context
      }

      // Read profile
      let farmSize, farmingType, primaryCrop;
      try {
        const saved = localStorage.getItem("kv_farmer_profile");
        if (saved) {
          const profile = JSON.parse(saved);
          farmSize = profile.farm_size;
          farmingType = profile.farming_type;
          primaryCrop = profile.primary_crop;
        }
      } catch (e) { }

      // Direct Gemini from client side
      const result = await diagnoseCrop(selectedFile!, {
        district: ctx.district || 'Nashik',
        state: ctx.state || 'Maharashtra',
        crop_type: primaryCrop || ctx.crop_types[0] || 'unknown',
        language: localStorage.getItem('kv_language') || ctx.language || 'en',
        farm_size: farmSize,
        farming_type: farmingType
      });

      // Still save to backend for Sentinel heatmap
      try {
        await fetch(`${API_BASE}/api/log-diagnosis`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            disease_name: result.name,
            confidence: result.confidence,
            district: ctx.district || 'Nashik',
            crop_type: ctx.crop_types[0] || 'unknown',
            lat,
            long: lng
          })
        });
      } catch {
        // Non-critical — Sentinel still works with direct save
      }

      setDiagnosisResult(result);

      // Update farmer context with latest diagnosis
      updateFarmerContext({
        last_diagnosis: result.name || null,
        lat,
        long: lng,
      });

      setViewState("result");
    } catch (err: any) {
      console.error("Diagnosis error:", err);
      const errorStr = err?.message || err?.toString() || '';

      if (errorStr.includes('RATE_LIMIT') || errorStr.includes('429') ||
        errorStr.includes('quota') || errorStr.includes('Too Many Requests') ||
        errorStr.includes('AI_BUSY') || errorStr.includes('503')) {
        // Show rate limit UI — not a fake diagnosis card
        setViewState("rate_limit");
      } else {
        setDiagnosisResult({
          type: "unclear",
          name: "Analysis Failed",
          name_local: "",
          confidence: 0,
          explanation:
            "Something went wrong during the analysis. Please check your internet connection and try again.",
          cause: "",
          treatment_steps: [],
          organic_option: { description: "", steps: [] },
          prevention: "",
          budget_items: [],
          total_cost_inr: 0,
          organic_total_cost_inr: 0,
          urgency: "monitor",
          low_confidence_note: "Analysis failed. Please try again.",
        });
        setViewState("result");
      }
    }
  }, [compressedBlob, API_BASE]);

  // ── Retake ────────────────────────────────────────────────────────
  const handleRetake = useCallback(() => {
    if (imagePreviewUrl) {
      URL.revokeObjectURL(imagePreviewUrl);
    }
    setSelectedFile(null);
    setImagePreviewUrl("");
    setCompressedBlob(null);
    setViewState("home");
  }, [imagePreviewUrl]);

  // ── Log Treatment Choice ──────────────────────────────────────────
  const handleChooseTreatment = useCallback(
    async (type: "organic" | "chemical") => {
      try {
        const ctx = getFarmerContext();
        await fetch(`${API_BASE}/api/log-treatment`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            farmer_id: ctx.farmer_id,
            diagnosis_id: diagnosisResult?.diagnosis_id || "",
            treatment_type: type,
          }),
        });
      } catch {
        // Non-blocking, don't fail the UI
      }
    },
    [API_BASE, diagnosisResult]
  );

  // ── Dismiss result → go home ──────────────────────────────────────
  const handleDismiss = useCallback(() => {
    if (imagePreviewUrl) {
      URL.revokeObjectURL(imagePreviewUrl);
    }
    setSelectedFile(null);
    setImagePreviewUrl("");
    setCompressedBlob(null);
    setDiagnosisResult(null);
    setViewState("home");
  }, [imagePreviewUrl]);

  // ══════════════════════════════════════════════════════════════════
  // RENDER
  // ══════════════════════════════════════════════════════════════════

  // ── Rate Limit state ──────────────────────────────────────────────
  if (viewState === "rate_limit") {
    return (
      <div className="pb-6">
        <div className="mx-4 mt-8 bg-amber-50 border border-amber-200 rounded-2xl p-5 text-center">
          <div className="text-3xl mb-3">⏱️</div>
          <h3 className="text-sm font-bold text-amber-800 mb-2">
            AI is busy — please wait a moment
          </h3>
          <p className="text-xs text-amber-700 mb-4">
            High demand on AI servers. Please try again in 1-2 minutes.
          </p>
          <button
            onClick={handleRetake}
            className="bg-green-700 text-white rounded-xl px-6 py-3 text-sm font-bold w-full active:scale-95 transition-transform"
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  // ── Preview / analyzing state ─────────────────────────────────────
  if (viewState === "preview" || viewState === "analyzing") {
    return (
      <div className="pb-6">
        <PhotoPreview
          imageUrl={imagePreviewUrl}
          isAnalyzing={viewState === "analyzing"}
          onConfirm={handleConfirm}
          onRetake={handleRetake}
        />

        {/* Analyzing skeleton */}
        {viewState === "analyzing" && (
          <div className="mx-3 mt-4 space-y-3">
            <div className="bg-white rounded-2xl border border-gray-200 p-4 space-y-3">
              <div className="h-4 bg-gray-200 rounded-full animate-pulse w-2/3" />
              <div className="h-3 bg-gray-200 rounded-full animate-pulse w-full" />
              <div className="h-3 bg-gray-200 rounded-full animate-pulse w-5/6" />
              <div className="h-3 bg-gray-200 rounded-full animate-pulse w-3/4" />
            </div>
            <div className="bg-white rounded-2xl border border-gray-200 p-4 space-y-3">
              <div className="h-4 bg-gray-200 rounded-full animate-pulse w-1/2" />
              <div className="h-3 bg-gray-200 rounded-full animate-pulse w-full" />
              <div className="h-3 bg-gray-200 rounded-full animate-pulse w-4/5" />
            </div>
          </div>
        )}
      </div>
    );
  }

  // ── Result state ──────────────────────────────────────────────────
  if (viewState === "result" && diagnosisResult) {
    return (
      <div className="pb-6">
        <DiagnosisResultCard
          result={diagnosisResult}
          onChooseTreatment={handleChooseTreatment}
          onDismiss={handleDismiss}
        />
      </div>
    );
  }

  // ── Home state (default) ──────────────────────────────────────────
  return (
    <div className="pb-6">
      {/* Header Section */}
      <div className="px-4 py-6 bg-gradient-to-b from-white to-gray-50 border-b border-gray-100">
        <h1 className="text-2xl font-black text-gray-900 tracking-tight">Welcome back, Farmer 👋</h1>
        {isBackendWaking && (
          <div className="text-xs text-amber-600 animate-pulse mt-1 mb-2 font-semibold">
            Connecting to AI... (this may take 30 seconds on first load)
          </div>
        )}
        <p className="text-sm font-bold text-gray-500 mt-1 uppercase tracking-wider flex items-center gap-1">
          {crop || "Loading..."} | 📍 {isMounted ? (location?.split(',')[0] || "India") : "..."} {farmSize ? `| ${farmSize}` : ""}
        </p>
      </div>

      {/* 1. Sentinel Alert (conditional) */}
      {alertData && alertData.alert && (
        <SentinelAlertCard
          title="⚠️ Outbreak Alert Near You"
          message={alertData.message}
          count={alertData.count}
          disease={alertData.disease}
        />
      )}

      {/* 2. Scan Hero Card */}
      <ScanHeroCard onFileSelected={handleFileSelected} />

      {/* 3. Weather Widget */}
      <WeatherWidget climateAlert={climateAlert} />

      {/* Market Trends Section */}
      <div className="mx-3 mt-4">
        <div className="flex items-center justify-between mb-3 px-1">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-amber-50 rounded-lg flex items-center justify-center">
              <TrendingUp className="w-4 h-4 text-amber-600" strokeWidth={2.5} />
            </div>
            <h2 className="text-base font-bold text-gray-900">Market Trends &mdash; {currentDistrict}</h2>
          </div>
          <button
            onClick={() => router.push('/mandi')}
            className="text-xs font-bold text-amber-600 active:opacity-50"
          >
            View All
          </button>
        </div>
        <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
          {!mandiData ? (
            [1, 2, 3].map(i => (
              <div key={i} className="min-w-[140px] h-24 bg-gray-100 animate-pulse rounded-2xl shrink-0" />
            ))
          ) : mandiData.map((item, idx) => (
            <div
              key={idx}
              className="min-w-[140px] bg-white border border-gray-100 rounded-2xl p-3 shadow-sm shrink-0 active:scale-95 transition-transform"
              onClick={() => router.push('/mandi')}
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-xl">{item.emoji || (item.crop ? (cropEmojis as any)[item.crop] : "🌱")}</span>
                <div className={`flex items-center text-[10px] font-bold ${item.trend === 'up' ? 'text-green-600' : item.trend === 'down' ? 'text-red-600' : 'text-gray-400'
                  }`}>
                  {item.trend === 'up' ? <ArrowUpRight className="w-3 h-3" /> : item.trend === 'down' ? <ArrowDownRight className="w-3 h-3" /> : <Minus className="w-3 h-3" />}
                  {item.trend_percent || ''}
                </div>
              </div>
              <h3 className="text-xs font-bold text-gray-900 truncate">{item.crop}</h3>
              <p className="text-[10px] text-gray-400 truncate">{item.market}</p>
              <div className="text-xs font-black text-gray-900 mt-1">₹{item.modal_price}</div>
            </div>
          ))}
        </div>
      </div>

      {/* 4. Quick Access Grid */}
      <QuickAccessGrid />
    </div>
  );
}
