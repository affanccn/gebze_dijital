// Delete events older than 2026-10-01 from Firestore
const BASE_URL = 'https://firestore.googleapis.com/v1/projects/gebze-dijital/databases/(default)/documents';

async function getAdminToken() {
  const authRes = await fetch(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyD4CqNJxmmKPTTnFqjzHbFvvH3FZN8VIRM',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'admin@gebze.bel.tr',
        password: 'GebzeAdmin2026!',
        returnSecureToken: true
      })
    }
  );
  const authData = await authRes.json();
  if (!authData.idToken) {
    throw new Error('Auth failed: ' + JSON.stringify(authData));
  }
  return authData.idToken;
}

async function getAllEvents(token) {
  let allDocs = [];
  let pageToken = '';
  do {
    const url = `${BASE_URL}/events?pageSize=300${pageToken ? '&pageToken=' + pageToken : ''}`;
    const res = await fetch(url, {
      headers: { Authorization: 'Bearer ' + token }
    });
    const data = await res.json();
    if (data.documents) {
      allDocs = allDocs.concat(data.documents);
    }
    pageToken = data.nextPageToken || '';
  } while (pageToken);
  return allDocs;
}

async function deleteEvent(name, token) {
  const res = await fetch(`https://firestore.googleapis.com/v1/${name}`, {
    method: 'DELETE',
    headers: { Authorization: 'Bearer ' + token }
  });
  return res.ok;
}

async function main() {
  console.log('Authenticating as admin...');
  const token = await getAdminToken();
  console.log('Fetching all events...');
  const docs = await getAllEvents(token);
  console.log(`Total events in Firestore: ${docs.length}`);

  let deleted = 0;
  let kept = 0;

  for (const doc of docs) {
    const dateStr = doc.fields?.date?.stringValue || doc.fields?.tarih?.stringValue || '';
    // Keep October 2026, November 2026, December 2026, etc. (date >= 2026-10-01)
    if (!dateStr || dateStr < '2026-10-01') {
      const ok = await deleteEvent(doc.name, token);
      if (ok) {
        deleted++;
      } else {
        console.warn('Failed to delete:', doc.name);
      }
    } else {
      kept++;
    }
  }

  console.log(`\nCleanup finished:`);
  console.log(`Deleted (older than 2026-10-01): ${deleted}`);
  console.log(`Kept (October, November and beyond): ${kept}`);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
