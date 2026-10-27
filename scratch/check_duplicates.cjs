const collections = [
  'vet_clinics', 'polls', 'suggestions', 'pet_adoptions', 'feeding_points',
  'assembly_areas', 'events', 'municipal_news', 'outages', 'neighborhood_works',
  'pharmacies_on_duty', 'ebelediye_categories', 'broadcast_notifications'
];

async function check() {
  for (const col of collections) {
    try {
      const res = await fetch('https://firestore.googleapis.com/v1/projects/gebze-dijital/databases/(default)/documents/' + col + '?pageSize=300');
      const data = await res.json();
      const docs = data.documents || [];
      const map = {};
      const docDetails = [];
      docs.forEach(d => {
        const id = d.name.split('/').pop();
        const f = d.fields || {};
        const key = f.name?.stringValue || f.title?.stringValue || f.question?.stringValue || id;
        map[key] = (map[key] || 0) + 1;
        docDetails.push({ id, key });
      });
      const dupes = Object.entries(map).filter(([k, v]) => v > 1);
      console.log(`[${col}] Total: ${docs.length}, Unique: ${Object.keys(map).length}, Duplicates: ${dupes.length}`);
      if (dupes.length > 0) {
        console.log('  Dupes:', JSON.stringify(dupes));
      }
    } catch(e) {
      console.error(col, e.message);
    }
  }
}
check();
