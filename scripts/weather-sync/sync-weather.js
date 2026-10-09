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

  // weatherapi.com endpoint for Gebze, 3 days forecast
  const url = `http://api.weatherapi.com/v1/forecast.json?key=${apiKey}&q=Gebze&days=3&aqi=no&alerts=no&lang=tr`;

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
  
  // Hava durumu bilgisini tek bir dökümanda tutmak mantıklıdır (örneğin "gebze" id'li döküman)
  const ref = db.collection(COLLECTION).doc("gebze"); 
  
  batch.set(ref, {
    current: {
      temp_c: weatherData.current.temp_c,
      condition: weatherData.current.condition.text,
      icon: weatherData.current.condition.icon,
      humidity: weatherData.current.humidity,
      wind_kph: weatherData.current.wind_kph,
      feelslike_c: weatherData.current.feelslike_c
    },
    forecast: weatherData.forecast ? weatherData.forecast.forecastday.map(day => ({
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
    })) : [],
    syncedAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
  console.log("Hava durumu senkronizasyonu tamamlandı.");
}

main().catch((error) => {
  console.error("Hava durumu senkronizasyonu başarısız:", error);
  process.exitCode = 1;
});
