import * as cheerio from "cheerio";
import { createHash } from "node:crypto";
import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { Agent, setGlobalDispatcher } from "undici";

// GitHub Actions runner'ları (yurt dışı bulut IP'leri) ile belediye sunucusu arasındaki
// ağ gecikmeleri ve paket kayıplarında 10 saniyelik varsayılan zaman aşımı yetersiz kalıyordu.
// Bağlantı ve yanıt zaman aşımlarını 45 saniyeye yükseltiyoruz.
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
const NEWS_URL = `${BASE_URL}/haberler.html`;
const COLLECTION = "municipal_news";
const MAX_PAGES = 20;

const BROWSER_HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept":
    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
  "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8",
  "Cache-Control": "no-cache",
  "Pragma": "no-cache",
};

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

  if (
    !serviceAccount.project_id ||
    !serviceAccount.client_email ||
    !serviceAccount.private_key
  ) {
    throw new Error("Servis hesabı JSON dosyasında gerekli alanlar eksik.");
  }

  if (!getApps().length) {
    initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  }

  return getFirestore();
}

/**
 * Sayfa HTML'ini çeker; bağlantı zaman aşımı veya geçici ağ hatalarında
 * exponential backoff ile tekrar dener.
 */
async function getHtml(url, maxRetries = 3) {
  let lastError;
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`Bağlanılıyor (${attempt}/${maxRetries}): ${url}`);
      const response = await fetch(url, {
        headers: BROWSER_HEADERS,
        signal: AbortSignal.timeout(45000),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${url}`);
      }

      return await response.text();
    } catch (error) {
      lastError = error;
      console.warn(
        `⚠️ İstek başarısız (${attempt}/${maxRetries}) - ${url}: ${error?.message || error}`
      );
      if (attempt < maxRetries) {
        const delayMs = attempt * 3000;
        console.log(`⏳ ${delayMs / 1000} saniye sonra tekrar deneniyor...`);
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }
  }
  throw lastError;
}

/**
 * Türkçe metni hedef dile (en: İngilizce, ar: Arapça) çevirir.
 * Ücretsiz ve sınırsız Google Translate web servisini kullanır.
 * Hata veya zaman aşımında güvenle orijinal metne geri döner.
 */
async function translateText(text, targetLang) {
  if (!text || !text.trim()) return "";
  const clean = text.trim().slice(0, 1200); // güvenli uzunluk sınırı

  try {
    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=tr&tl=${targetLang}&dt=t&q=${encodeURIComponent(clean)}`;
    const response = await fetch(url, {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        "Accept": "*/*",
      },
      signal: AbortSignal.timeout(10000),
    });

    if (!response.ok) {
      return clean;
    }

    const data = await response.json();
    if (Array.isArray(data) && Array.isArray(data[0])) {
      const translated = data[0]
        .map((segment) => segment[0])
        .filter(Boolean)
        .join("");
      return translated.trim() || clean;
    }
  } catch (err) {
    console.warn(`[Çeviri Hatası] (${targetLang}): ${err?.message || err}`);
  }

  return clean;
}

/**
 * Haber detay sayfasından ilk anlamlı paragrafı özet olarak çeker.
 */
async function fetchNewsSummary(url) {
  if (!url) return "";
  try {
    const html = await getHtml(url, 2);
    const $detail = cheerio.load(html);
    let summary = "";
    $detail("p").each((_, p) => {
      const text = $detail(p).text().replace(/\s+/g, " ").trim();
      if (
        !summary &&
        text.length > 50 &&
        !text.includes("Tüm Hakları Saklıdır") &&
        !text.includes("Mahallesi") &&
        !text.includes("KOCAELİ")
      ) {
        summary = text;
      }
    });
    return summary;
  } catch (err) {
    return "";
  }
}

function absoluteUrl(value, base = BASE_URL) {
  if (!value) return "";
  try {
    return new URL(value, base).href;
  } catch {
    return "";
  }
}

/**
 * URL'deki encoding farklarını (örn: %E2%80%9C vs “) normalize eder.
 * Bu sayede aynı haber farklı URL varyasyonlarıyla çiftlenmez.
 */
function canonicalUrl(url) {
  if (!url) return "";
  try {
    return decodeURI(url).trim();
  } catch {
    return url.trim();
  }
}


// "08 Ekim 2026" biçimindeki tarihi yakalar (site bu biçimi kullanıyor).
const TR_DATE_RE =
  /(\d{1,2})\s+(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s+(\d{4})/i;

// Bazı bağlantılarda başlık iki kez yazılıyor ("A A" -> "A").
function cleanTitle(value) {
  const s = (value ?? "").replace(/\s+/g, " ").trim();
  if (s.length % 2 === 1) {
    const h = (s.length - 1) / 2;
    if (s[h] === " " && s.slice(0, h) === s.slice(h + 1)) return s.slice(0, h);
  }
  return s;
}

// URL sonundaki sayı (…_7418.html veya .../617) haberin site içi kimliği; yeniden eskiye sıralamada kullanılır.
function newsIdFromUrl(url) {
  const m = url.match(/(?:_|\/)(\d+)(?:\.html)?(?:$|\?)/);
  return m ? Number(m[1]) : null;
}

function imageSrc(img) {
  return absoluteUrl(img.attr("src") || img.attr("data-src") || "");
}

// Başlığı saran, TEK habere ait ve tarih içeren en yakın kutuyu bulur.
function findCard($, link) {
  let node = link.parent();
  for (let i = 0; i < 5 && node.length; i++) {
    const urls = new Set(
      node
        .find('a[href*="/haber/"]')
        .map((_, a) => absoluteUrl($(a).attr("href")))
        .get()
    );
    if (urls.size > 1) return null; // birden fazla haberi kapsıyor, çok geniş
    if (TR_DATE_RE.test(node.text())) return node;
    node = node.parent();
  }
  return null;
}

function extractNews($, pageIndex) {
  const byUrl = new Map(); // url -> kayıt (ilk görülme sırası korunur)

  $('a[href*="/haber/"]').each((_, element) => {
    const link = $(element);
    const url = canonicalUrl(absoluteUrl(link.attr("href")));
    if (!url || !url.includes("/haber/")) return;

    let rec = byUrl.get(url);
    if (!rec) {
      rec = { title: "", titleRank: 0, image: "", publishedAtText: "" };
      byUrl.set(url, rec);
    }

    const inHeading = link.closest("h1, h2, h3, h4").length > 0;
    const img = link.find("img").first();

    if (inHeading) {
      // En güvenilir başlık: haber kartındaki <h3> bağlantısı.
      const title = cleanTitle(link.text());
      if (title && rec.titleRank < 3) {
        rec.title = title;
        rec.titleRank = 3;
      }
      const card = findCard($, link);
      if (card) {
        const dateMatch = card.text().replace(/\s+/g, " ").match(TR_DATE_RE);
        if (dateMatch && !rec.publishedAtText) rec.publishedAtText = dateMatch[0];
        const cardImg = card.find("img").first();
        if (cardImg.length && !rec.image) rec.image = imageSrc(cardImg);
      }
    } else if (img.length) {
      if (!rec.image) rec.image = imageSrc(img);
      const alt = cleanTitle(img.attr("alt"));
      if (alt && rec.titleRank < 2) {
        rec.title = alt;
        rec.titleRank = 2;
      }
    } else {
      // Slider gibi yerlerdeki düz metin bağlantısı: son çare.
      const title = cleanTitle(link.attr("title") || link.text());
      if (title && rec.titleRank < 1) {
        rec.title = title;
        rec.titleRank = 1;
      }
    }
  });

  const items = [];
  for (const [url, rec] of byUrl) {
    if (!rec.title) continue;
    items.push({
      title: rec.title,
      url,
      image: rec.image,
      publishedAtText: rec.publishedAtText,
      newsId: newsIdFromUrl(url),
      pageIndex,
      itemIndex: items.length,
    });
  }
  return items;
}

async function main() {
  const db = initializeFirebase();

  let firstHtml;
  try {
    firstHtml = await getHtml(NEWS_URL);
  } catch (error) {
    const isTimeout =
      error?.code === "UND_ERR_CONNECT_TIMEOUT" ||
      error?.cause?.code === "UND_ERR_CONNECT_TIMEOUT" ||
      error?.name === "TimeoutError" ||
      error?.message?.includes("Connect Timeout") ||
      error?.message?.includes("fetch failed");

    if (isTimeout) {
      console.warn(
        "\n⚠️ [GEÇİCİ AĞ UYARISI] www.gebze.bel.tr adresine tüm denemelere rağmen bağlanılamadı (ConnectTimeoutError)." +
        "\nBelediye sunucusu şu an geçici olarak erişilemez durumda olabilir." +
        "\nMevcut Firestore verileri korundu. Bir sonraki zamanlanmış çalıştırmada tekrar denenecek.\n"
      );
      return;
    }
    throw error;
  }

  const $first = cheerio.load(firstHtml);

  // İlk sayfa ve HTML'de bulunan sayfalama bağlantıları.
  const pages = new Set([NEWS_URL]);

  $first(".news-pagination a.page-btn").each((_, element) => {
    const href = $first(element).attr("href");
    const url = absoluteUrl(href, NEWS_URL);

    if (
      url.startsWith(`${BASE_URL}/`) &&
      /haberler(?:_\d+)?\.html(?:$|\?)/.test(url)
    ) {
      pages.add(url);
    }
  });

  const pageList = [...pages].slice(0, MAX_PAGES);
  const allNews = new Map();

  for (let i = 0; i < pageList.length; i++) {
    const pageUrl = pageList[i];

    try {
      const html =
        pageUrl === NEWS_URL
          ? firstHtml
          : await getHtml(pageUrl);

      const $ = cheerio.load(html);
      const items = extractNews($, i + 1);

      for (const item of items) {
        // Canonical URL üzerinden SHA256 kimlik: aynı haber tekrar eklenmez.
        const canonUrl = canonicalUrl(item.url);
        const id = createHash("sha256")
          .update(canonUrl)
          .digest("hex");

        allNews.set(id, { id, ...item, url: canonUrl });
      }

      console.log(`Sayfa ${i + 1}: ${items.length} haber (${pageUrl})`);
    } catch (error) {
      console.error(`Sayfa alınamadı (${pageUrl}):`, error?.message || error);
    }
  }

  if (allNews.size === 0) {
    console.warn(
      "⚠️ Hiç haber verisi çözümlenemedi. Mevcut Firestore verilerine dokunulmadı."
    );
    return;
  }

  const entries = [...allNews.values()];

  // 1. Firestore'da halihazırda var olan haberlerin çevirilerini çek (akıllı önbellek) ve çift kayıtları temizle
  console.log("Firestore'daki mevcut haber kayıtları ve çevirileri taranıyor...");
  const translationCache = new Map();
  const existingByNewsId = new Map();
  const duplicatesToDelete = [];

  try {
    const existingSnapshot = await db.collection(COLLECTION).get();
    for (const doc of existingSnapshot.docs) {
      const data = doc.data();
      const newsId = data.newsId;

      if (newsId) {
        if (existingByNewsId.has(newsId)) {
          console.warn(`⚠️ Çift kayıt tespit edildi (newsId: ${newsId}, doc: ${doc.id}). Temizlenecek.`);
          duplicatesToDelete.push(doc.id);
        } else {
          existingByNewsId.set(newsId, doc.id);
        }
      }

      translationCache.set(doc.id, {
        title_en: data.title_en || "",
        title_ar: data.title_ar || "",
        summary: data.summary || "",
        summary_en: data.summary_en || "",
        summary_ar: data.summary_ar || "",
      });
    }

    if (duplicatesToDelete.length > 0) {
      console.log(`${duplicatesToDelete.length} adet mükerrer doküman Firestore'dan siliniyor...`);
      for (const dupId of duplicatesToDelete) {
        await db.collection(COLLECTION).doc(dupId).delete();
      }
    }
    console.log(`Mevcut ${translationCache.size} doküman önbelleğe alındı.`);
  } catch (err) {
    console.warn("Önbellek okunamadı, çeviriler sıfırdan kontrol edilecek:", err?.message || err);
  }

  // 2. Eksik çevirileri tespit et ve tamamla
  let translatedCount = 0;
  console.log("Haber başlıkları ve özetleri çoklu dil için (EN, AR) kontrol ediliyor...");

  for (let i = 0; i < entries.length; i++) {
    const item = entries[i];
    const cached = translationCache.get(item.id);

    // Başlık çevirileri
    if (cached?.title_en && cached?.title_ar) {
      item.title_en = cached.title_en;
      item.title_ar = cached.title_ar;
    } else {
      item.title_en = await translateText(item.title, "en");
      item.title_ar = await translateText(item.title, "ar");
      translatedCount++;
      await new Promise((r) => setTimeout(r, 150)); // rate-limit önlemi
    }

    // Özet (özellikle en yeni 15 haber için özet metni Firestore'a kaydedilir)
    let summary = cached?.summary || "";
    let summaryEn = cached?.summary_en || "";
    let summaryAr = cached?.summary_ar || "";

    if (!summary && i < 15) {
      summary = await fetchNewsSummary(item.url);
    }

    if (summary) {
      item.summary = summary;
      if (summaryEn && summaryAr) {
        item.summary_en = summaryEn;
        item.summary_ar = summaryAr;
      } else {
        item.summary_en = await translateText(summary, "en");
        item.summary_ar = await translateText(summary, "ar");
        await new Promise((r) => setTimeout(r, 150));
      }
    } else {
      item.summary = cached?.summary || "";
      item.summary_en = cached?.summary_en || "";
      item.summary_ar = cached?.summary_ar || "";
    }
  }

  console.log(
    `Çeviri adımı tamamlandı (${translatedCount} yeni/güncellenen haber çevrildi).`
  );

  // Firestore batch sınırını aşmamak için parçalı yaz.
  for (let start = 0; start < entries.length; start += 400) {
    const batch = db.batch();

    for (const item of entries.slice(start, start + 400)) {
      const { id, ...data } = item;
      const ref = db.collection(COLLECTION).doc(id);

      batch.set(
        ref,
        {
          ...data,
          source: "Gebze Belediyesi",
          syncedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    await batch.commit();
  }

  console.log(`✅ Senkronizasyon tamamlandı: ${entries.length} haber işlendi.`);
}

main().catch((error) => {
  const isTimeout =
    error?.code === "UND_ERR_CONNECT_TIMEOUT" ||
    error?.cause?.code === "UND_ERR_CONNECT_TIMEOUT" ||
    error?.name === "TimeoutError" ||
    error?.message?.includes("Connect Timeout") ||
    error?.message?.includes("fetch failed");

  if (isTimeout) {
    console.warn(
      "\n⚠️ [UYARI] Belediye sunucusuna bağlantı sağlanamadığı için senkronizasyon pas geçildi." +
      "\nFirestore veritabanı güvenle korundu.\n"
    );
    process.exitCode = 0;
    return;
  }

  console.error("Haber senkronizasyonu başarısız:", error);
  process.exitCode = 1;
});