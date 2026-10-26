import * as cheerio from "cheerio";
import { createHash } from "node:crypto";
import { writeFileSync } from "node:fs";
import { Agent, setGlobalDispatcher } from "undici";

const agent = new Agent({
  connect: { timeout: 45000 },
  headersTimeout: 45000,
  bodyTimeout: 45000
});
setGlobalDispatcher(agent);

const BASE_URL = "https://www.gebze.bel.tr";
const NEWS_URL = `${BASE_URL}/haberler.html`;

const BROWSER_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
  "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8",
  "Cache-Control": "no-cache"
};

const TR_DATE_RE = /(\d{1,2})\s+(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s+(\d{4})/i;

function cleanTitle(value) {
  const s = (value ?? "").replace(/\s+/g, " ").trim();
  if (s.length % 2 === 1) {
    const h = (s.length - 1) / 2;
    if (s[h] === " " && s.slice(0, h) === s.slice(h + 1)) return s.slice(0, h);
  }
  return s;
}

function newsIdFromUrl(url) {
  const m = url.match(/(?:_|\/)(\d+)(?:\.html)?(?:$|\?)/);
  return m ? Number(m[1]) : null;
}

function absoluteUrl(value, base = BASE_URL) {
  if (!value) return "";
  try {
    return new URL(value, base).href;
  } catch {
    return "";
  }
}

function canonicalUrl(url) {
  if (!url) return "";
  try {
    return decodeURI(url).trim();
  } catch {
    return url.trim();
  }
}

async function translateText(text, targetLang) {
  if (!text || !text.trim()) return "";
  const clean = text.trim().slice(0, 500);
  try {
    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=tr&tl=${targetLang}&dt=t&q=${encodeURIComponent(clean)}`;
    const res = await fetch(url, { signal: AbortSignal.timeout(6000) });
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data) && Array.isArray(data[0])) {
        return data[0].map(s => s[0]).filter(Boolean).join("").trim() || clean;
      }
    }
  } catch {}
  return clean;
}

async function fetchNewsSummary(url) {
  if (!url) return "";
  try {
    const res = await fetch(url, { headers: BROWSER_HEADERS, signal: AbortSignal.timeout(10000) });
    if (!res.ok) return "";
    const html = await res.text();
    const $ = cheerio.load(html);
    let summary = "";
    $("p").each((_, p) => {
      const text = $(p).text().replace(/\s+/g, " ").trim();
      if (!summary && text.length > 50 && !text.includes("Tüm Hakları Saklıdır") && !text.includes("KOCAELİ")) {
        summary = text;
      }
    });
    return summary;
  } catch {
    return "";
  }
}

async function main() {
  console.log("🌐 Gebze Belediyesi haberler sayfası taranıyor...");
  const res = await fetch(NEWS_URL, { headers: BROWSER_HEADERS });
  if (!res.ok) throw new Error("Sayfa açılamadı: " + res.status);
  const firstHtml = await res.text();
  const $first = cheerio.load(firstHtml);

  const pages = new Set([NEWS_URL]);
  $first(".news-pagination a.page-btn").each((_, element) => {
    const href = $first(element).attr("href");
    const url = absoluteUrl(href, NEWS_URL);
    if (url.startsWith(`${BASE_URL}/`) && /haberler(?:_\d+)?\.html(?:$|\?)/.test(url)) {
      pages.add(url);
    }
  });

  const pageList = [...pages].slice(0, 3); // İlk 3 sayfa (~45 haber)
  const allNews = new Map();

  for (let i = 0; i < pageList.length; i++) {
    const pageUrl = pageList[i];
    console.log(`Sayfa ${i + 1} taranıyor: ${pageUrl}`);
    const html = pageUrl === NEWS_URL ? firstHtml : await (await fetch(pageUrl, { headers: BROWSER_HEADERS })).text();
    const $ = cheerio.load(html);

    $('a[href*="/haber/"]').each((_, element) => {
      const link = $(element);
      const url = canonicalUrl(absoluteUrl(link.attr("href")));
      if (!url || !url.includes("/haber/")) return;

      const title = cleanTitle(link.closest("h1, h2, h3, h4").text() || link.find("img").first().attr("alt") || link.text());
      if (!title || title.length < 5) return;

      const newsId = newsIdFromUrl(url);
      const id = createHash("sha256").update(url).digest("hex");

      let image = absoluteUrl(link.find("img").first().attr("src") || link.closest("div, article").find("img").first().attr("src") || "");
      let publishedAtText = "";
      const dateMatch = link.closest("div, article").text().match(TR_DATE_RE);
      if (dateMatch) publishedAtText = dateMatch[0];

      if (!allNews.has(id)) {
        allNews.set(id, {
          id,
          title,
          url,
          image,
          publishedAtText,
          newsId,
          pageIndex: i + 1,
          itemIndex: allNews.size
        });
      }
    });
  }

  const entries = [...allNews.values()];
  console.log(`Toplam ${entries.length} haber tespit edildi. Özetler ve çeviriler çekiliyor...`);

  for (let i = 0; i < Math.min(entries.length, 20); i++) {
    const item = entries[i];
    console.log(`[${i + 1}/${Math.min(entries.length, 20)}] Özet & Çeviri: ${item.title.substring(0, 40)}...`);
    item.summary = await fetchNewsSummary(item.url);
    item.title_en = await translateText(item.title, "en");
    item.title_ar = await translateText(item.title, "ar");
    if (item.summary) {
      item.summary_en = await translateText(item.summary, "en");
      item.summary_ar = await translateText(item.summary, "ar");
    }
  }

  // gebze_haber_cache.js dosyasına yaz
  const jsContent = `// GEBZE BELEDİYESİ GÜNCEL RESMİ HABERLER ÖNBELLEĞİ (${new Date().toLocaleDateString('tr-TR')})\nwindow.GEBZE_OFFICIAL_NEWS = ${JSON.stringify(entries, null, 2)};\n`;
  writeFileSync("c:/Users/Asus/gebze_dijital/gebze_dijital/admin/gebze_haber_cache.js", jsContent, "utf-8");
  console.log("✅ admin/gebze_haber_cache.js başarıyla oluşturuldu!");
}

main().catch(console.error);
