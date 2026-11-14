import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const COLLECTION = "weather_info";

function initializeFirebase() {
  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!rawServiceAccount) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT GitHub Secret eksik.");
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(rawServiceAccount);
  } catch {
    throw new Error("FIREBASE_SERVICE_ACCOUNT geçerli bir JSON değil.");
  }

  if (!getApps().length) {
    initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  }

  return getFirestore();
}

async function fetchWeather() {
  const apiKey = process.env.WEATHER_API_KEY;
  if (!apiKey) {
    throw new Error("WEATHER_API_KEY GitHub Secret eksik.");
  }

  const url = `http://api.weatherapi.com/v1/forecast.json?key=${apiKey}&q=Gebze&days=5&aqi=no&alerts=no&lang=tr`;

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`API hatası: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  return data;
}

async function main() {
  const db = initializeFirebase();
  const weatherData = await fetchWeather();
  
  if (!weatherData || !weatherData.current) {
    throw new Error("API'den beklenen hava durumu verisi alınamadı.");
  }

  const batch = db.batch();
  
  const ref = db.collection(COLLECTION).doc("gebze"); 
  
  let finalForecast = weatherData.forecast ? weatherData.forecast.forecastday.map(day => ({
    date: day.date,
    maxtemp_c: day.day.maxtemp_c,
    mintemp_c: day.day.mintemp_c,
    condition: day.day.condition.text,
    icon: day.day.condition.icon,
    hourly: day.hour ? day.hour.map((h) => ({
      time: h.time,
      temp_c: h.temp_c,
      icon: h.condition.icon,
    })) : []
  })) : [];

  if (finalForecast.length < 5) {
    try {
      const omUrl = 'https://api.open-meteo.com/v1/forecast?latitude=40.8037&longitude=29.4398&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=5&timezone=Europe%2FIstanbul';
      const omRes = await fetch(omUrl);
      if (omRes.ok) {
        const omData = await omRes.json();
        if (omData && omData.daily && omData.daily.time) {
          const wCodeMap = (code) => {
            if (code === 0) return { text: "Güneşli", icon: "//cdn.weatherapi.com/weather/64x64/day/113.png" };
            if ([1, 2].includes(code)) return { text: "Parçalı Bulutlu", icon: "//cdn.weatherapi.com/weather/64x64/day/116.png" };
            if (code === 3) return { text: "Bulutlu", icon: "//cdn.weatherapi.com/weather/64x64/day/119.png" };
            if ([45, 48].includes(code)) return { text: "Sisli", icon: "//cdn.weatherapi.com/weather/64x64/day/143.png" };
            if ([51, 53, 55, 61, 63, 65, 80, 81, 82].includes(code)) return { text: "Yağmurlu", icon: "//cdn.weatherapi.com/weather/64x64/day/296.png" };
            if ([71, 73, 75, 85, 86].includes(code)) return { text: "Karlı", icon: "//cdn.weatherapi.com/weather/64x64/day/326.png" };
            if ([95, 96, 99].includes(code)) return { text: "Gök Gürültülü Fırtına", icon: "//cdn.weatherapi.com/weather/64x64/day/389.png" };
            return { text: "Parçalı Bulutlu", icon: "//cdn.weatherapi.com/weather/64x64/day/116.png" };
          };

          for (let i = 0; i < omData.daily.time.length; i++) {
            const dStr = omData.daily.time[i];
            const alreadyExists = finalForecast.some(f => f.date === dStr);
            if (!alreadyExists) {
              const cond = wCodeMap(omData.daily.weather_code[i]);
              finalForecast.push({
                date: dStr,
                maxtemp_c: omData.daily.temperature_2m_max[i],
                mintemp_c: omData.daily.temperature_2m_min[i],
                condition: cond.text,
                icon: cond.icon,
                hourly: []
              });
            }
          }
        }
      }
    } catch (e) {
      console.warn("Open-Meteo ek gün tamamlama hatası:", e.message);
    }
  }

  batch.set(ref, {
    current: {
      temp_c: weatherData.current.temp_c,
      condition: weatherData.current.condition.text,
      icon: weatherData.current.condition.icon,
      humidity: weatherData.current.humidity,
      wind_kph: weatherData.current.wind_kph,
      feelslike_c: weatherData.current.feelslike_c
    },
    forecast: finalForecast,
    syncedAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
  console.log(`Hava durumu senkronizasyonu tamamlandı (${finalForecast.length} gün).`);
}

main().catch((error) => {
  console.error("Hava durumu senkronizasyonu başarısız:", error);
  process.exitCode = 1;
});
