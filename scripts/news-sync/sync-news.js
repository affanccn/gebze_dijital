
import * as cheerio from "cheerio";
import { createHash } from "node:crypto";
import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const BASE_URL = "https://www.gebze.bel.tr";
const NEWS_URL = `${BASE_URL}/haberler.html`;
const COLLECTION = "municipal_news";
const MAX_PAGES = 20;

function initializeFirebase() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (!projectId || !rawServiceAccount) {
    throw new Error("Firebase GitHub Secrets eksik.");
  }

  const serviceAccount = JSON.parse(rawServiceAccount);

  if (!getApps().length) {
    initializeApp({
      credential: cert(serviceAccount),
      projectId,
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

function extractNews($, pageIndex) {
  const items = [];
  const seen = new Set();

  $('a[href*="/haber/"]').each((_, element) => {
    const link = $(element);
    const href = link.attr("href");
    const url = absoluteUrl(href);

    if (!url || !url.includes("/haber/")) return;

    // Haber detay bağlantısına en yakın olası kartı bul.
    const card = link.closest(
      ".slider-item, .news-item, .haber-item, " +
      ".news-card, .haber-kart, article"
    );

    const container = card.length ? card : link;

    const imageElement =
      container.find("img").first().length
        ? container.find("img").first()
        : link.find("img").first();

    const title =
      container.find(
        ".slider-title, .news-title, .haber-baslik, h1, h2, h3"
      ).first().text().trim() ||
      imageElement.attr("alt")?.trim() ||
      link.attr("title")?.trim() ||
      link.text().trim();

    if (!title || seen.has(url)) return;

    // Tarihi sadece kartta bulunuyorsa al.
    const cardText = container.text().replace(/\s+/g, " ").trim();
    const dateMatch = cardText.match(
      /\b\d{1,2}[./-]\d{1,2}[./-]\d{4}\b/
    );

    seen.add(url);

    items.push({
      title,
      url,
      image: absoluteUrl(imageElement.attr("src")),
      publishedAtText: dateMatch?.[0] ?? "",
      pageIndex,
      itemIndex: items.length,
    });
  });

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