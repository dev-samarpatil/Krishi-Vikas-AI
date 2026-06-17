"use client";

import { useEffect, useState } from "react";
import { MapContainer, TileLayer, CircleMarker, useMap, Marker } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

import icon from "leaflet/dist/images/marker-icon.png";
import iconShadow from "leaflet/dist/images/marker-shadow.png";

let DefaultIcon = L.icon({
  iconUrl: icon.src,
  shadowUrl: iconShadow.src,
});
L.Marker.prototype.options.icon = DefaultIcon;

import MapToggles from "./MapToggles";
import OutbreakBottomSheet from "./OutbreakBottomSheet";
import { getFarmerContext } from "@/lib/farmer-context";
import { useLanguage } from "@/context/LanguageContext";

// Custom Leaflet DivIcon for pulsing cluster effect
const createPulseIcon = (count: number, colorClass: keyof typeof colors) => {
  const bgColors = {
    red: "bg-red-600",
    orange: "bg-orange-500",
    amber: "bg-[#D97706]"
  };
  const color = bgColors[colorClass];

  return L.divIcon({
    className: "pulse-marker-container",
    html: `
      <div class="relative flex items-center justify-center w-12 h-12">
        <div class="absolute w-full h-full ${color}/18 rounded-full animate-ping [animation-duration:2s]"></div>
        <div class="absolute w-8 h-8 ${color}/32 rounded-full animate-pulse"></div>
        <div class="absolute w-5 h-5 ${color} rounded-full flex items-center justify-center shadow-lg shadow-black/20">
           <span class="text-[9px] font-bold text-white">${count}</span>
        </div>
      </div>
    `,
    iconSize: [48, 48],
    iconAnchor: [24, 24],
  });
};

const colors = {
  red: "red",
  orange: "orange",
  amber: "amber"
};

interface Cluster {
  disease_name: string;
  count: number;
  lat: number;
  long: number;
  radius_km: number;
  colorClass: keyof typeof colors;
}

const generateDemoClusters = (farmerLat: number, farmerLng: number): Cluster[] => [
  {
    // Severe — 8km northeast of farmer
    lat: farmerLat + 0.072,
    long: farmerLng + 0.072,
    count: 6,
    colorClass: 'red',
    disease_name: 'Fall Armyworm',
    radius_km: 15
  },
  {
    // Moderate — 12km northwest  
    lat: farmerLat + 0.065,
    long: farmerLng - 0.090,
    count: 3,
    colorClass: 'orange',
    disease_name: 'Early Blight',
    radius_km: 8
  },
  {
    // Low — 5km south
    lat: farmerLat - 0.045,
    long: farmerLng + 0.010,
    count: 1,
    colorClass: 'amber',
    disease_name: 'Powdery Mildew',
    radius_km: 2
  }
];

function ChangeView({ center }: { center: [number, number] }) {
  const map = useMap();
  map.setView(center, map.getZoom());
  return null;
}

export default function SentinelMap() {
  const [activeLayer, setActiveLayer] = useState<"disease" | "climate">("disease");
  const [selectedCluster, setSelectedCluster] = useState<Cluster | null>(null);
  const { t } = useLanguage();
  
  const ctx = getFarmerContext();
  const [mapCenter, setMapCenter] = useState<[number, number]>(() => {
    const lat = parseFloat(localStorage.getItem('kv_lat') || '19.99');
    const lng = parseFloat(localStorage.getItem('kv_lng') || '73.79');
    return [lat, lng];
  });
  const [clusters, setClusters] = useState<Cluster[]>(() => {
    const lat = parseFloat(localStorage.getItem('kv_lat') || '19.99');
    const lng = parseFloat(localStorage.getItem('kv_lng') || '73.79');
    return generateDemoClusters(lat, lng);
  });
  const [weatherData, setWeatherData] = useState<any>(null);

  useEffect(() => {
    try {
      const data = localStorage.getItem('kv_weather');
      if (data) setWeatherData(JSON.parse(data));
    } catch(err) {}

    const fetchClusters = async () => {
      try {
        const url = process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8000";
        const resp = await fetch(`${url}/api/map-clusters`);
        if (resp.ok) {
          const data = await resp.json();
          if (data.clusters && data.clusters.length > 0) {
            const mapped = data.clusters.map((c: any) => ({
              disease_name: c.disease_name,
              count: c.count,
              lat: c.lat,
              long: c.long || c.lng,
              radius_km: c.radius_km || 15,
              colorClass: c.count >= 5 ? "red" : c.count >= 3 ? "orange" : "amber"
            }));
            setClusters(mapped);
            return true;
          }
        }
      } catch (err) {
        console.error("Failed to fetch map clusters:", err);
      }
      return false;
    };

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const lat = position.coords.latitude;
          const lng = position.coords.longitude;
          setMapCenter([lat, lng]);
          const success = await fetchClusters();
          if (!success) {
            setClusters(generateDemoClusters(lat, lng));
          }
        },
        async (error) => {
          console.error("GPS error:", error);
          await fetchClusters();
        },
        { 
          timeout: 6000,
          maximumAge: 600000,
          enableHighAccuracy: false
        }
      );
    } else {
      fetchClusters();
    }
  }, []);

  const getClimateRisks = (temp: number, humidity: number, wind: number, description: string) => {
    const risks = []
    
    if (description?.toLowerCase().includes('haze')) {
      risks.push({
        level: 'medium', icon: '🌫️',
        title: 'Haze Conditions',
        advice: 'Avoid pesticide spraying today. Poor air quality affects crop absorption.'
      })
    }
    if (temp > 35) {
      risks.push({
        level: 'high', icon: '🌡️',
        title: 'Heat Stress Risk',
        advice: `${temp}°C is stressful for crops. Irrigate before 8am. Avoid field work 11am-4pm.`
      })
    }
    if (humidity > 75) {
      risks.push({
        level: 'medium', icon: '💧',
        title: 'Fungal Disease Risk', 
        advice: `Humidity at ${humidity}%. Conditions ideal for fungal spread. Apply Mancozeb preventively.`
      })
    }
    if (wind > 20) {
      risks.push({
        level: 'medium', icon: '💨',
        title: 'High Wind — No Spraying',
        advice: `${wind} km/h winds. Pesticide will drift. Wait for early morning calm conditions.`
      })
    }
    if (risks.length === 0) {
      risks.push({
        level: 'low', icon: '✅',
        title: 'Good Farming Conditions',
        advice: `${temp}°C, ${humidity}% humidity. Ideal for spraying, harvesting, and field work today.`
      })
    }
    return risks
  }

  return (
    <div className="absolute inset-0 z-0">
      <MapContainer 
        center={mapCenter} 
        zoom={10} 
        zoomControl={false}
        style={{ height: 'calc(100vh - 132px)', width: '100%' }}
      >
        <ChangeView center={mapCenter} />
        <TileLayer
          attribution='&copy; OpenStreetMap'
          url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
        />

        <CircleMarker 
          center={mapCenter}
          radius={8}
          pathOptions={{ 
            color: '#1D4ED8', 
            fillColor: '#3B82F6',
            fillOpacity: 1
          }}
        >
          {/* <Tooltip permanent>📍 Your location</Tooltip> */}
        </CircleMarker>

        {activeLayer === "disease" && clusters.map((cluster, idx) => (
          <Marker
            key={idx}
            position={[cluster.lat, cluster.long]}
            icon={createPulseIcon(cluster.count, cluster.colorClass)}
            eventHandlers={{
              click: () => {
                if (typeof navigator !== "undefined" && navigator.vibrate) {
                  navigator.vibrate(50);
                }
                setSelectedCluster(cluster);
              }
            }}
          />
        ))}
      </MapContainer>

      {/* Floating Toggles over the map */}
      <MapToggles activeLayer={activeLayer} setActiveLayer={setActiveLayer} />

      {/* Map Legend */}
      <div className="absolute top-14 right-2.5 z-[1000] bg-slate-800/90 rounded-xl px-3 py-2">
         <div className="flex flex-col gap-2">
            <div className="flex items-center gap-2">
               <div className="w-2.5 h-2.5 rounded-full bg-[#DC2626]"></div>
               <span className="text-white text-xs font-semibold">{t("severe")}</span>
            </div>
            <div className="flex items-center gap-2">
               <div className="w-2.5 h-2.5 rounded-full bg-[#F97316]"></div>
               <span className="text-white text-xs font-semibold">{t("moderate")}</span>
            </div>
            <div className="flex items-center gap-2">
               <div className="w-2.5 h-2.5 rounded-full bg-[#D97706]"></div>
               <span className="text-white text-xs font-semibold">{t("low")}</span>
            </div>
         </div>
      </div>

      {/* Climate Risk Card */}
      {activeLayer === "climate" && (() => {
        // Support both direct attributes and nested "current" layout from /api/weather
        const temp = weatherData?.current?.temp_c || weatherData?.temp || 28;
        const humidity = weatherData?.current?.humidity || weatherData?.humidity || 50;
        const wind = weatherData?.current?.wind_speed_kmh || weatherData?.wind || 10;
        const description = weatherData?.current?.description || weatherData?.description || "";
        const district = ctx.district || "Pune";
        const climateRisks = getClimateRisks(temp, humidity, wind, description);

        return (
          <div className="absolute bottom-0 left-0 right-0 bg-white rounded-t-2xl p-4 z-[1000] shadow-[0_-4px_20px_rgba(0,0,0,0.15)]">
            <div className="text-xs text-gray-500 text-center mb-3 font-medium">
              📍 {district} · {temp}°C · Humidity {humidity}% · Wind {wind} km/h
            </div>
            
            {climateRisks.map((risk, i) => (
              <div key={i} className={`flex gap-3 p-3 rounded-xl mb-2 
                ${risk.level === 'high' ? 'bg-red-50 border-l-4 border-red-500' :
                  risk.level === 'medium' ? 'bg-amber-50 border-l-4 border-amber-400' :
                  'bg-green-50 border-l-4 border-green-500'}`}>
                <span className="text-xl">{risk.icon}</span>
                <div>
                  <div className="text-xs font-bold text-gray-900">{risk.title}</div>
                  <div className="text-xs text-gray-600 mt-0.5">{risk.advice}</div>
                </div>
              </div>
            ))}
          </div>
        );
      })()}

      {/* Bottom Sheet overlay */}
      <OutbreakBottomSheet 
        cluster={selectedCluster as any} 
        onClose={() => setSelectedCluster(null)} 
      />
    </div>
  );
}
