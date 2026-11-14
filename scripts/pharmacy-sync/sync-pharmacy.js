import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const COLLECTION = "pharmacies_on_duty";
const API_URL = "https://eczaneapi.com/api/v1/pharmacies/on-duty?city=kocaeli&district=gebze";

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

async function fetchPharmacies() {
  const apiKey = process.env.PHARMACY_API_KEY;
  if (!apiKey) {
    throw new Error("PHARMACY_API_KEY GitHub Secret eksik.");
  }

  const response = await fetch(API_URL, {
    headers: {
      "X-API-Key": apiKey,
      "content-type": "application/json"
    }
  });

  if (!response.ok) {
    throw new Error(`API hatası: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  if (!data.success || !data.data) {
    throw new Error("API'den beklenen formatta veri alınamadı.");
  }

  const todayData = data.data.find(d => d.day === "Bugün" || d.day === "Today");
  if (!todayData || !todayData.pharmacies) {
    return [];
  }

  return todayData.pharmacies;
}

async function main() {
  const db = initializeFirebase();
  const pharmacies = await fetchPharmacies();

  if (pharmacies.length === 0) {
    console.log("Bugün için nöbetçi eczane bulunamadı.");
    return;
  }

  const batch = db.batch();

  const oldDocs = await db.collection(COLLECTION).get();
  oldDocs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  pharmacies.forEach((pharmacy) => {
    const ref = db.collection(COLLECTION).doc();
    batch.set(ref, {
      name: pharmacy.name || "",
      address: pharmacy.address || "",
      phone: pharmacy.phone || "",
      district: pharmacy.district?.name || "Gebze",
      loc: pharmacy.location ? `${pharmacy.location.latitude},${pharmacy.location.longitude}` : "",

      syncedAt: FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
  console.log(`Senkronizasyon tamamlandı: ${pharmacies.length} nöbetçi eczane eklendi.`);
}

main().catch((error) => {
  console.error("Eczane senkronizasyonu başarısız:", error);
  process.exitCode = 1;
});
