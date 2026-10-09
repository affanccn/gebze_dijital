import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const COLLECTION = "pharmacies_on_duty";
const API_URL = "https://api.collectapi.com/health/dutyPharmacy?ilce=Gebze&il=Kocaeli";

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

  // Assuming apiKey format provided is full token or just needs to be passed.
  // We use collectapi style as default. If the API key is "eczane_api_...", we pass it directly in the header.
  const response = await fetch(API_URL, {
    headers: {
      "authorization": apiKey.startsWith("apikey ") ? apiKey : `apikey ${apiKey}`,
      "content-type": "application/json"
    }
  });

  if (!response.ok) {
    throw new Error(`API hatası: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  if (!data.success || !data.result) {
    throw new Error("API'den beklenen formatta veri alınamadı.");
  }

  return data.result; // Array of pharmacies
}

async function main() {
  const db = initializeFirebase();
  const pharmacies = await fetchPharmacies();
  
  if (pharmacies.length === 0) {
    console.log("Bugün için nöbetçi eczane bulunamadı.");
    return;
  }

  const batch = db.batch();
  
  // Önce eski nöbetçi eczaneleri temizleyelim (sadece bugünün verisi kalsın)
  const oldDocs = await db.collection(COLLECTION).get();
  oldDocs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  // Yeni eczaneleri ekleyelim
  pharmacies.forEach((pharmacy) => {
    const ref = db.collection(COLLECTION).doc(); // Auto ID
    batch.set(ref, {
      name: pharmacy.name || "",
      address: pharmacy.address || "",
      phone: pharmacy.phone || "",
      district: pharmacy.dist || "Gebze",
      loc: pharmacy.loc || "", // "lat,lng" formatında gelebilir
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
