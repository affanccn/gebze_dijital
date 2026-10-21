import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const BASE_URL = "https://www.gebze.bel.tr";
const EVENTS_JSON_URL = `${BASE_URL}/json/etkinlik.json`;
const COLLECTION = "events";

const TR_MONTHS = [
  "",
  "Ocak",
  "Şubat",
  "Mart",
  "Nisan",
  "Mayıs",
  "Haziran",
  "Temmuz",
  "Ağustos",
  "Eylül",
  "Ekim",
  "Kasım",
  "Aralık"
];

function formatTrDate(dateStr) {
  if (!dateStr || !dateStr.includes("-")) return dateStr || "";
  const parts = dateStr.split("-");
  if (parts.length !== 3) return dateStr;
  const day = parseInt(parts[2], 10);
  const month = parseInt(parts[1], 10);
  const year = parts[0];
  const monthName = TR_MONTHS[month] || "";
  return `${day} ${monthName} ${year}`.trim();
}

function initializeFirebase() {
  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (!rawServiceAccount) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT ortam değişkeni (GitHub Secret) eksik."
    );
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(rawServiceAccount);
  } catch {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT geçerli bir JSON değil."
    );
  }

  if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
    throw new Error(
      "Servis hesabı JSON dosyasında gerekli alanlar eksik."
    );
  }

  if (!getApps().length) {
    initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  }

  return getFirestore();
}

async function fetchEvents() {
  console.log(`Etkinlikler çekiliyor: ${EVENTS_JSON_URL}`);
  const response = await fetch(EVENTS_JSON_URL, {
    headers: {
      "User-Agent": "GebzeDijitalEventsBot/1.0",
      "Accept": "application/json",
    },
    signal: AbortSignal.timeout(20000),
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${EVENTS_JSON_URL}`);
  }

  const data = await response.json();
  if (!Array.isArray(data)) {
    throw new Error("Etkinlik verisi liste formatında dönmedi.");
  }

  return data;
}

function normalizeEvent(item) {
  const id = String(item.id || Date.now());
  const title = (item.baslik || "").trim();
  const category = (item.kategori || "Genel").trim();
  const location = (item.konum || "Gebze").trim();
  const date = (item.tarih || "").trim();
  const time = (item.saat || "").trim();
  const formattedDate = formatTrDate(date);

  const subtitleParts = [];
  if (location) subtitleParts.push(location);
  if (formattedDate) subtitleParts.push(formattedDate);
  if (time) subtitleParts.push(time);
  const subtitle = subtitleParts.join(" • ");

  const rawImg = (item.resim || "").trim();
  const image = rawImg
    ? (rawImg.startsWith("http") ? rawImg : `${BASE_URL}/${rawImg}`)
    : "";

  const rawUrl = (item.url || "").trim();
  const url = rawUrl
    ? (rawUrl.startsWith("http") ? rawUrl : `${BASE_URL}/${rawUrl}`)
    : `${BASE_URL}/etkinlik.html`;

  return {
    id,
    title,
    name: title,
    category,
    location,
    address: location,
    date,
    time,
    formattedDate,
    subtitle,
    description: (item.aciklama || category).trim(),
    image,
    imageUrl: image,
    url,
    source: "Gebze Belediyesi",
    syncedAt: FieldValue.serverTimestamp(),
  };
}

async function main() {
  const db = initializeFirebase();
  const rawEvents = await fetchEvents();

  console.log(`Toplam ${rawEvents.length} adet etkinlik verisi alındı.`);
  if (rawEvents.length === 0) {
    console.log("İşlenecek etkinlik bulunamadı.");
    return;
  }

  const events = rawEvents.map(normalizeEvent);

  // Firestore batch limit 500, 400'lük parçalarla yaz
  for (let start = 0; start < events.length; start += 400) {
    const chunk = events.slice(start, start + 400);
    const batch = db.batch();

    for (const item of chunk) {
      const { id, ...data } = item;
      const docRef = db.collection(COLLECTION).doc(`etkinlik_${id}`);
      batch.set(docRef, { ...data, eventId: id }, { merge: true });
    }

    await batch.commit();
    console.log(`Batch yazıldı: ${chunk.length} etkinlik.`);
  }

  console.log(`✅ Senkronizasyon tamamlandı: ${events.length} etkinlik Firestore'a aktarıldı.`);
}

main().catch((err) => {
  console.error("Etkinlik senkronizasyonu hatası:", err);
  process.exitCode = 1;
});
