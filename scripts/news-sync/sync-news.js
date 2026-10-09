const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const cheerio = require("cheerio");

initializeApp({
  credential: cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)),
});

const BASE = "https://www.gebze.bel.tr";
const MONTHS = { ocak:0, şubat:1, mart:2, nisan:3, mayıs:4, haziran:5,
                 temmuz:6, ağustos:7, eylül:8, ekim:9, kasım:10, aralık:11 };
const DATE_RE = /(\d{1,2})\s+(\p{L}+)\s+(\d{4})/u;

function parseDate(text) {
  const m = text.match(DATE_RE);
  if (!m) return null;
  const month = MONTHS[m[2].toLocaleLowerCase("tr")];
  if (month === undefined) return null;
  return Timestamp.fromDate(new Date(Date.UTC(+m[3], month, +m[1])));
}

async function scrapeList(page = "haberler.html") {
  const res = await fetch(`${BASE}/${page}`, {
    headers: { "User-Agent": "GebzeDijitalApp/1.0 (iletisim@ornek.com)" },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const $ = cheerio.load(await res.text());
  const items = new Map();

  $('h3 a[href*="/haber/"]').each((_, a) => {
    const href = $(a).attr("href") || "";
    const idMatch = href.match(/_(\d+)\.html$/);
    if (!idMatch || items.has(idMatch[1])) return;

    let box = $(a).parent();
    for (let i = 0; i < 4 && !(box.find("img").length && DATE_RE.test(box.text())); i++) {
      box = box.parent();
    }
    const img = box.find("img").first().attr("src");
    items.set(idMatch[1], {
      id: idMatch[1],
      title: $(a).text().trim(),
      url: new URL(href, BASE).href,
      imageUrl: img ? new URL(img, BASE).href : null,
      publishedAt: parseDate(box.text()),
    });
  });
  return [...items.values()];
}

async function main() {
  const db = getFirestore();
  const items = await scrapeList();
  if (items.length === 0) throw new Error("0 haber parse edildi, site yapısı değişmiş olabilir");

  const isFirstRun = (await db.collection("news").limit(1).get()).empty;
  const fresh = [];

  for (const n of items) {
    const ref = db.collection("news").doc(n.id);
    if ((await ref.get()).exists) continue;
    await ref.set({
      ...n,
      source: "gebze.bel.tr",
      isPublished: true,
      fetchedAt: FieldValue.serverTimestamp(),
    });
    fresh.push(n);
  }

  if (!isFirstRun && fresh.length > 0) {
    await getMessaging().send({
      topic: "news",
      notification: {
        title: fresh.length === 1 ? "Gebze Belediyesi" : `${fresh.length} yeni haber`,
        body: fresh[0].title,
      },
      data: { type: "news", newsId: fresh[0].id },
    });
  }
  console.log(`Bitti. Yeni haber: ${fresh.length}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
