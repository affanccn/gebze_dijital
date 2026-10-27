// Script to clean up duplicate records from Firestore
// Uses Firestore REST API with document deletion and deterministic seeding

const BASE_URL = 'https://firestore.googleapis.com/v1/projects/gebze-dijital/databases/(default)/documents';

async function deleteDoc(col, id) {
  try {
    const res = await fetch(`${BASE_URL}/${col}/${id}`, { method: 'DELETE' });
    return res.ok;
  } catch (e) {
    console.error(`Error deleting ${col}/${id}:`, e.message);
    return false;
  }
}

async function setDoc(col, id, fields) {
  try {
    const res = await fetch(`${BASE_URL}/${col}/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fields })
    });
    return res.ok;
  } catch (e) {
    console.error(`Error writing ${col}/${id}:`, e.message);
    return false;
  }
}

async function getCollectionDocs(col) {
  try {
    const res = await fetch(`${BASE_URL}/${col}?pageSize=300`);
    const data = await res.json();
    return data.documents || [];
  } catch (e) {
    console.error(`Error fetching ${col}:`, e.message);
    return [];
  }
}

async function cleanCollection(col, keyField) {
  console.log(`\n--- Cleaning collection: ${col} (Key: ${keyField}) ---`);
  const docs = await getCollectionDocs(col);
  console.log(`Found ${docs.length} total documents.`);
  
  const grouped = {};
  docs.forEach(d => {
    const id = d.name.split('/').pop();
    let val = d.fields?.[keyField]?.stringValue;
    if (!val) {
      // try other common fields
      val = d.fields?.title?.stringValue || d.fields?.name?.stringValue || d.fields?.question?.stringValue || id;
    }
    const normKey = val.trim().toLowerCase();
    if (!grouped[normKey]) grouped[normKey] = [];
    grouped[normKey].push({ id, val, createTime: d.createTime || d.updateTime });
  });

  let deletedCount = 0;
  for (const [normKey, list] of Object.entries(grouped)) {
    if (list.length > 1) {
      // Sort: keep the most recent or the one with a clean/semantic ID
      list.sort((a, b) => new Date(b.createTime) - new Date(a.createTime));
      const keep = list[0];
      const duplicates = list.slice(1);
      console.log(`Keeping: "${keep.val}" (${keep.id}), Deleting ${duplicates.length} duplicate(s)...`);
      for (const dup of duplicates) {
        const ok = await deleteDoc(col, dup.id);
        if (ok) deletedCount++;
      }
    }
  }
  console.log(`[${col}] Deleted ${deletedCount} duplicate documents. Remaining unique: ${Object.keys(grouped).length}`);
}

async function seedCleanVetClinics() {
  console.log('\n--- Seeding 5 official Gebze Duty Vet Clinics with deterministic IDs ---');
  const clinics = [
    {
      id: 'vet_gebze_pati',
      name: { stringValue: 'Gebze Pati Veteriner Kliniği (7/24 Nöbetçi)' },
      district: { stringValue: 'Gebze / Kocaeli' },
      address: { stringValue: 'Hacıhalil Mah. Hükümet Cad. No:42/A, Gebze/Kocaeli' },
      phone: { stringValue: '(0262) 641 22 33' },
      emergencyHours: { stringValue: '7/24 Acil Nöbetçi Hizmeti' },
      latitude: { doubleValue: 40.8035 },
      longitude: { doubleValue: 29.4320 },
      is24Hours: { booleanValue: true }
    },
    {
      id: 'vet_anka',
      name: { stringValue: 'Anka Veteriner Tıp Merkezi & Cerrahi' },
      district: { stringValue: 'Gebze / Kocaeli' },
      address: { stringValue: 'Osman Yılmaz Mah. İstanbul Cad. No:88, Gebze/Kocaeli' },
      phone: { stringValue: '(0262) 646 10 20' },
      emergencyHours: { stringValue: '24 Saat Acil Müdahale & Yoğun Bakım' },
      latitude: { doubleValue: 40.8005 },
      longitude: { doubleValue: 29.4270 },
      is24Hours: { booleanValue: true }
    },
    {
      id: 'vet_dostlar',
      name: { stringValue: 'Dostlar Veteriner Kliniği' },
      district: { stringValue: 'Gebze / Kocaeli' },
      address: { stringValue: 'Tatlıkuyu Mah. Güney Yanyol Cad. No:15, Gebze/Kocaeli' },
      phone: { stringValue: '(0262) 644 55 66' },
      emergencyHours: { stringValue: 'Hafta içi & Hafta sonu Gece Nöbeti (09:00 - 02:00)' },
      latitude: { doubleValue: 40.7970 },
      longitude: { doubleValue: 29.4225 },
      is24Hours: { booleanValue: false }
    },
    {
      id: 'vet_mavi_pati',
      name: { stringValue: 'Mavi Pati Veteriner Kliniği' },
      district: { stringValue: 'Gebze / Kocaeli' },
      address: { stringValue: 'Mevlana Mah. Issıkgöl Cad. No:62/B, Gebze/Kocaeli' },
      phone: { stringValue: '(0262) 643 78 90' },
      emergencyHours: { stringValue: '7/24 Acil Çağrı & Müdahale' },
      latitude: { doubleValue: 40.8140 },
      longitude: { doubleValue: 29.4380 },
      is24Hours: { booleanValue: true }
    },
    {
      id: 'vet_eskihisar',
      name: { stringValue: 'Eskihisar Veteriner Kliniği' },
      district: { stringValue: 'Gebze / Kocaeli' },
      address: { stringValue: 'İstasyon Mah. Çerkeşli Cad. No:24, Gebze/Kocaeli' },
      phone: { stringValue: '(0262) 655 40 50' },
      emergencyHours: { stringValue: '08:30 - 23:00 / Acil Telefon Hattı Açık' },
      latitude: { doubleValue: 40.7850 },
      longitude: { doubleValue: 29.4310 },
      is24Hours: { booleanValue: false }
    }
  ];

  for (const c of clinics) {
    const { id, ...fields } = c;
    await setDoc('vet_clinics', id, fields);
    console.log(`  Seeded clinic ${id}: ${fields.name.stringValue}`);
  }
}

async function main() {
  console.log('=== STARTING FIRESTORE DEDUPLICATION ===');
  
  // 1. Clean vet clinics
  await cleanCollection('vet_clinics', 'name');
  
  // 2. Also remove any old random ID clinics that match the 5 official ones, and seed deterministic ones
  await seedCleanVetClinics();
  // Clean again to remove any old random ID variants that have the same name
  await cleanCollection('vet_clinics', 'name');

  // 3. Clean feeding points
  await cleanCollection('feeding_points', 'title');

  // 4. Clean pet adoptions
  await cleanCollection('pet_adoptions', 'name');

  // 5. Clean ebelediye categories
  await cleanCollection('ebelediye_categories', 'name');

  // 6. Clean outages
  await cleanCollection('outages', 'title');

  // 7. Clean suggestions
  await cleanCollection('suggestions', 'title');

  // 8. Clean events
  await cleanCollection('events', 'title');

  // 9. Clean municipal news
  await cleanCollection('municipal_news', 'title');

  console.log('\n=== DEDUPLICATION COMPLETED SUCCESSFULLY ===');
}

main();
