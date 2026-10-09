import * as cheerio from "cheerio";
import { createHash } from "node:crypto";
import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const BASE_URL = "https://www.gebze.bel.tr";
const NEWS_URL = `${BASE_URL}/haberler.html`;
const COLLECTION = "municipal_news";
const MAX_PAGES = 20;


function initializeFirebase() {
  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (!rawServiceAccount) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT GitHub Secret eksik."
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

async function getHtml(url) {
  const response = await fetch(url, {
    headers: {
      "User-Agent": "GebzeDijitalNewsBot/1.0",
      "Accept": "text/html",
    },
    signal: AbortSignal.timeout(20000),
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${url}`);
  }

  return response.text();
}

function absoluteUrl(value, base = BASE_URL) {
  if (!value) return "";
  try {
    return new URL(value, base).href;
  } catch {
    return "";
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

// URL sonundaki sayı (…_7418.html) haberin site içi kimliği; yeniden eskiye sıralamada kullanılır.
function newsIdFromUrl(url) {
  const m = url.match(/_(\d+)\.html(?:$|\?)/);
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
    const url = absoluteUrl(link.attr("href"));
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
  const firstHtml = await getHtml(NEWS_URL);
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
        // URL'den sabit kimlik: aynı haber tekrar eklenmez.
        const id = createHash("sha256")
          .update(item.url)
          .digest("hex");

        allNews.set(id, { id, ...item });
      }

      console.log(
        `Sayfa ${i + 1}: ${items.length} haber (${pageUrl})`
      );
    } catch (error) {
      console.error(`Sayfa alınamadı: ${pageUrl}`, error.message);
      throw error;
    }
  }

  if (allNews.size === 0) {
    throw new Error(
      "Hiç haber bulunamadı. HTML seçicilerini kontrol edin; boş veriyle senkronizasyonu başarılı saymayın."
    );
  }

  const entries = [...allNews.values()];

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

  console.log(
    `Senkronizasyon tamamlandı: ${entries.length} haber işlendi.`
  );
}

main().catch((error) => {
  console.error("Haber senkronizasyonu başarısız:", error);
  process.exitCode = 1;
});