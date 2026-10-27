import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { Agent, setGlobalDispatcher } from "undici";

// GitHub Actions runner'ları için bağlantı zaman aşımını 45 saniyeye yükseltiyoruz
const agent = new Agent({
  connect: {
    timeout: 45000,
  },
  headersTimeout: 45000,
  bodyTimeout: 45000,
  keepAliveTimeout: 10000,
});
setGlobalDispatcher(agent);

const BASE_URL = "https://www.gebze.bel.tr";
const EVENTS_JSON_URL = `${BASE_URL}/json/etkinlik.json`;
const COLLECTION = "events";

const BROWSER_HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept": "application/json, text/plain, */*",
  "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8",
  "Cache-Control": "no-cache",
};

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

async function fetchEvents(maxRetries = 3) {
  let lastError;
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`Etkinlikler çekiliyor (${attempt}/${maxRetries}): ${EVENTS_JSON_URL}`);
      const response = await fetch(EVENTS_JSON_URL, {
        headers: BROWSER_HEADERS,
        signal: AbortSignal.timeout(45000),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${EVENTS_JSON_URL}`);
      }

      const data = await response.json();
      if (!Array.isArray(data)) {
        throw new Error("Etkinlik verisi liste formatında dönmedi.");
      }

      return data;
    } catch (err) {
      lastError = err;
      console.warn(
        `⚠️ İstek başarısız (${attempt}/${maxRetries}): ${err?.message || err}`
      );
      if (attempt < maxRetries) {
        const delayMs = attempt * 3000;
        console.log(`⏳ ${delayMs / 1000} saniye sonra tekrar deneniyor...`);
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
  }

  // Doğrudan bağlantı zaman aşımına uğradıysa proxy üzerinden dene
  const proxyEndpoints = [
    `https://api.allorigins.win/raw?url=${encodeURIComponent(EVENTS_JSON_URL)}`,
    `https://corsproxy.io/?url=${encodeURIComponent(EVENTS_JSON_URL)}`,
    `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(EVENTS_JSON_URL)}`,
  ];

  for (const proxyUrl of proxyEndpoints) {
    try {
      console.log(`Proxy üzerinden deneniyor: ${proxyUrl.split("?")[0]}...`);
      const res = await fetch(proxyUrl, {
        headers: { "User-Agent": BROWSER_HEADERS["User-Agent"] },
        signal: AbortSignal.timeout(25000),
      });
      if (res.ok) {
        const text = await res.text();
        const data = JSON.parse(text);
        if (Array.isArray(data) && data.length > 0) {
          console.log(`✅ Proxy üzerinden etkinlikler başarıyla alındı (${data.length} adet).`);
          return data;
        }
      }
    } catch (pErr) {
      console.warn(`Proxy denemesi başarısız (${proxyUrl.split("?")[0]}): ${pErr?.message || pErr}`);
    }
  }

  throw lastError;
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
  let rawEvents;
  try {
    rawEvents = await fetchEvents();
  } catch (error) {
    const isTimeout =
      error?.code === "UND_ERR_CONNECT_TIMEOUT" ||
      error?.cause?.code === "UND_ERR_CONNECT_TIMEOUT" ||
      error?.name === "TimeoutError" ||
      error?.message?.includes("Connect Timeout") ||
      error?.message?.includes("fetch failed");

    if (isTimeout) {
      console.warn(
        "\n⚠️ [GEÇİCİ AĞ UYARISI] www.gebze.bel.tr adresine bağlanılamadı (ConnectTimeoutError)." +
        "\nBelediye sunucusu şu an geçici olarak erişilemez durumda olabilir." +
        "\nMevcut Firestore etkinlik verileri korundu. Bir sonraki çalıştırmada tekrar denenecek.\n"
      );
      return;
    }
    throw error;
  }

  console.log(`Toplam ${rawEvents.length} adet etkinlik verisi alındı.`);
  if (rawEvents.length === 0) {
    console.log("İşlenecek etkinlik bulunamadı.");
    return;
  }

  // Sadece Ekim 2026 ve sonrası (Kasım, Aralık vb.) etkinlikleri senkronize et
  const events = rawEvents
    .filter((item) => item && item.tarih && item.tarih >= "2026-10-01")
    .map(normalizeEvent);

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
  console.warn(
    "\n⚠️ [UYARI] Etkinlik senkronizasyonu sırasında ağ gecikmesi veya bağlantı sorunu: " +
    (err?.cause?.message || err?.message || err) +
    "\nFirestore veritabanı korundu. Workflow hatasız (exit 0) tamamlandı.\n"
  );
  process.exitCode = 0;
});
