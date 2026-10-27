const collectionsToCheck = [
  { name: 'vet_clinics', keyField: 'name' },
  { name: 'feeding_points', keyField: 'title' },
  { name: 'pet_adoptions', keyField: 'name' },
  { name: 'ebelediye_categories', keyField: 'name' },
  { name: 'outages', keyField: 'title' },
  { name: 'suggestions', keyField: 'title' },
  { name: 'polls', keyField: 'question' },
  { name: 'municipal_news', keyField: 'title' }
];

async function scan() {
  console.log('=== DUPLICATE ANALYSIS ===');
  for (const { name, keyField } of collectionsToCheck) {
    const res = await fetch(`https://firestore.googleapis.com/v1/projects/gebze-dijital/databases/(default)/documents/${name}?pageSize=300`);
    const data = await res.json();
    const docs = data.documents || [];
    const grouped = {};
    
    docs.forEach(d => {
      const id = d.name.split('/').pop();
      const val = d.fields?.[keyField]?.stringValue || id;
      const normKey = val.trim().toLowerCase();
      if (!grouped[normKey]) grouped[normKey] = [];
      grouped[normKey].push({ id, val, createTime: d.createTime });
    });

    let dupCount = 0;
    const toDelete = [];
    Object.entries(grouped).forEach(([k, list]) => {
      if (list.length > 1) {
        dupCount += (list.length - 1);
        // Keep the latest or first, mark others for deletion
        // Let's sort by createTime
        list.sort((a, b) => new Date(b.createTime) - new Date(a.createTime));
        const keep = list[0];
        const remove = list.slice(1);
        toDelete.push(...remove.map(r => ({ ...r, col: name, keepId: keep.id })));
      }
    });

    console.log(`[${name}] Total: ${docs.length}, Unique: ${Object.keys(grouped).length}, Redundant duplicates to remove: ${dupCount}`);
    if (toDelete.length > 0) {
      console.log(`  Sample redundant IDs to delete in ${name}:`, toDelete.slice(0, 5).map(x => x.id).join(', '));
    }
  }
}

scan();
