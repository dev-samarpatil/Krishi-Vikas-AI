"use client";

import { useEffect, useState } from "react";
import {
  Cloud,
  Sun,
  CloudRain,
  CloudDrizzle,
  CloudSnow,
  CloudLightning,
  CloudFog,
  Droplets,
  Wind,
  AlertTriangle,
} from "lucide-react";
import SkeletonLoader from "@/components/shared/SkeletonLoader";

interface WeatherData {
  current: {
    temp_c: number;
    feels_like_c: number;
    humidity: number;
    description: string;
    icon: string;
    wind_speed_kmh: number;
    city: string;
  };
  forecast: {
    date: string;
    temp_c: number;
    temp_min: number;
    temp_max: number;
    description: string;
    icon: string;
  }[];
}

function getWeatherIcon(iconCode: string) {
  const code = iconCode?.slice(0, 2) || "01";
  const iconMap: Record<string, React.ReactNode> = {
    "01": <Sun className="w-8 h-8 text-yellow-200" />,
    "02": <Cloud className="w-8 h-8 text-white/90" />,
    "03": <Cloud className="w-8 h-8 text-white/70" />,
    "04": <Cloud className="w-8 h-8 text-white/60" />,
    "09": <CloudDrizzle className="w-8 h-8 text-blue-200" />,
    "10": <CloudRain className="w-8 h-8 text-blue-200" />,
    "11": <CloudLightning className="w-8 h-8 text-yellow-200" />,
    "13": <CloudSnow className="w-8 h-8 text-white" />,
    "50": <CloudFog className="w-8 h-8 text-white/70" />,
  };
  return iconMap[code] || <Sun className="w-8 h-8 text-yellow-200" />;
}

function getMiniIcon(iconCode: string) {
  const code = iconCode?.slice(0, 2) || "01";
  const iconMap: Record<string, React.ReactNode> = {
    "01": <Sun className="w-4 h-4 text-yellow-200" />,
    "02": <Cloud className="w-4 h-4 text-white/90" />,
    "03": <Cloud className="w-4 h-4 text-white/70" />,
    "04": <Cloud className="w-4 h-4 text-white/60" />,
    "09": <CloudDrizzle className="w-4 h-4 text-blue-200" />,
    "10": <CloudRain className="w-4 h-4 text-blue-200" />,
    "11": <CloudLightning className="w-4 h-4 text-yellow-200" />,
    "13": <CloudSnow className="w-4 h-4 text-white" />,
    "50": <CloudFog className="w-4 h-4 text-white/70" />,
  };
  return iconMap[code] || <Sun className="w-4 h-4 text-yellow-200" />;
}

const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

interface WeatherWidgetProps {
  climateAlert?: {
    alert_level: "urgent" | "advisory" | null;
    message: string;
  } | null;
}

const getClimateAlertMessage = (weather: {
  temp: number
  humidity: number  
  description: string
  wind: number
}) => {
  const { temp, humidity, description, wind } = weather
  
  if (description?.toLowerCase().includes('haze') || 
      description?.toLowerCase().includes('smoke')) {
    return '🌫️ Haze detected — avoid spraying pesticides today. Poor visibility affects coverage.'
  }
  if (temp > 38) {
    return `🌡️ Heat stress alert (${temp}°C) — irrigate crops early morning before 8am today.`
  }
  if (humidity > 78) {
    return `💧 High humidity (${humidity}%) — fungal disease risk. Apply preventive fungicide spray.`
  }
  if (wind > 25) {
    return `💨 Strong winds (${wind} km/h) — do not spray pesticides. Wait for calm weather.`
  }
  if (temp < 10) {
    return `❄️ Cold weather (${temp}°C) — protect sensitive crops from frost damage tonight.`
  }
  // Default — show something useful always
  return `☀️ ${temp}°C, ${humidity}% humidity — good conditions for field work today.`
}

export default function WeatherWidget({ climateAlert }: WeatherWidgetProps) {
  const [data, setData] = useState<WeatherData | null>(null);
  const [loading, setLoading] = useState(true);
  const [district, setDistrict] = useState("");

  useEffect(() => {
    try {
      setDistrict(localStorage.getItem('kv_district') || "");
    } catch {}
  }, []);

  useEffect(() => {
    const fetchWeather = async () => {
      try {
        // Try getting GPS, fallback to Nashik defaults
        let lat = 19.997;
        let lon = 73.789;
        try {
          const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
            navigator.geolocation.getCurrentPosition(resolve, reject, {
              timeout: 5000,
              maximumAge: 300000,
            })
          );
          lat = pos.coords.latitude;
          lon = pos.coords.longitude;
        } catch {
          // Use defaults
        }

        const API_BASE =
          process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8000";
        const resp = await fetch(
          `${API_BASE}/api/weather?lat=${lat}&lon=${lon}`
        );
        const json = await resp.json();
        setData(json);
      } catch (err) {
        console.error("Weather fetch error:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchWeather();
  }, []);

  if (loading) {
    return (
      <div className="mx-3 mt-3 bg-sky-600 rounded-2xl p-4 text-white shadow-md">
        <div className="text-sm font-semibold opacity-80 mb-2">Today&apos;s Weather</div>
        <SkeletonLoader variant="text" lines={2} className="opacity-30" />
      </div>
    );
  }

  if (!data || !data.current) {
    return null;
  }

  const { current, forecast } = data;

  return (
    <div className="mx-3 mt-3 bg-sky-600 rounded-2xl p-4 text-white shadow-md">
      {/* Current weather */}
      <div className="flex items-center justify-between">
        <div>
          <div className="text-xs font-semibold text-sky-100 capitalize tracking-wider">
            {current.city ? `${current.city}${district && current.city.toLowerCase() !== district.toLowerCase() ? `, ${district}` : ""}` : "Your Location"}
          </div>
          <div className="flex items-end gap-1 mt-1">
            <span className="text-4xl font-bold leading-none">
              {current.temp_c}°
            </span>
            <span className="text-sm text-sky-200 mb-1">{current.description}</span>
          </div>
        </div>
        <div className="flex flex-col items-center">
          {getWeatherIcon(current.icon)}
        </div>
      </div>

      {/* Stats row */}
      <div className="flex items-center gap-4 mt-3 text-xs text-sky-100">
        <div className="flex items-center gap-1">
          <Droplets className="w-3.5 h-3.5" />
          <span>{current.humidity}%</span>
        </div>
        <div className="flex items-center gap-1">
          <Wind className="w-3.5 h-3.5" />
          <span>{current.wind_speed_kmh} km/h</span>
        </div>
        <div>Feels like {current.feels_like_c}°</div>
      </div>

      {/* Climate Alert Strip */}
      <div className="mt-3 p-3 rounded-xl flex gap-2 items-start text-xs bg-black/20 text-white">
        <p className="leading-snug">
          {getClimateAlertMessage({
            temp: current.temp_c,
            humidity: current.humidity,
            description: current.description,
            wind: current.wind_speed_kmh
          })}
        </p>
      </div>

      {/* 5-day forecast */}
      {forecast && forecast.length > 0 && (
        <div className="flex justify-between mt-4 pt-3 border-t border-sky-500">
          {forecast.slice(0, 5).map((day, i) => {
            const d = new Date(day.date);
            const dayName = i === 0 ? "Today" : DAY_NAMES[d.getDay()];
            return (
              <div
                key={day.date}
                className="flex flex-col items-center gap-1 text-xs"
              >
                <span className="text-sky-200 font-medium">{dayName}</span>
                {getMiniIcon(day.icon)}
                <span className="font-bold text-white">{day.temp_c}°</span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
