// ══════════════════════════════════════════════════════════════════════════════
// GEBZE BELEDİYESİ • DİJİTAL YÖNETİM PORTALI - CORE CONTROLLER
// ══════════════════════════════════════════════════════════════════════════════

import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import {
  getFirestore,
  setDoc,
  Timestamp,
  collection,
  addDoc,
  getDocs,
  deleteDoc,
  doc,
  updateDoc,
  serverTimestamp,
  query,
  orderBy,
  onSnapshot,
  where,
  getCountFromServer
} from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";
import {
  getAuth,
  signInWithEmailAndPassword,
  onAuthStateChanged,
  signOut
} from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";

// Firebase Proje Yapılandırması (Canlı)
const firebaseConfig = {
  apiKey: "AIzaSyD4CqNJxmmKPTTnFqjzHbFvvH3FZN8VIRM",
  authDomain: "gebze-dijital.firebaseapp.com",
  projectId: "gebze-dijital",
  storageBucket: "gebze-dijital.firebasestorage.app",
  messagingSenderId: "417554808986",
  appId: "1:417554808986:web:aea3daf07f5b6534301f23"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

window.db = db;
window.auth = auth;

// Global Durum Değişkenleri
window.reportsCache = [];
window.reportsUnsub = null;
window.activeReportId = null;
window.activeSuggestionId = null;
window.eventsListCache = [];
window.usersListCache = [];
window.usersMap = {};

// ─────────────────────────────────────────────────────────────────────────────
// 1. OTURUM & YÖNETİCİ KİMLİK DOĞRULAMA
// ─────────────────────────────────────────────────────────────────────────────
onAuthStateChanged(auth, (user) => {
  const overlay = document.getElementById('loginOverlay');
  const who = document.getElementById('adminWho');
  const out = document.getElementById('btnSignOut');
  if (user) {
    if (overlay) overlay.style.display = 'none';
    if (who) who.innerText = user.email || 'Yetkili Yönetici (Aktif)';
    if (out) out.style.display = 'inline-flex';
  }
});

// Otomatik oturum dene
if (!auth.currentUser) {
  signInWithEmailAndPassword(auth, "admin@gebze.bel.tr", "GebzeAdmin2026!")
    .then(() => {
      const overlay = document.getElementById('loginOverlay');
      if (overlay) overlay.style.display = 'none';
      const who = document.getElementById('adminWho');
      if (who) who.innerText = 'admin@gebze.bel.tr (Aktif)';
      const out = document.getElementById('btnSignOut');
      if (out) out.style.display = 'inline-flex';
      refreshAllData();
    })
    .catch((err) => {
      console.warn("Otomatik oturum:", err.message);
      refreshAllData();
    });
}

window.adminQuickSignIn = async () => {
  const overlay = document.getElementById('loginOverlay');
  if (overlay) overlay.style.display = 'none';
  const who = document.getElementById('adminWho');
  const out = document.getElementById('btnSignOut');
  try {
    await signInWithEmailAndPassword(auth, "admin@gebze.bel.tr", "GebzeAdmin2026!");
  } catch (err) {
    console.warn("Hızlı oturum uyarısı:", err);
  }
  if (who) who.innerText = auth.currentUser?.email || 'Yetkili Yönetici (Canlı)';
  if (out) out.style.display = 'inline-flex';
  refreshAllData();
  showToast("Yönetici paneli başarıyla açıldı.");
};

window.bypassLogin = () => {
  const overlay = document.getElementById('loginOverlay');
  if (overlay) overlay.style.display = 'none';
  const who = document.getElementById('adminWho');
  if (who) who.innerText = 'Yönetici (Önizleme Modu)';
  refreshAllData();
  showToast("Önizleme modunda açıldı.");
};

window.adminSignIn = async (e) => {
  e.preventDefault();
  const errBox = document.getElementById('loginError');
  const btn = document.getElementById('loginBtn');
  errBox.innerText = '';
  btn.disabled = true;
  try {
    await signInWithEmailAndPassword(
      auth,
      document.getElementById('loginEmail').value.trim(),
      document.getElementById('loginPassword').value
    );
    document.getElementById('loginPassword').value = '';
  } catch (err) {
    const msgs = {
      'auth/invalid-credential': 'E-posta veya şifre hatalı.',
      'auth/invalid-email': 'Geçerli bir e-posta adresi girin.',
      'auth/user-disabled': 'Bu hesap devre dışı bırakılmış.',
      'auth/too-many-requests': 'Çok fazla deneme yapıldı, lütfen bekleyip tekrar deneyin.'
    };
    errBox.innerText = msgs[err.code] || ('Giriş hatası: ' + err.message);
  } finally {
    btn.disabled = false;
  }
};

window.adminSignOut = async () => {
  if (confirm('Yönetim panelinden güvenli çıkış yapılsın mı?')) {
    if (window.reportsUnsub) window.reportsUnsub();
    await signOut(auth);
    const overlay = document.getElementById('loginOverlay');
    if (overlay) overlay.style.display = 'flex';
  }
};

function refreshAllData() {
  loadDashboard();
  initRealtimeReports();
  // loadUsers() kaldırıldı; sadece kullanıcılar sekmesine girildiğinde yüklenir.
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. NAVİGASYON & MODÜL YÖNETİMİ
// ─────────────────────────────────────────────────────────────────────────────
window.switchNav = (tabId, title, subtitle) => {
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.tab-view').forEach(el => el.classList.remove('active'));

  const navBtn = document.getElementById('nav-' + tabId);
  if (navBtn) navBtn.classList.add('active');

  const targetTab = document.getElementById('view-' + tabId);
  if (targetTab) targetTab.classList.add('active');

  const hTitle = document.getElementById('headerTitle');
  const hSubtitle = document.getElementById('headerSubtitle');
  if (hTitle) hTitle.innerText = title || 'Yönetim Portalı';
  if (hSubtitle) hSubtitle.innerText = subtitle || 'Gebze Belediyesi Dijital Hizmetler';

  // İlgili modül verilerini yükle
  if (tabId === 'dashboard') loadDashboard();
  if (tabId === 'reports') renderReportsView();
  if (tabId === 'suggestions') loadSuggestions();
  if (tabId === 'polls') loadPolls();
  if (tabId === 'guide') loadGuidePlaces();
  if (tabId === 'foods') loadFoods();
  if (tabId === 'picnic') loadPicnic();
  if (tabId === 'nurseries') loadNurseries();
  if (tabId === 'news') loadNews();
  if (tabId === 'events') loadEvents();
  if (tabId === 'broadcast') loadBroadcastHistory();
  if (tabId === 'outages') loadOutages();
  if (tabId === 'works') loadWorks();
  if (tabId === 'pharmacies') loadPharmacies();
  if (tabId === 'assembly') loadAssemblyAreas();
  if (tabId === 'pets') loadPatiData();
  if (tabId === 'ebelediye') loadEBelediye();
  if (tabId === 'users') loadUsers();

  const sidebar = document.getElementById('sidebar');
  if (sidebar) sidebar.classList.remove('open');
};

window.toggleSidebar = () => {
  const sidebar = document.getElementById('sidebar');
  if (sidebar) sidebar.classList.toggle('open');
};

// ─────────────────────────────────────────────────────────────────────────────
// 3. GENEL BAKIŞ (DASHBOARD - AGGREGATION & CACHE OPTİMİZE)
// ─────────────────────────────────────────────────────────────────────────────
let _adminDashboardCache = null;
let _adminDashboardCacheTime = 0;
const ADMIN_DASHBOARD_CACHE_TTL = 5 * 60 * 1000; // 5 dakika TTL

function applyAdminDashboardData(data) {
  setKpi('kpiReports', data.pendingReports);
  const bRep = document.getElementById('badgePendingReports');
  if (bRep && data.pendingReports !== null) {
    bRep.innerText = data.pendingReports;
    bRep.style.display = data.pendingReports > 0 ? 'inline-block' : 'none';
  }

  setKpi('kpiSuggestions', data.pendingSugg);
  const bSugg = document.getElementById('badgePendingSugg');
  if (bSugg && data.pendingSugg !== null) {
    bSugg.innerText = data.pendingSugg;
    bSugg.style.display = data.pendingSugg > 0 ? 'inline-block' : 'none';
  }

  setKpi('kpiNews', data.news);
  setKpi('kpiPolls', data.polls);
  setKpi('kpiOutages', data.outages);
  setKpi('kpiPets', data.pets);
  setKpi('kpiPharmacies', data.pharmacies);
  setKpi('kpiAssembly', data.assembly);
  setKpi('kpiUsers', data.users);
  setKpi('kpiEvents', data.events);
  setKpi('kpiGuide', data.places);
  setKpi('kpiNurseries', data.nurseries);
  setKpi('kpiFoods', data.foods);
  setKpi('kpiPicnic', data.picnic);
  setKpi('kpiWorks', data.works);
}

async function loadDashboard(forceRefresh = false) {
  const now = Date.now();
  if (!forceRefresh && _adminDashboardCache && (now - _adminDashboardCacheTime < ADMIN_DASHBOARD_CACHE_TTL)) {
    applyAdminDashboardData(_adminDashboardCache);
    return;
  }

  const safeCount = async (target) => {
    try {
      const q = typeof target === 'string' ? collection(db, target) : target;
      const snap = await getCountFromServer(q);
      return snap.data().count;
    } catch (err) {
      console.warn(`[safeCount] sayım uyarısı:`, err.message);
      return null;
    }
  };

  try {
    const [
      newsCount,
      pollsCount,
      outagesCount,
      petsCount,
      pharmaciesCount,
      assemblyCount,
      usersCount,
      eventsCount,
      placesCount,
      nurseriesCount,
      foodsCount,
      picnicCount,
      worksCount,
      pendingReportsCount,
      pendingSuggCount
    ] = await Promise.all([
      safeCount("municipal_news"),
      safeCount("polls"),
      safeCount("outages"),
      safeCount("pet_adoptions"),
      safeCount("pharmacies_on_duty"),
      safeCount("assembly_areas"),
      safeCount("users"),
      safeCount("events"),
      safeCount("guide_places"),
      safeCount("nurseries"),
      safeCount("guide_foods"),
      safeCount("guide_picnic"),
      safeCount("neighborhood_works"),
      safeCount(query(collection(db, "reports"), where("status", "in", ["Beklemede", "İnceleniyor", "İşleme Alındı", "pending"])))
        .catch(() => safeCount("reports")),
      safeCount(query(collection(db, "suggestions"), where("approved", "==", false)))
        .catch(() => safeCount("suggestions"))
    ]);

    _adminDashboardCache = {
      news: newsCount ?? (_adminDashboardCache?.news ?? '-'),
      polls: pollsCount ?? (_adminDashboardCache?.polls ?? '-'),
      outages: outagesCount ?? (_adminDashboardCache?.outages ?? '-'),
      pets: petsCount ?? (_adminDashboardCache?.pets ?? '-'),
      pharmacies: pharmaciesCount ?? (_adminDashboardCache?.pharmacies ?? '-'),
      assembly: assemblyCount ?? (_adminDashboardCache?.assembly ?? '-'),
      users: usersCount ?? (_adminDashboardCache?.users ?? '-'),
      events: eventsCount ?? (_adminDashboardCache?.events ?? '-'),
      places: placesCount ?? (_adminDashboardCache?.places ?? '-'),
      nurseries: nurseriesCount ?? (_adminDashboardCache?.nurseries ?? '-'),
      foods: foodsCount ?? (_adminDashboardCache?.foods ?? '-'),
      picnic: picnicCount ?? (_adminDashboardCache?.picnic ?? '-'),
      works: worksCount ?? (_adminDashboardCache?.works ?? '-'),
      pendingReports: pendingReportsCount ?? (_adminDashboardCache?.pendingReports ?? 0),
      pendingSugg: pendingSuggCount ?? (_adminDashboardCache?.pendingSugg ?? 0)
    };
    _adminDashboardCacheTime = Date.now();

    applyAdminDashboardData(_adminDashboardCache);
  } catch (err) {
    console.error("Dashboard yüklenirken hata:", err);
  }
}
window.loadDashboard = loadDashboard;

function setKpi(id, val) {
  const el = document.getElementById(id);
  if (el) el.innerText = val;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. VATANDAŞ BAŞVURULARI & ULAKBEL ÇÖZÜM MASASI
// ─────────────────────────────────────────────────────────────────────────────
async function initRealtimeReports() {
  if (window.reportsUnsub) window.reportsUnsub();

  // Kullanıcı önbelleğini gerekirse arka planda güncelle
  if (!window.usersMap || Object.keys(window.usersMap).length === 0) {
    try {
      const uSnap = await getDocs(collection(db, "users"));
      window.usersMap = window.usersMap || {};
      uSnap.forEach(d => { window.usersMap[d.id] = d.data(); });
    } catch (_) { }
  }

  try {
    const q = query(collection(db, "reports"));
    window.reportsUnsub = onSnapshot(q, (snapshot) => {
      const list = [];
      snapshot.forEach(docSnap => {
        list.push({ id: docSnap.id, ...docSnap.data() });
      });
      list.sort((a, b) => {
        const ta = a.createdAt?.toMillis ? a.createdAt.toMillis() : (a.createdAt ? new Date(a.createdAt).getTime() : 0);
        const tb = b.createdAt?.toMillis ? b.createdAt.toMillis() : (b.createdAt ? new Date(b.createdAt).getTime() : 0);
        return tb - ta;
      });
      window.reportsCache = list;

      let pendingCount = 0;
      list.forEach(r => {
        const st = (r.status || '').trim();
        if (st === 'Beklemede' || st === 'İnceleniyor' || st === 'İşleme Alındı' || st === 'pending') pendingCount++;
      });
      const bRep = document.getElementById('badgePendingReports');
      if (bRep) {
        bRep.innerText = pendingCount;
        bRep.style.display = pendingCount > 0 ? 'inline-block' : 'none';
      }
      setKpi('kpiReports', pendingCount);

      renderReportsView();
    }, (err) => {
      console.warn("Reports snapshot uyarısı:", err.message);
      const tbody = document.getElementById("reportsTableBody");
      if (tbody && (!window.reportsCache || window.reportsCache.length === 0)) {
        tbody.innerHTML = `<tr><td colspan="7" class="empty-state">
          ℹ️ Vatandaş başvurularını listelemek için yönetici hesabıyla oturum açınız.
        </td></tr>`;
      }
    });
  } catch (e) {
    console.error("initRealtimeReports hatası:", e);
  }
}
window.initRealtimeReports = initRealtimeReports;

const REPORT_STATUS_MAP = {
  'Beklemede': { label: 'Beklemede', cls: 'badge-warning' },
  'pending': { label: 'Beklemede', cls: 'badge-warning' },
  'İnceleniyor': { label: 'İnceleniyor', cls: 'badge-primary' },
  'reviewing': { label: 'İnceleniyor', cls: 'badge-primary' },
  'İşleme Alındı': { label: 'İşleme Alındı', cls: 'badge-info' },
  'in_progress': { label: 'İşleme Alındı', cls: 'badge-info' },
  'Çözüldü': { label: 'Çözüldü', cls: 'badge-success' },
  'resolved': { label: 'Çözüldü', cls: 'badge-success' },
  'Reddedildi': { label: 'Reddedildi', cls: 'badge-danger' },
  'rejected': { label: 'Reddedildi', cls: 'badge-danger' }
};

function renderReportsView() {
  const container = document.getElementById("reportsTableBody");
  const gridContainer = document.getElementById("reportsGrid");
  if (!container || !gridContainer) return;

  const filterStatus = document.getElementById("reportFilterStatus")?.value || 'all';
  const filterHood = document.getElementById("reportFilterNeighborhood")?.value || '';
  const filterCat = document.getElementById("reportFilterCategory")?.value || '';
  const searchTxt = (document.getElementById("reportSearch")?.value || '').trim().toLowerCase();

  const filtered = (window.reportsCache || []).filter(r => {
    const s = (r.status || 'Beklemede').trim();
    if (filterStatus === 'pending' && (s !== 'Beklemede' && s !== 'pending')) return false;
    if (filterStatus === 'reviewing' && (s !== 'İnceleniyor' && s !== 'reviewing')) return false;
    if (filterStatus === 'in_progress' && (s !== 'İşleme Alındı' && s !== 'in_progress')) return false;
    if (filterStatus === 'resolved' && (s !== 'Çözüldü' && s !== 'resolved')) return false;
    if (filterStatus === 'rejected' && (s !== 'Reddedildi' && s !== 'rejected')) return false;

    if (filterHood && r.neighborhood !== filterHood) return false;
    if (filterCat && r.category !== filterCat && r.categoryKey !== filterCat) return false;

    if (searchTxt) {
      const matchTicket = (r.ticketNo || '').toLowerCase().includes(searchTxt);
      const matchName = (r.userName || '').toLowerCase().includes(searchTxt);
      const matchPhone = (r.userPhone || '').toLowerCase().includes(searchTxt);
      const matchDesc = (r.description || '').toLowerCase().includes(searchTxt);
      if (!matchTicket && !matchName && !matchPhone && !matchDesc) return false;
    }
    return true;
  });

  const b = document.getElementById('reportCountBadge');
  if (b) b.innerText = `${filtered.length} Talep`;

  if (filtered.length === 0) {
    container.innerHTML = `<tr><td colspan="7" class="empty-state">Kriterlere uygun başvuru kaydı bulunamadı.</td></tr>`;
    gridContainer.innerHTML = `<div class="empty-state">Kriterlere uygun başvuru kaydı bulunamadı.</div>`;
    return;
  }

  // 1. Tablo Görünümü
  container.innerHTML = '';
  filtered.forEach(r => {
    const tr = document.createElement("tr");
    const stInfo = REPORT_STATUS_MAP[r.status] || { label: r.status || 'Beklemede', cls: 'badge-warning' };

    let dateStr = '–';
    if (r.createdAt?.toMillis) {
      dateStr = new Date(r.createdAt.toMillis()).toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
    } else if (r.createdAt) {
      dateStr = new Date(r.createdAt).toLocaleDateString('tr-TR');
    }

    const ticketNo = r.ticketNo || ('GBZ-' + r.id.substring(0, 6).toUpperCase());
    const userName = r.userName || (r.userId && window.usersMap[r.userId]?.fullName) || 'Gebze Sakini';
    const location = [r.neighborhood, r.address].filter(Boolean).join(' • ') || 'Gebze';
    const descShort = (r.description || 'Açıklama belirtilmemiş').length > 55 ? (r.description || '').substring(0, 55) + '...' : (r.description || '');

    tr.innerHTML = `
      <td><strong style="color:var(--navy-light); font-family:monospace;">${ticketNo}</strong></td>
      <td style="white-space:nowrap; font-size:12px; color:var(--text-muted);">${dateStr}</td>
      <td>
        <div style="font-weight:700;">${userName}</div>
        <div style="font-size:11px; color:var(--text-muted);">${r.userPhone || ''}</div>
      </td>
      <td>
        <div style="font-weight:600;">${r.category || 'Genel Şikayet'}</div>
        <div style="font-size:11.5px; color:var(--text-muted);">📍 ${location}</div>
      </td>
      <td style="max-width:260px;">
        <span style="font-size:12.5px; line-height:1.4;">${descShort}</span>
        ${r.imageUrl ? ` <span style="cursor:pointer;" onclick="openLightbox('${r.imageUrl}')" title="Fotoğraf">📸</span>` : ''}
      </td>
      <td><span class="badge ${stInfo.cls}">${stInfo.label}</span></td>
      <td>
        <div style="display:flex; gap:6px;">
          <button class="btn btn-outline btn-sm" onclick="openReportDetailModal('${r.id}')">İncele & Yanıtla</button>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('reports', '${r.id}', initRealtimeReports)">Sil</button>
        </div>
      </td>
    `;
    container.appendChild(tr);
  });

  // 2. Kart Görünümü
  gridContainer.innerHTML = '';
  filtered.forEach(r => {
    const card = document.createElement("div");
    card.className = "item-card";
    const stInfo = REPORT_STATUS_MAP[r.status] || { label: r.status || 'Beklemede', cls: 'badge-warning' };
    const ticketNo = r.ticketNo || ('GBZ-' + r.id.substring(0, 6).toUpperCase());
    const userName = r.userName || (r.userId && window.usersMap[r.userId]?.fullName) || 'Gebze Sakini';

    card.innerHTML = `
      ${r.imageUrl ? `<img src="${r.imageUrl}" class="item-card-image" onclick="openLightbox('${r.imageUrl}')" alt="talep">` : ''}
      <div class="item-card-body">
        <div class="item-card-meta">
          <span style="font-family:monospace; font-weight:800; color:var(--navy-light);">${ticketNo}</span>
          <span class="badge ${stInfo.cls}" style="margin-left:auto;">${stInfo.label}</span>
        </div>
        <div class="item-card-title">${r.category || 'Vatandaş Talebi'}</div>
        <div class="item-card-desc">${r.description || ''}</div>
        <div style="font-size:11.5px; color:var(--text-muted); border-top:1px dashed var(--border); padding-top:8px;">
          👤 ${userName} • 📍 ${r.neighborhood || 'Gebze'}
        </div>
      </div>
      <div class="item-card-footer">
        <button class="btn btn-primary btn-sm" onclick="openReportDetailModal('${r.id}')">İncele / Yanıtla</button>
        <button class="btn btn-danger btn-sm" onclick="deleteDocItem('reports', '${r.id}', initRealtimeReports)">Sil</button>
      </div>
    `;
    gridContainer.appendChild(card);
  });
}
window.renderReportsView = renderReportsView;

window.switchReportsView = (viewMode) => {
  const table = document.getElementById("reportsTableView");
  const grid = document.getElementById("reportsGrid");
  const btnTable = document.getElementById("btnViewTable");
  const btnGrid = document.getElementById("btnViewGrid");
  if (viewMode === 'grid') {
    if (table) table.style.display = 'none';
    if (grid) grid.style.display = 'grid';
    if (btnGrid) { btnGrid.classList.add('btn-primary'); btnGrid.classList.remove('btn-outline'); }
    if (btnTable) { btnTable.classList.remove('btn-primary'); btnTable.classList.add('btn-outline'); }
  } else {
    if (table) table.style.display = 'block';
    if (grid) grid.style.display = 'none';
    if (btnTable) { btnTable.classList.add('btn-primary'); btnTable.classList.remove('btn-outline'); }
    if (btnGrid) { btnGrid.classList.remove('btn-primary'); btnGrid.classList.add('btn-outline'); }
  }
};

window.openReportDetailModal = (id) => {
  const r = (window.reportsCache || []).find(x => x.id === id);
  if (!r) return;
  window.activeReportId = id;

  const ticketNo = r.ticketNo || ('GBZ-' + r.id.substring(0, 6).toUpperCase());
  const userName = r.userName || (r.userId && window.usersMap[r.userId]?.fullName) || 'Gebze Sakini';

  document.getElementById("modalReportTicket").innerText = ticketNo;
  document.getElementById("modalReportCitizen").innerText = `${userName} (${r.userPhone || 'Tel yok'})`;
  document.getElementById("modalReportCategory").innerText = r.category || 'Genel Şikayet';

  const loc = [r.neighborhood, r.address].filter(Boolean).join(' • ') || 'Gebze';
  document.getElementById("modalReportLocation").innerText = loc;

  const mapBtn = document.getElementById("modalReportMapBtn");
  if (r.lat && r.lng) {
    mapBtn.href = `https://www.google.com/maps?q=${r.lat},${r.lng}`;
    mapBtn.style.display = 'inline-flex';
  } else {
    mapBtn.style.display = 'none';
  }

  document.getElementById("modalReportDesc").innerText = r.description || 'Açıklama belirtilmemiş.';

  const imgBox = document.getElementById("modalReportImageBox");
  if (r.imageUrl) {
    imgBox.innerHTML = `
      <div style="font-size:11px; text-transform:uppercase; color:var(--text-muted); font-weight:800; margin-bottom:4px;">Eklenen Fotoğraf</div>
      <img src="${r.imageUrl}" style="max-height:220px; border-radius:10px; cursor:pointer; border:1px solid var(--border);" onclick="openLightbox('${r.imageUrl}')" alt="talep fotoğrafı">
    `;
    imgBox.style.display = 'block';
  } else {
    imgBox.style.display = 'none';
  }

  document.getElementById("modalReportStatusSelect").value = r.status || 'Beklemede';
  document.getElementById("modalReportNoteInput").value = r.response || r.adminNote || '';

  const histBox = document.getElementById("modalReportHistory");
  if (r.history && Array.isArray(r.history) && r.history.length > 0) {
    histBox.innerHTML = r.history.map(h => `
      <div style="font-size:12px; margin-bottom:4px; padding:6px 10px; background:#F1F5F9; border-radius:6px;">
        <strong>${h.status || 'Güncelleme'}</strong> • <span style="color:var(--text-muted);">${h.date || ''}</span>
        ${h.note ? `<div style="color:var(--text-dark); margin-top:2px;">${h.note}</div>` : ''}
      </div>
    `).join('');
  } else {
    histBox.innerHTML = '<div style="font-size:12px; color:var(--text-muted);">Henüz geçmiş işlem kaydı yok.</div>';
  }

  document.getElementById("reportDetailModal").style.display = 'flex';
};

window.closeReportDetailModal = () => {
  document.getElementById("reportDetailModal").style.display = 'none';
  window.activeReportId = null;
};

window.saveReportAction = async () => {
  if (!window.activeReportId) return;
  const status = document.getElementById("modalReportStatusSelect").value;
  const note = document.getElementById("modalReportNoteInput").value.trim();
  const btn = document.getElementById("btnSaveReportAction");
  btn.disabled = true;

  try {
    const historyItem = {
      status,
      note,
      date: new Date().toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
      who: auth.currentUser?.email || 'Yönetici'
    };

    const docRef = doc(db, "reports", window.activeReportId);
    await updateDoc(docRef, {
      status,
      response: note,
      adminNote: note,
      updatedAt: serverTimestamp(),
      history: arrayUnion(historyItem)
    });

    showToast("Talep durumu ve resmi birim yanıtı kaydedildi!");
    closeReportDetailModal();
  } catch (err) {
    alert("Kayıt sırasında hata oluştu: " + err.message);
  } finally {
    btn.disabled = false;
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 5. VATANDAŞ ÖNERİLERİ (SÖZ SENDE) & MODERASYON
// ─────────────────────────────────────────────────────────────────────────────
async function loadSuggestions() {
  const container = document.getElementById("suggestionsGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Öneriler yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "suggestions"));
    if (snap.empty) {
      container.innerHTML = '<div class="empty-state">Henüz iletilen vatandaş önerisi yok.</div>';
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const isApproved = d.approved === true;
      const statusText = d.status || (isApproved ? 'Onaylandı' : 'Beklemede');
      const badgeCls = statusText === 'Onaylandı' ? 'badge-success' : (statusText === 'Reddedildi' ? 'badge-danger' : 'badge-warning');

      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">
            <span>💡 ${d.category || 'Genel'}</span>
            <span>📍 ${d.neighborhood || 'Gebze'}</span>
            <span class="badge ${badgeCls}" style="margin-left:auto;">${statusText}</span>
          </div>
          <div class="item-card-title">${d.title}</div>
          <div class="item-card-desc">${d.description || ''}</div>
          ${d.officialResponse ? `
            <div style="background:var(--success-soft); padding:8px 12px; border-radius:8px; font-size:12px; color:#14532D; margin-bottom:10px;">
              <strong>🏛️ Belediye Resmi Yanıtı:</strong> ${d.officialResponse}
            </div>
          ` : ''}
          <div style="font-size:11.5px; color:var(--text-muted); font-weight:600;">
            İleten: ${d.author || 'Vatandaş'} • ❤️ ${d.likes || 0} Destek Oyu
          </div>
        </div>
        <div class="item-card-footer">
          <div style="display:flex; gap:6px; flex-wrap:wrap;">
            ${!isApproved ? `
              <button class="btn btn-success btn-sm" onclick="approveSuggestion('${docSnap.id}')">✅ Onayla & Yayına Al</button>
            ` : `
              <button class="btn btn-outline btn-sm" onclick="unapproveSuggestion('${docSnap.id}')">Yayından Kaldır</button>
            `}
            <button class="btn btn-primary btn-sm" onclick="openSuggestionReplyModal('${docSnap.id}')">💬 Resmi Yanıt Ekle</button>
          </div>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('suggestions', '${docSnap.id}', loadSuggestions)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadSuggestions = loadSuggestions;

window.approveSuggestion = async (id) => {
  try {
    await updateDoc(doc(db, "suggestions", id), {
      approved: true,
      status: 'Onaylandı',
      reviewedAt: serverTimestamp()
    });
    showToast("Öneri onaylandı ve uygulamada yayına alındı!");
    loadSuggestions();
    loadDashboard();
  } catch (e) { alert("Hata: " + e.message); }
};

window.unapproveSuggestion = async (id) => {
  try {
    await updateDoc(doc(db, "suggestions", id), {
      approved: false,
      status: 'Beklemede'
    });
    showToast("Öneri yayından kaldırıldı.");
    loadSuggestions();
    loadDashboard();
  } catch (e) { alert("Hata: " + e.message); }
};

window.openSuggestionReplyModal = (id) => {
  window.activeSuggestionId = id;
  const modal = document.getElementById("suggestionReplyModal");
  if (modal) modal.style.display = 'flex';
};

window.closeSuggestionReplyModal = () => {
  const modal = document.getElementById("suggestionReplyModal");
  if (modal) modal.style.display = 'none';
  window.activeSuggestionId = null;
};

window.saveSuggestionReply = async () => {
  if (!window.activeSuggestionId) return;
  const status = document.getElementById("modalSuggStatusSelect").value;
  const resp = document.getElementById("modalSuggResponseInput").value.trim();
  if (!resp) { alert("Lütfen vatandaşa iletilecek resmi açıklamayı yazınız."); return; }

  try {
    await updateDoc(doc(db, "suggestions", window.activeSuggestionId), {
      status,
      approved: status === 'Onaylandı',
      officialResponse: resp,
      respondedAt: serverTimestamp()
    });
    showToast("Resmi birim yanıtı vatandaşa başarıyla iletildi!");
    closeSuggestionReplyModal();
    loadSuggestions();
  } catch (e) { alert("Hata: " + e.message); }
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. SÖZ SENDE (ANKETLER)
// ─────────────────────────────────────────────────────────────────────────────
async function loadPolls() {
  const container = document.getElementById("pollsGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Anketler yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "polls"));
    if (snap.empty) {
      container.innerHTML = '<div class="empty-state">Henüz aktif anket bulunmuyor.</div>';
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const optionsHtml = (d.options || []).map((opt, i) => {
        const votes = (d.votes && d.votes[i]) ? d.votes[i] : 0;
        return `<li style="font-size:12.5px; margin-bottom:6px; color:var(--text-dark); display:flex; justify-content:space-between; align-items:center;">
          <span>${opt}</span> <span class="badge badge-primary">${votes} Oy</span>
        </li>`;
      }).join('');

      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">🗳️ ${d.neighborhood || 'Tüm Gebze'} • Bitiş: ${d.endDate || 'Süresiz'}</div>
          <div class="item-card-title">${d.question}</div>
          <div class="item-card-desc">${d.description || ''}</div>
          <ul style="list-style:none; padding:8px 0; margin:6px 0; border-top:1px dashed var(--border); border-bottom:1px dashed var(--border);">${optionsHtml}</ul>
        </div>
        <div class="item-card-footer">
          <button class="btn btn-sm ${d.isActive ? 'btn-success' : 'btn-outline'}" onclick="togglePollStatus('${docSnap.id}', ${!d.isActive})">
            ${d.isActive ? '🟢 Oylamaya Açık' : '🔴 Oylamaya Kapalı'}
          </button>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('polls', '${docSnap.id}', loadPolls)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadPolls = loadPolls;

window.togglePollStatus = async (id, currentStatus) => {
  try {
    await updateDoc(doc(db, "polls", id), { isActive: currentStatus });
    showToast("Anket oylama durumu güncellendi.");
    loadPolls();
  } catch (e) { alert("Hata: " + e.message); }
};

// ─────────────────────────────────────────────────────────────────────────────
// 7. GEZİ & KENT REHBERİ PORTALI (MEKANLAR, DOĞA ROTALARI, LEZZETLER, KURUMLAR)
// ─────────────────────────────────────────────────────────────────────────────
window.switchGuideTab = (subTab) => {
  document.querySelectorAll('.guide-sub-view').forEach(v => v.style.display = 'none');
  const target = document.getElementById('guide-sub-' + subTab);
  if (target) target.style.display = 'block';

  document.querySelectorAll('#view-guide .sub-tab-btn').forEach(b => b.classList.remove('active'));
  const btn = document.getElementById('sub-btn-guide-' + subTab);
  if (btn) btn.classList.add('active');

  if (subTab === 'places') loadGuidePlaces();
  if (subTab === 'picnic') loadGuidePicnic();
  if (subTab === 'foods') loadGuideFoods();
  if (subTab === 'institutions') loadGuideInstitutions();
};

async function loadGuidePlaces() {
  const container = document.getElementById("guidePlacesGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Tarihi mekanlar yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "guide_places"));
    if (snap.empty) {
      container.innerHTML = `
        <div class="empty-state">
          <p style="margin-bottom:8px;">Kayıtlı mekan bulunamadı.</p>
          <button class="btn btn-orange btn-sm" onclick="seedGuidePlaces()">🏛️ Resmi Gebze Tarihi Mekanlarını Eşitle</button>
        </div>
      `;
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        ${d.image ? `<img src="${d.image}" class="item-card-image" onclick="openLightbox('${d.image}')" alt="mekan">` : ''}
        <div class="item-card-body">
          <div class="item-card-meta">🏛️ ${d.category || 'Tarihi Mekan'}</div>
          <div class="item-card-title">${d.name || d.title}</div>
          <div class="item-card-desc">${d.summary || d.description || ''}</div>
        </div>
        <div class="item-card-footer">
          ${d.detailUrl ? `<a href="${d.detailUrl}" target="_blank" class="badge badge-info" style="text-decoration:none;">🔗 Detay Sayfası</a>` : '<span class="badge badge-success">Rehberde Aktif</span>'}
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('guide_places', '${docSnap.id}', loadGuidePlaces)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadGuidePlaces = loadGuidePlaces;

// ═════════════════ YÖRESEL LEZZETLER (guide_foods) ═════════════════
window.foodsCache = [];
window.foodEditId = null;

async function loadFoods() {
  const grid = document.getElementById('foodsGrid') || document.getElementById('guideFoodsGrid');
  if (!grid) return;
  grid.innerHTML = '<div class="empty-state">Yöresel lezzetler yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, 'guide_foods'));
    window.foodsCache = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    const countEl = document.getElementById('foodsCount');
    if (countEl) countEl.innerText = window.foodsCache.length;
    renderFoods();
  } catch (e) {
    grid.innerHTML = `<div class="empty-state">Kayıtlar okunamadı: ${e.message}</div>`;
  }
}
window.loadFoods = loadFoods;
window.loadGuideFoods = loadFoods;

function renderFoods() {
  const grid = document.getElementById('foodsGrid') || document.getElementById('guideFoodsGrid');
  if (!grid) return;
  const q = (document.getElementById('foodsSearchInput')?.value || '').trim().toLowerCase();
  const list = (window.foodsCache || []).filter(f => {
    if (!q) return true;
    return (f.name || '').toLowerCase().includes(q) ||
      (f.summary || '').toLowerCase().includes(q) ||
      (f.whereToEat || '').toLowerCase().includes(q) ||
      (f.origin || '').toLowerCase().includes(q);
  }).sort((a, b) => (Number(a.order) || 999) - (Number(b.order) || 999));

  const countEl = document.getElementById('foodsCount');
  if (countEl) countEl.innerText = list.length;

  if (!window.foodsCache || !window.foodsCache.length) {
    grid.innerHTML = `
      <div class="empty-state" style="grid-column: 1 / -1; padding: 36px 20px; text-align: center; background: white; border-radius: var(--radius); border: 2px dashed var(--border);">
        <div style="font-size: 42px; margin-bottom: 12px;">🍲</div>
        <div style="font-size: 16px; font-weight: 800; color: var(--navy); margin-bottom: 6px;">Firebase'de Henüz Kayıtlı Yöresel Lezzet Yok</div>
        <div style="font-size: 13px; color: var(--text-muted); max-width: 520px; margin: 0 auto 18px; line-height: 1.5;">
          Gebze Çöreği, Mancarlı Pide, Höşmerim Tatlısı, Saray Pişmaniyesi, Doğal Manda Yoğurdu ve Eskihisar Deniz Mahsulleri dahil 6 resmi kayıt hazır bekliyor.
        </div>
        <button type="button" class="btn btn-primary" onclick="seedFoods()">
          ⚡ 6 Resmi Gebze Lezzetini Firebase'e Yükle
        </button>
      </div>`;
    return;
  }

  if (!list.length) {
    grid.innerHTML = '<div class="empty-state">Arama kriterlerine uygun yöresel lezzet bulunamadı.</div>';
    return;
  }

  grid.innerHTML = list.map(f => {
    const ings = Array.isArray(f.ingredients) ? f.ingredients : (f.ingredients ? String(f.ingredients).split(',') : []);
    const ingPreview = ings.slice(0, 4).join(', ') + (ings.length > 4 ? ` (+${ings.length - 4})` : '');
    return `
    <div class="item-card">
      ${f.image ? `<img src="${f.image}" class="item-card-image" onclick="openLightbox('${f.image}')" alt="" onerror="this.style.display='none'">` : ''}
      <div class="item-card-body">
        <div class="item-card-meta">
          <span class="badge badge-warning" style="background:#FFF7ED; color:#EA580C; border:1px solid #FFEDD5;">🍲 Yöresel Lezzet</span>
          <span style="margin-left:auto; font-weight:700; color:var(--text-muted); font-size:11.5px;">Sıra: #${f.order || 999}</span>
        </div>
        <div class="item-card-title">${f.name || ''}</div>
        <div class="item-card-desc">${f.summary || ''}</div>
        ${f.origin ? `<div style="font-size:12px; color:var(--text-muted); margin-top:8px; line-height:1.4;"><strong>🏺 Kökeni:</strong> ${f.origin.length > 100 ? f.origin.substring(0, 100) + '...' : f.origin}</div>` : ''}
        ${f.whereToEat ? `<div style="font-size:12px; color:var(--navy-light); font-weight:700; margin-top:6px;">📍 ${f.whereToEat}</div>` : ''}
        ${ingPreview ? `<div style="font-size:11.5px; color:var(--text-muted); margin-top:4px; font-style:italic;">🧂 ${ingPreview}</div>` : ''}
      </div>
      <div class="item-card-footer">
        <button class="btn btn-outline btn-sm" onclick="editFood('${f.id}')">Düzenle</button>
        <button class="btn btn-danger btn-sm" onclick="deleteDocItem('guide_foods', '${f.id}', loadFoods)">Sil</button>
      </div>
    </div>`;
  }).join('');
}
window.renderFoods = renderFoods;

window.editFood = (id) => {
  const f = window.foodsCache.find(x => x.id === id);
  if (!f) return;
  window.foodEditId = id;
  if (document.getElementById('foodName')) document.getElementById('foodName').value = f.name || '';
  if (document.getElementById('foodNameEn')) document.getElementById('foodNameEn').value = f.name_en || '';
  if (document.getElementById('foodNameAr')) document.getElementById('foodNameAr').value = f.name_ar || '';
  if (document.getElementById('foodSummary')) document.getElementById('foodSummary').value = f.summary || '';
  if (document.getElementById('foodOrigin')) document.getElementById('foodOrigin').value = f.origin || '';
  if (document.getElementById('foodIngredients')) document.getElementById('foodIngredients').value = Array.isArray(f.ingredients) ? f.ingredients.join(', ') : (f.ingredients || '');
  if (document.getElementById('foodRecipe')) document.getElementById('foodRecipe').value = Array.isArray(f.recipe) ? f.recipe.join('\n') : (f.recipe || '');
  if (document.getElementById('foodWhereToEat')) document.getElementById('foodWhereToEat').value = f.whereToEat || '';
  if (document.getElementById('foodImage')) document.getElementById('foodImage').value = f.image || '';
  if (document.getElementById('foodOrder')) document.getElementById('foodOrder').value = f.order ?? 1;

  if (document.getElementById('foodFormTitle')) document.getElementById('foodFormTitle').innerText = 'Lezzeti düzenle';
  if (document.getElementById('foodSubmitBtn')) document.getElementById('foodSubmitBtn').innerText = 'Değişiklikleri kaydet';
  if (document.getElementById('foodCancelBtn')) document.getElementById('foodCancelBtn').style.display = 'inline-flex';
  document.getElementById('formFood')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
};

window.cancelFoodEdit = () => {
  window.foodEditId = null;
  document.getElementById('formFood')?.reset();
  if (document.getElementById('foodFormTitle')) document.getElementById('foodFormTitle').innerText = 'Yeni yöresel lezzet ekle';
  if (document.getElementById('foodSubmitBtn')) document.getElementById('foodSubmitBtn').innerText = 'Lezzeti ekle';
  if (document.getElementById('foodCancelBtn')) document.getElementById('foodCancelBtn').style.display = 'none';
};

// ═════════════════ DOĞA & PİKNİK ALANLARI (guide_picnic) ═════════════════
window.picnicCache = [];
window.picnicEditId = null;
window.picnicFilterType = 'all';

async function loadPicnic() {
  const grid = document.getElementById('picnicGrid') || document.getElementById('guidePicnicGrid');
  if (!grid) return;
  grid.innerHTML = '<div class="empty-state">Doğa ve piknik alanları yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, 'guide_picnic'));
    window.picnicCache = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    const countEl = document.getElementById('picnicCount');
    if (countEl) countEl.innerText = window.picnicCache.length;
    renderPicnic();
  } catch (e) {
    grid.innerHTML = `<div class="empty-state">Kayıtlar okunamadı: ${e.message}</div>`;
  }
}
window.loadPicnic = loadPicnic;
window.loadGuidePicnic = loadPicnic;

function renderPicnic() {
  const grid = document.getElementById('picnicGrid') || document.getElementById('guidePicnicGrid');
  if (!grid) return;
  const q = (document.getElementById('picnicSearchInput')?.value || '').trim().toLowerCase();
  const filterType = window.picnicFilterType || 'all';

  const typeLabels = {
    all: 'Tümü',
    piknik: '🧺 Piknik Alanı',
    mesire: '🏞️ Mesire Alanı',
    doga: '🌲 Doğa Alanı',
    park: '🌳 Park'
  };

  const chipContainer = document.getElementById('picnicTypeChips');
  if (chipContainer) {
    const allCounts = { all: (window.picnicCache || []).length };
    (window.picnicCache || []).forEach(p => {
      const t = p.type || 'piknik';
      allCounts[t] = (allCounts[t] || 0) + 1;
    });
    chipContainer.innerHTML = Object.entries(typeLabels).map(([k, label]) => {
      const isAct = filterType === k;
      return `<button type="button" class="chip ${isAct ? 'active' : ''}" onclick="window.picnicFilterType='${k}'; renderPicnic();">${label} <span>${allCounts[k] || 0}</span></button>`;
    }).join('');
  }

  const list = (window.picnicCache || []).filter(p => {
    if (filterType !== 'all' && (p.type || 'piknik') !== filterType) return false;
    if (!q) return true;
    return (p.name || '').toLowerCase().includes(q) ||
      (p.summary || '').toLowerCase().includes(q) ||
      (p.village || '').toLowerCase().includes(q) ||
      (p.address || '').toLowerCase().includes(q);
  }).sort((a, b) => (Number(a.order) || 999) - (Number(b.order) || 999));

  const countEl = document.getElementById('picnicCount');
  if (countEl) countEl.innerText = list.length;

  if (!window.picnicCache || !window.picnicCache.length) {
    grid.innerHTML = `
      <div class="empty-state" style="grid-column: 1 / -1; padding: 36px 20px; text-align: center; background: white; border-radius: var(--radius); border: 2px dashed var(--border);">
        <div style="font-size: 42px; margin-bottom: 12px;">🌲</div>
        <div style="font-size: 16px; font-weight: 800; color: var(--navy); margin-bottom: 6px;">Firebase'de Henüz Kayıtlı Doğa & Piknik Alanı Yok</div>
        <div style="font-size: 13px; color: var(--text-muted); max-width: 520px; margin: 0 auto 18px; line-height: 1.5;">
          Beylikdağı, Denizli Göleti, Ballıkayalar, Eskihisar Korusu, Pelitli Bayraktepe ve Tatlıkuyu Vadisi dahil 15 resmi alan hazır bekliyor.
        </div>
        <button type="button" class="btn btn-primary" onclick="seedPicnic()">
          ⚡ 15 Resmi Doğa & Piknik Alanını Firebase'e Yükle
        </button>
      </div>`;
    return;
  }

  if (!list.length) {
    grid.innerHTML = '<div class="empty-state">Seçilen filtre ve arama kriterine uygun alan bulunamadı.</div>';
    return;
  }

  const typeBadgeColors = {
    piknik: 'badge-warning',
    mesire: 'badge-purple',
    doga: 'badge-success',
    park: 'badge-primary'
  };

  grid.innerHTML = list.map(p => {
    const feats = Array.isArray(p.features) ? p.features : (p.features ? String(p.features).split(',') : []);
    const featPills = feats.slice(0, 3).map(f => `<span style="display:inline-block; font-size:11px; background:#F1F5F9; color:#334155; padding:2px 7px; border-radius:6px; margin:2px 2px 0 0;">${f}</span>`).join('');
    const badgeCls = typeBadgeColors[p.type] || 'badge-primary';
    return `
    <div class="item-card">
      ${p.image ? `<img src="${p.image}" class="item-card-image" onclick="openLightbox('${p.image}')" alt="" onerror="this.style.display='none'">` : ''}
      <div class="item-card-body">
        <div class="item-card-meta">
          <span class="badge ${badgeCls}">${typeLabels[p.type] || p.type || 'Piknik'}</span>
          ${p.village ? `<span style="margin-left:auto; font-weight:600; color:var(--navy-light);">📍 ${p.village}</span>` : ''}
        </div>
        <div class="item-card-title">${p.name || ''}</div>
        <div class="item-card-desc">${p.summary || ''}</div>
        ${p.address ? `<div style="font-size:12px; color:var(--text-muted); margin-top:6px;">📍 ${p.address}</div>` : ''}
        ${featPills ? `<div style="margin-top:8px;">${featPills}</div>` : ''}
      </div>
      <div class="item-card-footer">
        <span style="font-size:11.5px; font-weight:700; color:var(--text-muted);">Sıra: #${p.order || 999}</span>
        <div style="margin-left:auto; display:flex; gap:6px;">
          <button class="btn btn-outline btn-sm" onclick="editPicnic('${p.id}')">Düzenle</button>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('guide_picnic', '${p.id}', loadPicnic)">Sil</button>
        </div>
      </div>
    </div>`;
  }).join('');
}
window.renderPicnic = renderPicnic;

window.editPicnic = (id) => {
  const p = window.picnicCache.find(x => x.id === id);
  if (!p) return;
  window.picnicEditId = id;
  if (document.getElementById('picnicName')) document.getElementById('picnicName').value = p.name || '';
  if (document.getElementById('picnicNameEn')) document.getElementById('picnicNameEn').value = p.name_en || '';
  if (document.getElementById('picnicNameAr')) document.getElementById('picnicNameAr').value = p.name_ar || '';
  if (document.getElementById('picnicType')) document.getElementById('picnicType').value = p.type || 'piknik';
  if (document.getElementById('picnicVillage')) document.getElementById('picnicVillage').value = p.village || '';
  if (document.getElementById('picnicAddress')) document.getElementById('picnicAddress').value = p.address || '';
  if (document.getElementById('picnicSummary')) document.getElementById('picnicSummary').value = p.summary || '';
  if (document.getElementById('picnicFeatures')) document.getElementById('picnicFeatures').value = Array.isArray(p.features) ? p.features.join(', ') : (p.features || '');
  if (document.getElementById('picnicLat')) document.getElementById('picnicLat').value = p.lat ?? '';
  if (document.getElementById('picnicLng')) document.getElementById('picnicLng').value = p.lng ?? '';
  if (document.getElementById('picnicMapQuery')) document.getElementById('picnicMapQuery').value = p.mapQuery || '';
  if (document.getElementById('picnicImage')) document.getElementById('picnicImage').value = p.image || '';
  if (document.getElementById('picnicOrder')) document.getElementById('picnicOrder').value = p.order ?? 1;

  if (document.getElementById('picnicFormTitle')) document.getElementById('picnicFormTitle').innerText = 'Alanı düzenle';
  if (document.getElementById('picnicSubmitBtn')) document.getElementById('picnicSubmitBtn').innerText = 'Değişiklikleri kaydet';
  if (document.getElementById('picnicCancelBtn')) document.getElementById('picnicCancelBtn').style.display = 'inline-flex';
  document.getElementById('formPicnic')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
};

window.cancelPicnicEdit = () => {
  window.picnicEditId = null;
  document.getElementById('formPicnic')?.reset();
  if (document.getElementById('picnicFormTitle')) document.getElementById('picnicFormTitle').innerText = 'Yeni doğa / piknik alanı ekle';
  if (document.getElementById('picnicSubmitBtn')) document.getElementById('picnicSubmitBtn').innerText = 'Alanı ekle';
  if (document.getElementById('picnicCancelBtn')) document.getElementById('picnicCancelBtn').style.display = 'none';
};

async function loadGuideInstitutions() {
  const container = document.getElementById("guideInstitutionsGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Kamu kurumları yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "guide_institutions"));
    if (snap.empty) {
      container.innerHTML = `
        <div class="empty-state">
          <p style="margin-bottom:8px;">Kayıtlı kamu kurumu bulunamadı.</p>
          <button class="btn btn-orange btn-sm" onclick="seedGuideInstitutions()">🏢 Resmi Kurumları Eşitle</button>
        </div>
      `;
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">🏢 ${d.category || 'Kamu Kurumu'}</div>
          <div class="item-card-title">${d.name || d.title}</div>
          <div class="item-card-desc">📍 ${d.address || 'Gebze'}<br>📞 ${d.phone || '0262 642 04 30'}</div>
        </div>
        <div class="item-card-footer">
          ${d.url ? `<a href="${d.url}" target="_blank" class="badge badge-info" style="text-decoration:none;">🔗 Web Sitesi</a>` : '<span class="badge badge-success">Hizmet Noktası</span>'}
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('guide_institutions', '${docSnap.id}', loadGuideInstitutions)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadGuideInstitutions = loadGuideInstitutions;

// ─────────────────────────────────────────────────────────────────────────────
// 8. GÜNDÜZ BAKIMEVLERİ & KREŞLER
// ─────────────────────────────────────────────────────────────────────────────
async function loadNurseries() {
  const container = document.getElementById("nurseriesGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Kreşler yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "nurseries"));
    if (snap.empty) {
      container.innerHTML = `
        <div class="empty-state">
          <p style="margin-bottom:8px;">Kayıtlı belediye kreşi bulunamadı.</p>
          <button class="btn btn-orange btn-sm" onclick="seedNurseries()">👶 Resmi Kreşleri Eşitle</button>
        </div>
      `;
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        ${d.imageUrl ? `<img src="${d.imageUrl}" class="item-card-image" onclick="openLightbox('${d.imageUrl}')" alt="kreş">` : ''}
        <div class="item-card-body">
          <div class="item-card-meta">
            <span>👶 ${d.neighborhood || 'Gebze'}</span>
            <span class="badge badge-purple" style="margin-left:auto;">${d.capacity ? d.capacity + ' Çocuk Kapasitesi' : 'Aktif'}</span>
          </div>
          <div class="item-card-title">${d.name}</div>
          <div class="item-card-desc">
            📍 ${d.address || 'Gebze'}<br>
            📞 ${d.phone || '0262 642 04 30'}<br>
            ${d.ageGroup ? `🎓 Yaş Grubu: ${d.ageGroup}` : ''}
          </div>
          ${d.description ? `<div style="font-size:12px; color:var(--text-muted);">${d.description}</div>` : ''}
        </div>
        <div class="item-card-footer">
          <span class="badge badge-success">Kayıt Alıyor</span>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('nurseries', '${docSnap.id}', loadNurseries)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadNurseries = loadNurseries;

// ─────────────────────────────────────────────────────────────────────────────
// 9. HABERLER & DUYURULAR
// ─────────────────────────────────────────────────────────────────────────────
async function loadNews() {
  const container = document.getElementById("newsGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Haberler yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "municipal_news"));
    if (snap.empty) {
      container.innerHTML = '<div class="empty-state">Kayıtlı belediye haberi bulunamadı.</div>';
      return;
    }
    const list = [];
    snap.forEach(docSnap => {
      list.push({ id: docSnap.id, ...docSnap.data() });
    });

    // En yeni haberler en üstte (newsId varsa büyükten küçüğe, yoksa createdAt'e göre)
    list.sort((a, b) => {
      if (a.newsId && b.newsId) return b.newsId - a.newsId;
      const ta = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
      const tb = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
      return tb - ta;
    });

    container.innerHTML = '';
    list.forEach(d => {
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <img src="${d.image || 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?auto=format&fit=crop&w=600&q=80'}" class="item-card-image" onclick="openLightbox('${d.image}')" alt="haber">
        <div class="item-card-body">
          <div class="item-card-meta">
            <span>📅 ${d.publishedAtText || 'Bugün'}</span>
            ${d.category ? `<span class="badge badge-primary" style="margin-left:auto;">${d.category}</span>` : ''}
          </div>
          <div class="item-card-title">${d.title}</div>
          <div class="item-card-desc">${d.summary || d.description || ''}</div>
        </div>
        <div class="item-card-footer">
          ${d.url ? `<a href="${d.url}" target="_blank" class="badge badge-info" style="text-decoration:none;">🔗 Haberi Oku</a>` : '<span class="badge badge-success">Yayında</span>'}
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('municipal_news', '${d.id}', loadNews)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadNews = loadNews;

async function seedOfficialNews() {
  const btn = document.getElementById("btnSyncOfficialNews");
  if (btn) btn.disabled = true;
  try {
    const newsData = window.GEBZE_OFFICIAL_NEWS;
    if (!Array.isArray(newsData) || newsData.length === 0) {
      throw new Error("Resmi haber veri paketi (gebze_haber_cache.js) bulunamadı.");
    }

    showToast(`${newsData.length} resmi belediye haberi senkronize ediliyor...`);

    const trMonthsMap = {
      "ocak": 0, "şubat": 1, "mart": 2, "nisan": 3, "mayıs": 4, "haziran": 5,
      "temmuz": 6, "ağustos": 7, "eylül": 8, "ekim": 9, "kasım": 10, "aralık": 11
    };
    const parseTrDate = (str) => {
      if (!str) return null;
      const m = str.match(/(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+(\d{4})/i);
      if (!m) return null;
      const day = parseInt(m[1], 10);
      const month = trMonthsMap[m[2].toLowerCase()];
      const year = parseInt(m[3], 10);
      if (month === undefined) return null;
      return new Date(Date.UTC(year, month, day, 12, 0, 0));
    };

    let count = 0;
    for (const item of newsData) {
      const docId = item.id || ('news_' + (item.newsId || (count + 1)));
      const dateObj = parseTrDate(item.publishedAtText) || new Date(2026, 9, 26);
      await setDoc(doc(db, "municipal_news", docId), {
        id: docId,
        title: item.title,
        url: item.url || '',
        image: item.image || '',
        publishedAtText: item.publishedAtText || '26 Ekim 2026',
        publishedAt: Timestamp.fromDate(dateObj),
        newsId: item.newsId || (7400 + count),
        pageIndex: item.pageIndex || 1,
        itemIndex: item.itemIndex || count,
        summary: item.summary || item.title,
        title_en: item.title_en || item.title,
        title_ar: item.title_ar || item.title,
        summary_en: item.summary_en || (item.summary || item.title),
        summary_ar: item.summary_ar || (item.summary || item.title),
        category: "Belediye",
        source: "Gebze Belediyesi",
        syncedAt: serverTimestamp()
      }, { merge: true });
      count++;
    }

    showToast(`✅ ${count} adet resmi belediye haberi başarıyla Firestore'a aktarıldı!`);
    loadNews();
    loadDashboard();
  } catch (err) {
    alert("Haber senkronizasyonu hatası: " + err.message);
  } finally {
    if (btn) btn.disabled = false;
  }
}
window.seedOfficialNews = seedOfficialNews;

// ─────────────────────────────────────────────────────────────────────────────
// 10. ETKİNLİKLER & KÜLTÜR-SANAT
// ─────────────────────────────────────────────────────────────────────────────
async function loadEvents() {
  const container = document.getElementById("eventsGrid");
  if (container) container.innerHTML = '<div class="empty-state">Etkinlikler yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "events"));
    const list = [];
    snap.forEach(docSnap => {
      list.push({ id: docSnap.id, ...docSnap.data() });
    });

    list.sort((a, b) => {
      const da = a.date || '';
      const db = b.date || '';
      return db.localeCompare(da);
    });

    window.eventsListCache = list;
    const b = document.getElementById('eventsCountBadge');
    if (b) b.innerText = `${list.length} Etkinlik`;
    setKpi('kpiEvents', list.length);

    renderEventsList();
  } catch (e) {
    console.error("loadEvents hatası:", e);
    if (container) container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadEvents = loadEvents;

function renderEventsList() {
  const container = document.getElementById("eventsGrid");
  if (!container) return;

  const q = (document.getElementById("eventsSearchInput")?.value || '').trim().toLowerCase();
  const catFilter = document.getElementById("eventsFilterCategory")?.value || '';
  const monthFilter = document.getElementById("eventsFilterMonth")?.value || '';

  const filtered = (window.eventsListCache || []).filter(d => {
    if (catFilter && d.category !== catFilter) return false;
    if (monthFilter && !(d.date || '').startsWith(monthFilter)) return false;
    if (q) {
      const title = (d.title || d.name || '').toLowerCase();
      const loc = (d.location || d.subtitle || '').toLowerCase();
      const desc = (d.description || '').toLowerCase();
      if (!title.includes(q) && !loc.includes(q) && !desc.includes(q)) return false;
    }
    return true;
  });

  if (filtered.length === 0) {
    container.innerHTML = '<div class="empty-state">Kriterlere uygun etkinlik bulunamadı.</div>';
    return;
  }

  container.innerHTML = '';
  filtered.forEach(d => {
    const imgUrl = d.image || d.imageUrl || '';
    const card = document.createElement("div");
    card.className = "item-card";
    card.innerHTML = `
      ${imgUrl ? `<img src="${imgUrl}" class="item-card-image" onerror="this.style.display='none'" onclick="openLightbox('${imgUrl}')" alt="etkinlik">` : ''}
      <div class="item-card-body">
        <div class="item-card-meta">
          <span>🎭 ${d.category || 'Kültür & Sanat'}</span>
          <span style="margin-left:auto; font-weight:700;">📅 ${d.formattedDate || d.date || 'Yakında'} ${d.time ? '• ' + d.time : ''}</span>
        </div>
        <div class="item-card-title">${d.title || d.name || ''}</div>
        <div class="item-card-desc">📍 ${d.subtitle || d.location || 'Gebze'}</div>
        ${d.description && d.description !== d.category ? `<div style="font-size:12px; color:var(--text-muted); margin-top:4px;">${d.description}</div>` : ''}
      </div>
      <div class="item-card-footer">
        ${d.url ? `<a href="${d.url}" target="_blank" class="badge badge-info" style="text-decoration:none;">🔗 Resmi Sayfa</a>` : '<span class="badge badge-success">Aktif</span>'}
        <button class="btn btn-danger btn-sm" onclick="deleteDocItem('events', '${d.id}', loadEvents)">Sil</button>
      </div>
    `;
    container.appendChild(card);
  });
}
window.renderEventsList = renderEventsList;

window.syncEventsFromWeb = async () => {
  const btn = document.getElementById("btnSyncEventsWeb");
  const monthSelect = document.getElementById("syncEventMonth");
  const selectedMonth = monthSelect ? monthSelect.value : "2026-11";

  if (btn) {
    btn.disabled = true;
    btn.innerText = "⏳ Etkinlikler Çekiliyor...";
  }
  try {
    const targetUrl = "https://www.gebze.bel.tr/json/etkinlik.json";
    let data = null;

    try {
      const res = await fetch(targetUrl);
      if (res.ok) data = await res.json();
    } catch (_) { }

    if (!data || !Array.isArray(data)) {
      try {
        const res = await fetch("https://corsproxy.io/?url=" + encodeURIComponent(targetUrl));
        if (res.ok) data = await res.json();
      } catch (_) { }
    }

    if (!data || !Array.isArray(data)) {
      try {
        const res = await fetch("https://api.allorigins.win/raw?url=" + encodeURIComponent(targetUrl));
        if (res.ok) data = await res.json();
      } catch (_) { }
    }

    const localEvents = window.GEBZE_OFFICIAL_EVENTS || [];
    if (!data || !Array.isArray(data)) {
      data = localEvents;
    } else if (localEvents.length > 0) {
      const existingIds = new Set(data.map(x => String(x.id)));
      for (const ev of localEvents) {
        if (!existingIds.has(String(ev.id))) {
          data.push(ev);
        }
      }
    }

    if (!Array.isArray(data) || data.length === 0) {
      throw new Error("Etkinlik verisi alınamadı.");
    }

    const trMonths = ["", "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
    const formatTrDate = (dStr) => {
      if (!dStr || !dStr.includes("-")) return dStr || "";
      const p = dStr.split("-");
      if (p.length !== 3) return dStr;
      return `${parseInt(p[2], 10)} ${trMonths[parseInt(p[1], 10)] || ''} ${p[0]}`.trim();
    };

    let targetEvents;
    if (selectedMonth && selectedMonth !== 'all') {
      targetEvents = data.filter(x => (x.tarih || '').startsWith(selectedMonth));
      if (targetEvents.length === 0 && localEvents.length > 0) {
        targetEvents = localEvents.filter(x => (x.tarih || '').startsWith(selectedMonth));
      }
    } else {
      // Ekim 2026 öncesi eski etkinlikleri dahil etme; yalnızca Ekim ve sonrasını al
      targetEvents = data.filter(x => (x.tarih || '') >= '2026-10-01');
    }

    const finalEvents = targetEvents.length > 0 ? targetEvents : data.slice(0, 50);

    let count = 0;
    for (const item of finalEvents) {
      const id = String(item.id || Date.now() + count);
      const title = (item.baslik || "").trim();
      const category = (item.kategori || "Kültür & Sanat").trim();
      const location = (item.konum || "Gebze Kültür Merkezi").trim();
      const date = (item.tarih || "").trim();
      const time = (item.saat || "").trim();
      const formattedDate = formatTrDate(date);
      const subtitle = [location, formattedDate, time].filter(Boolean).join(" • ");
      const rawImg = (item.resim || "").trim();
      const image = rawImg ? (rawImg.startsWith("http") ? rawImg : `https://www.gebze.bel.tr/${rawImg}`) : "";
      const rawUrl = (item.url || "").trim();
      const url = rawUrl ? (rawUrl.startsWith("http") ? rawUrl : `https://www.gebze.bel.tr/${rawUrl}`) : "https://www.gebze.bel.tr/etkinlik.html";

      await setDoc(doc(db, "events", `etkinlik_${id}`), {
        id: `etkinlik_${id}`,
        eventId: id,
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
        syncedAt: serverTimestamp()
      }, { merge: true });
      count++;
    }

    const monthName = selectedMonth === '2026-11' ? 'Kasım 2026' : (selectedMonth === '2026-10' ? 'Ekim 2026' : (selectedMonth === '2026-12' ? 'Aralık 2026' : (selectedMonth === 'all' ? 'Tüm Program' : selectedMonth)));
    showToast(`✅ ${count} adet ${monthName} etkinliği başarıyla eşitlendi!`);

    const filterMonthSelect = document.getElementById("eventsFilterMonth");
    if (filterMonthSelect && selectedMonth !== 'all') {
      filterMonthSelect.value = selectedMonth;
    }

    loadEvents();
    loadDashboard();
  } catch (err) {
    alert("Etkinlik senkronizasyonu hatası: " + err.message);
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.innerText = "🌐 Seçili Ayın Etkinliklerini Çek / Güncelle";
    }
  }
};

window.cleanOldEvents = async () => {
  if (!confirm("Ekim 2026 öncesine ait eski etkinlikler veritabanından kalıcı olarak silinecek. Onaylıyor musunuz?")) {
    return;
  }
  const btn = document.getElementById("btnCleanOldEvents");
  if (btn) {
    btn.disabled = true;
    btn.innerText = "⏳ Siliniyor...";
  }
  try {
    const snap = await getDocs(collection(db, "events"));
    let deleted = 0;
    for (const d of snap.docs) {
      const data = d.data();
      const dateStr = data.date || data.tarih || '';
      if (!dateStr || dateStr < '2026-10-01') {
        await deleteDoc(doc(db, "events", d.id));
        deleted++;
      }
    }
    showToast(`🧹 ${deleted} adet eski etkinlik silindi.`);
    loadEvents();
    loadDashboard();
  } catch (err) {
    alert("Temizleme hatası: " + err.message);
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.innerText = "🧹 Eski Verileri Sil";
    }
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 11. ACİL DUYURU & BİLDİRİM YAYINI
// ─────────────────────────────────────────────────────────────────────────────
async function loadBroadcastHistory() {
  const container = document.getElementById("broadcastGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Bildirim geçmişi yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "broadcast_notifications"));
    if (snap.empty) {
      container.innerHTML = '<div class="empty-state">Henüz yayınlanmış bildirim yok.</div>';
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">
            <span>📡 Kitle: ${d.topic || 'Tüm Gebze'}</span>
            <span class="badge badge-success" style="margin-left:auto;">Yayınlandı</span>
          </div>
          <div class="item-card-title">${d.title}</div>
          <div class="item-card-desc">${d.message}</div>
          <div style="font-size:11.5px; color:var(--text-muted);">
            Tarih: ${d.createdAtText || 'Yeni'} • Kategori: ${d.category || 'Duyuru'}
          </div>
        </div>
        <div class="item-card-footer">
          <span class="badge badge-primary">Tüm Cihazlara Ulaştı</span>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('broadcast_notifications', '${docSnap.id}', loadBroadcastHistory)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadBroadcastHistory = loadBroadcastHistory;

// ─────────────────────────────────────────────────────────────────────────────
// 12. PLANLI KESİNTİLER
// ─────────────────────────────────────────────────────────────────────────────
async function loadOutages() {
  const container = document.getElementById("outagesGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Kesintiler yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "outages"));
    if (snap.empty) {
      container.innerHTML = '<div class="empty-state">Aktif planlı kesinti kaydı bulunamadı.</div>';
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const isDone = d.status === 'Tamamlandı';
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">
            <span>⚡ ${d.provider || 'Altyapı'}</span>
            <span style="margin-left:auto;">${(d.type || 'KESİNTİ').toUpperCase()}</span>
          </div>
          <div class="item-card-title">${d.title}</div>
          <div class="item-card-desc">📍 ${d.neighborhood || 'Gebze Geneli'}</div>
          <div style="font-size:12px; color:var(--text-muted); line-height:1.4;">
            🕒 Başlangıç: ${d.startDate || 'Belirtilmedi'}<br>
            🏁 Bitiş: ${d.endDate || 'Belirtilmedi'}
          </div>
        </div>
        <div class="item-card-footer">
          <button class="btn btn-sm ${isDone ? 'btn-outline' : 'btn-warning'}" onclick="toggleOutageStatus('${docSnap.id}', '${d.status || 'Devam Ediyor'}')">
            ${isDone ? '✅ Tamamlandı' : '⏳ Devam Ediyor'}
          </button>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('outages', '${docSnap.id}', loadOutages)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadOutages = loadOutages;

window.toggleOutageStatus = async (id, current) => {
  const next = current === 'Tamamlandı' ? 'Devam Ediyor' : 'Tamamlandı';
  try {
    await updateDoc(doc(db, "outages", id), { status: next });
    showToast(`Kesinti durumu "${next}" olarak güncellendi.`);
    loadOutages();
  } catch (e) { alert("Hata: " + e.message); }
};

// ─────────────────────────────────────────────────────────────────────────────
// 13. MAHALLEMDE (SAHA ÇALIŞMALARI)
// ─────────────────────────────────────────────────────────────────────────────
const WORK_CATS = {
  kazi: { label: 'Kazı', icon: '🚧' },
  altyapi: { label: 'Altyapı', icon: '🔧' },
  cevre: { label: 'Çevre', icon: '🌳' },
  yol_bakim: { label: 'Yol Bakım', icon: '🛣️' }
};

const escW = (v) => String(v ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmtTR = (d) => d.toLocaleString('tr-TR', { timeZone: 'Europe/Istanbul', day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });

async function loadWorks() {
  const container = document.getElementById("worksGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Çalışmalar yükleniyor...</div>';

  try {
    const snap = await getDocs(query(collection(db, "neighborhood_works"), orderBy("endDate")));
    const catFilter = document.getElementById("workFilterCategory")?.value || '';
    const hoodFilter = document.getElementById("workFilterNeighborhood")?.value || '';
    const now = Date.now();

    const rows = [];
    snap.forEach(docSnap => {
      const d = docSnap.data();
      if (!d.startDate?.toMillis || !d.endDate?.toMillis) return;
      if (catFilter && d.category !== catFilter) return;
      if (hoodFilter && d.neighborhood !== hoodFilter) return;
      const start = d.startDate.toMillis(), end = d.endDate.toMillis();
      const state = end < now ? 'expired' : (start <= now ? 'ongoing' : 'planned');
      rows.push({ id: docSnap.id, d, start, end, state });
    });

    if (rows.length === 0) {
      container.innerHTML = '<div class="empty-state">Kayıtlı mahalle çalışması bulunamadı.</div>';
      return;
    }

    const order = { ongoing: 0, planned: 1, expired: 2 };
    rows.sort((a, b) => order[a.state] - order[b.state] || a.start - b.start);

    container.innerHTML = '';
    rows.forEach(({ id, d, start, end, state }) => {
      const cat = WORK_CATS[d.category] || WORK_CATS.kazi;
      const badge = state === 'ongoing'
        ? '<span class="badge badge-warning">Devam Ediyor</span>'
        : state === 'planned'
          ? '<span class="badge badge-primary">Planlandı</span>'
          : '<span class="badge badge-danger">Süresi Doldu (Mobilde Gizli)</span>';

      const card = document.createElement("div");
      card.className = "item-card";
      if (state === 'expired') card.style.opacity = '0.6';
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">${cat.icon} ${cat.label}${d.unit ? ' • ' + escW(d.unit) : ''}</div>
          <div class="item-card-title">${escW(d.title)}</div>
          <div class="item-card-desc">📍 ${escW(d.neighborhood)}${d.address ? ' – ' + escW(d.address) : ''}</div>
          ${d.description ? `<div style="font-size:12px; color:var(--text-muted); line-height:1.4; margin-bottom:6px;">${escW(d.description)}</div>` : ''}
          <div style="font-size:12px; color:var(--text-muted); line-height:1.4;">
            🕒 Başlangıç: ${fmtTR(new Date(start))}<br>
            🏁 Bitiş: ${fmtTR(new Date(end))}
          </div>
        </div>
        <div class="item-card-footer">
          ${badge}
          <div style="display:flex; gap:6px;">
            ${state !== 'expired' ? `<button class="btn btn-primary btn-sm" onclick="finishWork('${id}')">Bitir</button>` : ''}
            <button class="btn btn-danger btn-sm" onclick="deleteDocItem('neighborhood_works', '${id}', loadWorks)">Sil</button>
          </div>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${escW(e.message)}</div>`;
  }
}
window.loadWorks = loadWorks;

window.finishWork = async (id) => {
  if (!confirm("Çalışma tamamlandı olarak işaretlensin mi?")) return;
  try {
    await updateDoc(doc(db, "neighborhood_works", id), { endDate: Timestamp.now() });
    showToast("Çalışma tamamlandı olarak işaretlendi.");
    loadWorks();
    loadDashboard();
  } catch (e) { alert("Hata: " + e.message); }
};

window.cleanupExpiredWorks = async () => {
  try {
    const snap = await getDocs(collection(db, "neighborhood_works"));
    const now = Date.now();
    const expired = [];
    snap.forEach(d => {
      const e = d.data().endDate;
      if (e?.toMillis && e.toMillis() < now) expired.push(d.id);
    });
    if (expired.length === 0) { showToast("Süresi dolmuş kayıt yok."); return; }
    if (!confirm(`${expired.length} adet süresi dolmuş kayıt kalıcı olarak silinsin mi?`)) return;
    await Promise.all(expired.map(id => deleteDoc(doc(db, "neighborhood_works", id))));
    showToast(`${expired.length} kayıt silindi.`);
    loadWorks();
    loadDashboard();
  } catch (e) { alert("Temizlik hatası: " + e.message); }
};

// ─────────────────────────────────────────────────────────────────────────────
// 14. NÖBETÇİ ECZANELER
// ─────────────────────────────────────────────────────────────────────────────
async function loadPharmacies() {
  const container = document.getElementById("pharmaciesGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Eczaneler yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "pharmacies_on_duty"));
    if (snap.empty) {
      container.innerHTML = `
        <div class="empty-state">
          <p style="margin-bottom:8px;">Kayıtlı nöbetçi eczane bulunmuyor.</p>
          <button class="btn btn-orange btn-sm" onclick="seedPharmacies()">💊 Resmi Nöbetçi Eczaneleri Eşitle</button>
        </div>
      `;
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">💊 ${d.district || 'Gebze'} • ${d.hours || 'Nöbetçi'}</div>
          <div class="item-card-title">${d.name}</div>
          <div class="item-card-desc">📍 ${d.address}</div>
          <div style="font-size:12.5px; font-weight:700; color:var(--navy-light);">
            📞 ${d.phone || 'Telefon yok'}
          </div>
        </div>
        <div class="item-card-footer">
          <span class="badge badge-success">7/24 Hizmet</span>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('pharmacies_on_duty', '${docSnap.id}', loadPharmacies)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadPharmacies = loadPharmacies;

// ─────────────────────────────────────────────────────────────────────────────
// 15. AFET TOPLANMA ALANLARI
// ─────────────────────────────────────────────────────────────────────────────
async function loadAssemblyAreas() {
  const container = document.getElementById("assemblyTableBody");
  if (!container) return;
  container.innerHTML = '<tr><td colspan="6" class="empty-state">Toplanma alanları yükleniyor...</td></tr>';
  try {
    const snap = await getDocs(collection(db, "assembly_areas"));
    if (snap.empty) {
      container.innerHTML = `<tr><td colspan="6" class="empty-state">
        <p style="margin-bottom:8px;">Kayıtlı afet toplanma alanı bulunmuyor.</p>
        <button class="btn btn-primary btn-sm" onclick="seedAssemblyAreas()">🏛️ Resmi Gebze Toplanma Alanlarını Eşitle</button>
      </td></tr>`;
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const tr = document.createElement("tr");
      const cap = d.area ? Math.floor(d.area / 3.5) : '–';

      tr.innerHTML = `
        <td><strong>${d.name}</strong></td>
        <td>📍 ${d.neighborhood} Mah. ${d.street ? '– ' + d.street : ''}</td>
        <td>${d.area ? d.area.toLocaleString('tr-TR') + ' m²' : '–'}</td>
        <td><span class="badge badge-primary">~${cap.toLocaleString('tr-TR')} Kişi</span></td>
        <td>
          <span title="Elektrik">${d.e ? '⚡' : '⚪'}</span>
          <span title="Su">${d.w ? '💧' : '⚪'}</span>
          <span title="WC">${d.wc ? '🚻' : '⚪'}</span>
        </td>
        <td>
          <div style="display:flex; gap:6px;">
            ${d.lat && d.lng ? `<a href="https://www.google.com/maps?q=${d.lat},${d.lng}" target="_blank" class="btn btn-outline btn-sm">Harita</a>` : ''}
            <button class="btn btn-danger btn-sm" onclick="deleteDocItem('assembly_areas', '${docSnap.id}', loadAssemblyAreas)">Sil</button>
          </div>
        </td>
      `;
      container.appendChild(tr);
    });
  } catch (e) {
    container.innerHTML = `<tr><td colspan="6" class="empty-state">Hata: ${e.message}</td></tr>`;
  }
}
window.loadAssemblyAreas = loadAssemblyAreas;

// ─────────────────────────────────────────────────────────────────────────────
// 16. GEBZE PATİ (SAHİPLENDİRME, MAMA ODAKLARI, VETERİNERLER)
// ─────────────────────────────────────────────────────────────────────────────
window.switchPatiTab = (subTab) => {
  document.querySelectorAll('#view-pets .sub-tab-btn').forEach(b => b.classList.remove('active'));
  document.querySelectorAll('.pati-sub-view').forEach(v => v.style.display = 'none');
  const btn = document.getElementById('sub-btn-' + subTab);
  if (btn) btn.classList.add('active');
  const target = document.getElementById('pati-sub-' + subTab);
  if (target) target.style.display = 'block';

  if (subTab === 'adoptions') loadPets();
  if (subTab === 'feeding') loadFeeding();
  if (subTab === 'vets') loadVets();
};

async function loadPatiData() {
  loadPets();
  loadFeeding();
  loadVets();
}
window.loadPatiData = loadPatiData;

async function loadPets() {
  const container = document.getElementById("petsGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Can dostlarımız yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "pet_adoptions"));
    if (snap.empty) {
      container.innerHTML = '<div class="empty-state">Henüz yuva arayan can dostumuz eklenmemiş.</div>';
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const isAdopted = d.isAdopted === true;
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <img src="${d.imageUrl || 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80'}" class="item-card-image" onclick="openLightbox('${d.imageUrl}')" alt="can dost">
        <div class="item-card-body">
          <div class="item-card-meta">
            <span>🐾 ${d.species || 'Dost'} • ${d.gender || 'Bilinmiyor'}</span>
            <span class="badge ${isAdopted ? 'badge-success' : 'badge-warning'}" style="margin-left:auto;">
              ${isAdopted ? 'Yuvasına Kavuştu' : 'Yuva Arıyor'}
            </span>
          </div>
          <div class="item-card-title">${d.name} (${d.age || 'Genç'})</div>
          <div class="item-card-desc">
            ${d.breed ? `<strong>Irk:</strong> ${d.breed}<br>` : ''}
            ${d.healthStatus ? `<strong>Sağlık:</strong> ${d.healthStatus}<br>` : ''}
            ${d.description || ''}
          </div>
        </div>
        <div class="item-card-footer">
          <button class="btn btn-sm ${isAdopted ? 'btn-outline' : 'btn-success'}" onclick="toggleAdopted('${docSnap.id}', ${!isAdopted})">
            ${isAdopted ? 'Tekrar İlana Al' : 'Sahiplendirildi İşaretle'}
          </button>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('pet_adoptions', '${docSnap.id}', loadPets)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadPets = loadPets;

window.toggleAdopted = async (id, status) => {
  try {
    await updateDoc(doc(db, "pet_adoptions", id), { isAdopted: status });
    showToast(status ? "Can dostumuz yuvasına kavuştu olarak işaretlendi!" : "İlan tekrar aktif edildi.");
    loadPets();
  } catch (e) { alert("Hata: " + e.message); }
};

async function loadFeeding() {
  const container = document.getElementById("feedingGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Besleme odakları yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "feeding_points"));
    if (snap.empty) {
      container.innerHTML = `
        <div class="empty-state">
          <p style="margin-bottom:8px;">Kayıtlı mama & su odağı bulunmuyor.</p>
          <button class="btn btn-orange btn-sm" onclick="seedFeedingPoints()">🥣 Resmi Odakları Eşitle</button>
        </div>
      `;
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">
            <span>🥣 ${d.neighborhood || 'Gebze'}</span>
            <span class="badge badge-success" style="margin-left:auto;">${d.status || '%100 Dolu'}</span>
          </div>
          <div class="item-card-title">${d.title || d.name}</div>
          <div class="item-card-desc">${d.description || d.address || ''}</div>
          <div style="font-size:11.5px; color:var(--text-muted);">
            🕒 Son Kontrol: ${d.lastChecked || 'Bugün'}
          </div>
        </div>
        <div class="item-card-footer">
          <span class="badge badge-primary">Aktif Odak</span>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('feeding_points', '${docSnap.id}', loadFeeding)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadFeeding = loadFeeding;

async function loadVets() {
  const container = document.getElementById("vetsGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Veteriner klinikleri yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "vet_clinics"));
    if (snap.empty) {
      container.innerHTML = `
        <div class="empty-state">
          <p style="margin-bottom:8px;">Kayıtlı veteriner kliniği bulunmuyor.</p>
          <button class="btn btn-orange btn-sm" onclick="seedVetClinics()">🏥 Resmi Klinikleri Eşitle</button>
        </div>
      `;
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">
            <span>🏥 ${d.neighborhood || 'Gebze'}</span>
            <span class="badge badge-success" style="margin-left:auto;">${d.dutyStatus || 'Nöbetçi'}</span>
          </div>
          <div class="item-card-title">${d.name}</div>
          <div class="item-card-desc">📍 ${d.address || 'Gebze'}<br>📞 ${d.phone || '0262 642 04 30'}</div>
        </div>
        <div class="item-card-footer">
          <span class="badge badge-primary">Acil Müdahale</span>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('vet_clinics', '${docSnap.id}', loadVets)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadVets = loadVets;

// ─────────────────────────────────────────────────────────────────────────────
// 17. E-BELEDİYE HİZMETLERİ
// ─────────────────────────────────────────────────────────────────────────────
async function loadEBelediye() {
  const container = document.getElementById("ebelediyeGrid");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Kategoriler yükleniyor...</div>';
  try {
    const snap = await getDocs(collection(db, "ebelediye_categories"));
    if (snap.empty) {
      container.innerHTML = `
        <div class="empty-state">
          <p style="font-weight:700; margin-bottom:8px;">Firestore'da E-Belediye verisi bulunamadı.</p>
          <button class="btn btn-primary btn-sm" onclick="seedEBelediyeOnly()">🏛️ Resmi E-Belediye Şablonunu Eşitle</button>
        </div>
      `;
      return;
    }
    container.innerHTML = '';
    snap.forEach(docSnap => {
      const d = docSnap.data();
      const sList = (d.services || []).map(s => `
        <li style="margin-bottom:8px; font-size:12.5px; border-bottom:1px dashed var(--border); padding-bottom:6px;">
          <strong>${s.name}</strong> - <span style="color:var(--text-muted);">${s.description || 'Resmi Portal'}</span><br>
          <a href="${s.url}" target="_blank" style="color:var(--navy-light); font-size:11.5px; text-decoration:none; font-weight:600;">🔗 ${s.url}</a>
        </li>
      `).join('');

      const card = document.createElement("div");
      card.className = "item-card";
      card.innerHTML = `
        <div class="item-card-body">
          <div class="item-card-meta">📁 ID: ${d.id} • ${(d.services || []).length} Hizmet</div>
          <div class="item-card-title">${d.name}</div>
          <ul style="list-style:none; padding:0; margin-top:10px;">${sList}</ul>
        </div>
        <div class="item-card-footer">
          <span class="badge badge-primary">E-Devlet & ULAKBEL Entegre</span>
          <button class="btn btn-danger btn-sm" onclick="deleteDocItem('ebelediye_categories', '${docSnap.id}', loadEBelediye)">Sil</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (e) {
    container.innerHTML = `<div class="empty-state">Hata: ${e.message}</div>`;
  }
}
window.loadEBelediye = loadEBelediye;

// ─────────────────────────────────────────────────────────────────────────────
// 18. KAYITLI VATANDAŞLAR (USERS)
// ─────────────────────────────────────────────────────────────────────────────
async function loadUsers(force = false) {
  const container = document.getElementById("usersTableBody");
  if (!force && window.usersListCache && window.usersListCache.length > 0) {
    renderUsersView();
    return;
  }
  if (container) container.innerHTML = '<tr><td colspan="8" class="empty-state">Kullanıcı profilleri yükleniyor...</td></tr>';
  try {
    const snap = await getDocs(collection(db, "users"));
    const list = [];
    snap.forEach(d => {
      list.push({ id: d.id, ...d.data() });
      window.usersMap[d.id] = d.data();
    });

    list.sort((a, b) => {
      const ta = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
      const tb = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
      return tb - ta;
    });

    window.usersListCache = list;
    const b = document.getElementById('usersCountBadge');
    if (b) b.innerText = `${list.length} Kayıtlı Vatandaş`;
    setKpi('kpiUsers', list.length);

    renderUsersView();
  } catch (e) {
    console.error("loadUsers hatası:", e);
    if (container) container.innerHTML = `<tr><td colspan="8" class="empty-state">Hata: ${e.message}</td></tr>`;
  }
}
window.loadUsers = loadUsers;

function renderUsersView() {
  const container = document.getElementById("usersTableBody");
  if (!container) return;

  const q = (document.getElementById("usersSearchInput")?.value || '').trim().toLowerCase();
  const hoodFilter = document.getElementById("usersFilterNeighborhood")?.value || '';
  const verFilter = document.getElementById("usersFilterVerified")?.value || '';

  const filtered = (window.usersListCache || []).filter(u => {
    if (hoodFilter && u.neighborhood !== hoodFilter) return false;
    if (verFilter === 'verified' && !u.isVerified) return false;
    if (verFilter === 'unverified' && u.isVerified) return false;

    if (q) {
      const fn = (u.fullName || '').toLowerCase();
      const tc = (u.tcKimlik || '').toLowerCase();
      const em = (u.email || '').toLowerCase();
      const ph = (u.phone || '').toLowerCase();
      const nh = (u.neighborhood || '').toLowerCase();
      if (!fn.includes(q) && !tc.includes(q) && !em.includes(q) && !ph.includes(q) && !nh.includes(q)) return false;
    }
    return true;
  });

  if (filtered.length === 0) {
    container.innerHTML = `<tr><td colspan="8" class="empty-state">Arama kriterlerine uygun kayıtlı vatandaş bulunamadı.</td></tr>`;
    return;
  }

  container.innerHTML = '';
  filtered.forEach(u => {
    const tr = document.createElement("tr");

    let dateStr = '–';
    if (u.createdAt?.toMillis) {
      dateStr = new Date(u.createdAt.toMillis()).toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric' });
    }

    const tcDisplay = u.tcKimlik ? (u.tcKimlik.substring(0, 3) + '*****' + u.tcKimlik.substring(8)) : '–';
    const isVerified = u.isVerified === true;

    tr.innerHTML = `
      <td>
        <div style="font-weight:700; color:var(--navy-deep);">${u.fullName || 'İsimsiz Vatandaş'}</div>
        <div style="font-size:11px; color:var(--text-muted); font-family:monospace;">${u.id.substring(0, 10)}...</div>
      </td>
      <td><span style="font-family:monospace; font-weight:700;">${tcDisplay}</span></td>
      <td>
        <div style="font-size:12.5px;">${u.email || '–'}</div>
        <div style="font-size:12px; color:var(--text-muted);">${u.phone || '–'}</div>
      </td>
      <td>
        <div style="font-weight:600;">📍 ${u.neighborhood ? u.neighborhood + ' Mah.' : 'Belirtilmedi'}</div>
        <div style="font-size:11.5px; color:var(--text-muted); max-width:180px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">${u.address || ''}</div>
      </td>
      <td>
        <span class="badge badge-primary">Talepler: ${u.totalReports || 0}</span>
        <span class="badge badge-warning">Öneriler: ${u.totalSuggestions || 0}</span>
      </td>
      <td>
        <span class="badge ${isVerified ? 'badge-success' : 'badge-warning'}">
          ${isVerified ? '✅ Doğrulandı' : '⏳ Bekliyor'}
        </span>
      </td>
      <td style="font-size:12px; color:var(--text-muted);">${dateStr}</td>
      <td>
        <div style="display:flex; align-items:center; gap:6px;">
          <button class="btn btn-outline btn-sm" onclick="openUserDetailModal('${u.id}')" title="Detaylı Profil & Düzenleme" style="font-weight:700;">
            🔍 Detay
          </button>
          ${!isVerified ? `
            <button class="btn btn-success btn-sm" onclick="toggleUserVerification('${u.id}', true, event)" title="Hesabı Hemen Onayla ve Doğrula" style="white-space:nowrap; padding:5px 9px; font-size:11.5px; font-weight:700;">
              ✓ Onayla
            </button>
          ` : `
            <button class="btn btn-outline btn-sm" onclick="toggleUserVerification('${u.id}', false, event)" title="Onayı Kaldır (Beklemeye Al)" style="white-space:nowrap; padding:5px 9px; font-size:11.5px; color:var(--text-muted);">
              ✕ Kaldır
            </button>
          `}
        </div>
      </td>
    `;
    container.appendChild(tr);
  });
}
window.renderUsersView = renderUsersView;

window.currentDetailUserId = null;

window.openUserDetailModal = (userId) => {
  window.currentDetailUserId = userId;
  const u = (window.usersListCache || []).find(x => x.id === userId) || (window.usersMap ? window.usersMap[userId] : null);
  if (!u) return;

  const isVer = u.isVerified === true;
  const statusBadge = document.getElementById("modalUserStatusBadge");
  const notice = document.getElementById("modalVerificationNotice");
  const btnApprove = document.getElementById("btnModalApprove");
  const btnRevoke = document.getElementById("btnModalRevoke");
  const btnRole = document.getElementById("btnModalToggleRole");

  if (statusBadge) {
    statusBadge.className = isVer ? "badge badge-success" : "badge badge-warning";
    statusBadge.innerText = isVer ? "✅ Doğrulanmış Hesap" : "⏳ Doğrulama Bekliyor";
  }

  if (notice) {
    notice.innerText = isVer
      ? "Bu vatandaşın belediye / kimlik doğrulaması tamamlanmıştır ve hesabı aktiftir."
      : "Bu vatandaşın hesabı henüz doğrulanmamış (onay bekliyor durumunda).";
  }

  if (btnApprove) btnApprove.style.display = isVer ? "none" : "inline-flex";
  if (btnRevoke) btnRevoke.style.display = isVer ? "inline-flex" : "none";

  const isAdm = u.role === 'admin';
  if (btnRole) {
    btnRole.innerText = isAdm ? "👤 Vatandaş Rolüne Al" : "👑 Yönetici (Admin) Yetkisi Ver";
    btnRole.className = isAdm ? "btn btn-outline btn-sm" : "btn btn-purple btn-sm";
  }

  const inputName = document.getElementById("modalEditFullName");
  const inputTc = document.getElementById("modalEditTcNo");
  const inputEmail = document.getElementById("modalEditEmail");
  const inputPhone = document.getElementById("modalEditPhone");
  const inputHood = document.getElementById("modalEditNeighborhood");
  const inputAddr = document.getElementById("modalEditAddress");

  if (inputName) inputName.value = u.fullName || '';
  if (inputTc) inputTc.value = u.tcNo || u.tcKimlik || '';
  if (inputEmail) inputEmail.value = u.email || '';
  if (inputPhone) inputPhone.value = u.phoneNumber || u.phone || '';
  if (inputHood) inputHood.value = u.neighborhood || '';
  if (inputAddr) inputAddr.value = u.address || '';

  const uidElem = document.getElementById("modalUserUid");
  if (uidElem) uidElem.innerText = u.id || '-';

  const dateElem = document.getElementById("modalUserCreatedAt");
  if (dateElem) {
    let regDate = '–';
    const rawDate = u.createdAt || u.updatedAt;
    if (rawDate) {
      if (rawDate.toMillis) regDate = new Date(rawDate.toMillis()).toLocaleString('tr-TR');
      else if (rawDate.seconds) regDate = new Date(rawDate.seconds * 1000).toLocaleString('tr-TR');
      else {
        try {
          const d = new Date(rawDate);
          if (!isNaN(d.getTime())) regDate = d.toLocaleString('tr-TR');
        } catch (_) { }
      }
    }
    dateElem.innerText = regDate;
  }

  const themeElem = document.getElementById("modalUserTheme");
  if (themeElem) themeElem.innerText = u.themeMode === 'dark' ? '🌙 Koyu Tema' : '☀️ Açık Tema';
  const fontElem = document.getElementById("modalUserFont");
  if (fontElem) fontElem.innerText = u.largeFont ? '🔍 Büyük Yazı' : 'Standart Boyut';

  const actElem = document.getElementById("modalUserActivity");
  if (actElem) actElem.innerText = `💡 ${u.totalSuggestions || 0} Öneri • 👍 ${u.totalSupported || 0} Destek`;

  const np = u.notificationPreferences || {};
  const prefs = [];
  if (np.sms || u.notifySms) prefs.push('📱 SMS');
  if (np.push || u.notifyPush) prefs.push('🔔 Push');
  if (np.emergency || u.notifyEmergency) prefs.push('🚨 Afet/Acil');
  if (np.outages || u.notifyOutages) prefs.push('⚡ Kesinti');
  if (np.news || u.notifyNews) prefs.push('📰 Haberler');
  if (np.sozSende) prefs.push('🗳️ Söz Sende');
  const prefsElem = document.getElementById("modalUserPrefs");
  if (prefsElem) prefsElem.innerText = prefs.length ? prefs.join(' • ') : 'Tüm bildirimler açık';

  const statusElem = document.getElementById("modalSaveStatus");
  if (statusElem) {
    statusElem.innerText = '';
    statusElem.style.color = 'var(--text-muted)';
  }

  const modal = document.getElementById("userDetailModal");
  if (modal) {
    modal.classList.add("open");
    modal.classList.add("active");
    modal.style.display = "flex";
  }
};

window.closeUserDetailModal = () => {
  const modal = document.getElementById("userDetailModal");
  if (modal) {
    modal.classList.remove("open");
    modal.classList.remove("active");
    modal.style.display = "none";
  }
  window.currentDetailUserId = null;
};

window.toggleUserVerification = async (userId, isVerified, event) => {
  if (event && event.stopPropagation) event.stopPropagation();
  if (!userId) return;

  const u = (window.usersListCache || []).find(x => x.id === userId) || (window.usersMap ? window.usersMap[userId] : null);
  const name = u ? (u.fullName || 'Vatandaş') : 'Vatandaş';
  const actionText = isVerified
    ? `"${name}" isimli vatandaşın hesabını onaylamak (doğrulamak) istiyor musunuz?`
    : `"${name}" isimli vatandaşın onayını kaldırmak (bekleme durumuna almak) istiyor musunuz?`;

  if (!confirm(actionText)) return;

  try {
    const userRef = doc(db, "users", userId);
    await updateDoc(userRef, {
      isVerified: isVerified,
      updatedAt: serverTimestamp()
    });

    if (window.usersMap && window.usersMap[userId]) {
      window.usersMap[userId].isVerified = isVerified;
    }
    if (window.usersListCache) {
      const item = window.usersListCache.find(x => x.id === userId);
      if (item) item.isVerified = isVerified;
    }

    renderUsersView();

    if (window.currentDetailUserId === userId) {
      openUserDetailModal(userId);
    }

    if (window.showToast) {
      window.showToast(isVerified ? `✅ ${name} hesabı başarıyla onaylandı!` : `⚠️ ${name} hesabı onayı kaldırıldı.`);
    }
  } catch (e) {
    console.error("toggleUserVerification hatası:", e);
    alert("Hesap durumu güncellenirken hata oluştu: " + e.message);
  }
};

window.toggleUserRole = async (userId) => {
  if (!userId) return;
  const u = (window.usersListCache || []).find(x => x.id === userId) || (window.usersMap ? window.usersMap[userId] : null);
  if (!u) return;

  const isCurrentAdmin = u.role === 'admin';
  const newRole = isCurrentAdmin ? 'citizen' : 'admin';
  const promptText = isCurrentAdmin
    ? `"${u.fullName || 'Vatandaş'}" kullanıcısının Yönetici (Admin) yetkisini kaldırıp normal Vatandaş yapmak istiyor musunuz?`
    : `"${u.fullName || 'Vatandaş'}" kullanıcısına Yönetici (Admin) yetkisi vermek istiyor musunuz?`;

  if (!confirm(promptText)) return;

  try {
    const userRef = doc(db, "users", userId);
    await updateDoc(userRef, {
      role: newRole,
      updatedAt: serverTimestamp()
    });

    if (window.usersMap && window.usersMap[userId]) {
      window.usersMap[userId].role = newRole;
    }
    if (window.usersListCache) {
      const item = window.usersListCache.find(x => x.id === userId);
      if (item) item.role = newRole;
    }

    renderUsersView();
    if (window.currentDetailUserId === userId) {
      openUserDetailModal(userId);
    }

    if (window.showToast) {
      window.showToast(`Rol güncellendi: ${newRole === 'admin' ? '👑 Yönetici' : '👤 Vatandaş'}`);
    }
  } catch (e) {
    console.error("toggleUserRole hatası:", e);
    alert("Rol güncellenirken hata oluştu: " + e.message);
  }
};

window.saveUserDetailChanges = async () => {
  const userId = window.currentDetailUserId;
  if (!userId) return alert("Düzenlenecek kullanıcı seçili değil.");

  const inputName = document.getElementById("modalEditFullName");
  const inputTc = document.getElementById("modalEditTcNo");
  const inputEmail = document.getElementById("modalEditEmail");
  const inputPhone = document.getElementById("modalEditPhone");
  const inputHood = document.getElementById("modalEditNeighborhood");
  const inputAddr = document.getElementById("modalEditAddress");
  const btnSave = document.getElementById("btnSaveUserChanges");
  const statusElem = document.getElementById("modalSaveStatus");

  const fullName = (inputName?.value || '').trim();
  const tcNo = (inputTc?.value || '').trim();
  const email = (inputEmail?.value || '').trim();
  const phoneNumber = (inputPhone?.value || '').trim();
  const neighborhood = (inputHood?.value || '').trim();
  const address = (inputAddr?.value || '').trim();

  if (tcNo && tcNo.length !== 11) {
    alert("T.C. Kimlik Numarası 11 haneli olmalıdır.");
    if (inputTc) inputTc.focus();
    return;
  }

  if (btnSave) {
    btnSave.disabled = true;
    btnSave.innerText = "⏳ Kaydediliyor...";
  }
  if (statusElem) {
    statusElem.innerText = "Veritabanına kaydediliyor...";
    statusElem.style.color = "var(--navy-light)";
  }

  try {
    const userRef = doc(db, "users", userId);
    const updateData = {
      fullName,
      tcNo,
      email,
      phoneNumber,
      neighborhood,
      address,
      updatedAt: serverTimestamp()
    };

    await updateDoc(userRef, updateData);

    if (window.usersMap && window.usersMap[userId]) {
      Object.assign(window.usersMap[userId], updateData);
    }
    if (window.usersListCache) {
      const item = window.usersListCache.find(x => x.id === userId);
      if (item) Object.assign(item, updateData);
    }

    renderUsersView();

    if (statusElem) {
      statusElem.innerText = "✅ Değişiklikler başarıyla kaydedildi.";
      statusElem.style.color = "var(--success)";
    }
    if (window.showToast) {
      window.showToast("💾 Vatandaş bilgileri başarıyla kaydedildi.");
    }
  } catch (e) {
    console.error("saveUserDetailChanges hatası:", e);
    alert("Bilgiler kaydedilirken hata oluştu: " + e.message);
    if (statusElem) {
      statusElem.innerText = "❌ Hata: " + e.message;
      statusElem.style.color = "var(--danger)";
    }
  } finally {
    if (btnSave) {
      btnSave.disabled = false;
      btnSave.innerHTML = `<span>💾</span> Bilgileri Kaydet`;
    }
  }
};

window.exportUsersCsv = () => {
  const users = window.usersListCache || [];
  if (users.length === 0) { alert("Dışa aktarılacak kullanıcı verisi bulunmuyor."); return; }
  const headers = ["ID", "Ad Soyad", "TC Kimlik", "E-posta", "Telefon", "Mahalle", "Adres", "Doğrulandı Mı"];
  const rows = users.map(u => [
    `"${u.id}"`,
    `"${(u.fullName || '').replace(/"/g, '""')}"`,
    `"${u.tcKimlik || ''}"`,
    `"${u.email || ''}"`,
    `"${u.phone || ''}"`,
    `"${u.neighborhood || ''}"`,
    `"${(u.address || '').replace(/"/g, '""')}"`,
    `"${u.isVerified ? 'EVET' : 'HAYIR'}"`
  ]);
  const csvContent = "\uFEFF" + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
  downloadFile(`gebze_vatandaslar_${new Date().toISOString().slice(0, 10)}.csv`, "text/csv;charset=utf-8;", csvContent);
};

// ─────────────────────────────────────────────────────────────────────────────
// 19. SİSTEM ARAÇLARI, ŞABLON EŞİTLEME & SEEDERS
// ─────────────────────────────────────────────────────────────────────────────
window.openSystemToolsModal = () => {
  const m = document.getElementById("systemToolsModal");
  if (m) m.style.display = 'flex';
};

window.closeSystemToolsModal = () => {
  const m = document.getElementById("systemToolsModal");
  if (m) m.style.display = 'none';
};

// 1. Resmi Toplanma Alanları
window.seedAssemblyAreas = async () => {
  const areas = [
    { name: "15 Temmuz Milli İrade Kent Meydanı", neighborhood: "Hacıhalil", street: "Cumhuriyet Cad.", area: 12000, lat: 40.8028, lng: 29.4307, e: true, w: true, wc: true, kind: "meydan" },
    { name: "Gebze Millet Bahçesi", neighborhood: "Mustafapaşa", street: "Şehit Yılmaz Argon Cad.", area: 55000, lat: 40.8095, lng: 29.4410, e: true, w: true, wc: true, kind: "park" },
    { name: "Gazilerdağı Tabiat Parkı Girişi", neighborhood: "Gaziler", street: "İbrahim Ağa Cad.", area: 25000, lat: 40.8220, lng: 29.4520, e: true, w: true, wc: true, kind: "mesire" },
    { name: "Eskihisar Sahil Parkı & Kale Meydanı", neighborhood: "Eskihisar", street: "Sahil Yolu Cad.", area: 15000, lat: 40.7712, lng: 29.4325, e: true, w: true, wc: true, kind: "park" },
    { name: "Beylikbağı Parkı & Kapalı Pazar Meydanı", neighborhood: "Mevlana", street: "Yavuz Selim Cad.", area: 14000, lat: 40.8210, lng: 29.4215, e: true, w: true, wc: true, kind: "park" },
    { name: "Yenikent Kapalı Pazar & Park Alanı", neighborhood: "Yenikent", street: "Karakol Cad.", area: 9500, lat: 40.8145, lng: 29.4180, e: true, w: true, wc: true, kind: "pazar" },
    { name: "Tatlıkuyu Vadisi Parkı", neighborhood: "Tatlıkuyu", street: "Ahmet Penbegüllü Bulv.", area: 22000, lat: 40.7985, lng: 29.4290, e: true, w: true, wc: true, kind: "park" },
    { name: "Osman Yılmaz Parkı & Açık Alanı", neighborhood: "Osman Yılmaz", street: "İstasyon Cad.", area: 6500, lat: 40.8010, lng: 29.4240, e: true, w: true, wc: true, kind: "park" },
    { name: "Arapçeşme Parkı & Spor Sahaları", neighborhood: "Arapçeşme", street: "Gençlik Cad.", area: 8000, lat: 40.8090, lng: 29.4470, e: true, w: true, wc: true, kind: "park" },
    { name: "Köşklü Çeşme Parkı", neighborhood: "Köşklü Çeşme", street: "555. Sok.", area: 5500, lat: 40.8035, lng: 29.4150, e: true, w: true, wc: false, kind: "park" },
    { name: "Güzeller Parkı", neighborhood: "Güzeller", street: "Bağdat Cad.", area: 7200, lat: 40.8055, lng: 29.4380, e: true, w: true, wc: true, kind: "park" },
    { name: "İstasyon Meydanı Parkı", neighborhood: "İstasyon", street: "Tren Garı Yanı", area: 9000, lat: 40.7890, lng: 29.4210, e: true, w: true, wc: true, kind: "meydan" },
    { name: "İnönü Parkı & Açık Spor Alanı", neighborhood: "İnönü", street: "İnönü Cad.", area: 6000, lat: 40.8175, lng: 29.4350, e: true, w: true, wc: true, kind: "park" },
    { name: "Barış Parkı", neighborhood: "Barış", street: "Dr. Zeki Acar Cad.", area: 5000, lat: 40.8080, lng: 29.4080, e: true, w: true, wc: false, kind: "park" }
  ];
  for (const a of areas) {
    const fixedId = "area_" + a.name.toLowerCase().replace(/[^a-z0-9]/g, '_').substring(0, 28);
    await setDoc(doc(db, "assembly_areas", fixedId), { ...a, createdAt: serverTimestamp() }, { merge: true });
  }
  showToast("Resmi toplanma alanları eşitlendi!");
  loadAssemblyAreas();
  loadDashboard();
};

// 2. Gezi Rehberi - Tarihi Mekanlar
window.seedGuidePlaces = async () => {
  const places = [
    {
      id: "cmp_camii",
      name: "Çoban Mustafa Paşa Camii ve Külliyesi",
      category: "Camiler & Külliyeler",
      summary: "Çoban Mustafa Paşa'nın 1523'te yaptırdığı cami ve külliye, Gebze'nin en önemli Osmanlı mimari başyapıtlarındandır. Mimar Sinan eseri süslemeler ve kütüphane içerir.",
      detailUrl: "https://www.gebze.bel.tr/gebze-tarihi-yerler_coban-mustafa-pasa-camii-ve-kulliyesi_1.html",
      image: "gorsel/tarihi_yerler/cmpasa.jpg"
    },
    {
      id: "sultan_orhan",
      name: "Sultan Orhan Camii",
      category: "Camiler & Külliyeler",
      summary: "Yaklaşık 1323-1331 yıllarında Orhan Bey tarafından yaptırılan, ilk dönem Osmanlı mimarisinin yalın ve zarif bir örneğidir.",
      detailUrl: "https://www.gebze.bel.tr/gebze/sultan-orhan-camii_2.html",
      image: "gorsel/tarihi_yerler/sorhan.jpg"
    },
    {
      id: "ilyas_bey",
      name: "İlyas Bey Camii",
      category: "Camiler & Külliyeler",
      summary: "Osmanlı'dan kalan en eski camilerden biri olarak kabul edilir. Kubbesiz olup girişinde nadide sülüs yazılı kitabe bulunur.",
      detailUrl: "https://www.gebze.bel.tr/gebze-tarihi-yerler_ilyas-bey-camii_3.html",
      image: "gorsel/tarihi_yerler/ilyasb.jpg"
    },
    {
      id: "anibal",
      name: "Anibal'ın (Hannibal) Mezarı",
      category: "Anıtlar & Meydanlar",
      summary: "Selvilerle çevrili alanda duran 24 tonluk taş lahit, beş dilde yazılmış kitabelerle Kartacalı büyük komutan Hannibal'ın hayatını anlatır.",
      detailUrl: "https://www.gebze.bel.tr/gebze-tarihi-yerler_anibalin-mezari_4.html",
      image: "gorsel/tarihi_yerler/anibal.jpg"
    },
    {
      id: "hunkar",
      name: "Hünkar Çayırı",
      category: "Tarihi Yapılar",
      summary: "Fatih Sultan Mehmet'in 1481'de son seferine giderken ordusunu konaklattığı ve vefat ettiği tarihi çayırlık alan ve anıt çeşme.",
      detailUrl: "https://www.gebze.bel.tr/gebze-tarihi-yerler_hunkar-cayiri_5.html",
      image: "gorsel/tarihi_yerler/hunkar.jpg"
    },
    {
      id: "eskihisar_kalesi",
      name: "Eskihisar Kalesi",
      category: "Tarihi Yapılar",
      summary: "Bizans döneminde körfezin güvenliğini sağlamak için inşa edilen, günümüzde açık hava konser ve kültür alanı olarak kullanılan tarihi sahil kalesi.",
      detailUrl: "https://www.gebze.bel.tr/gebze-tarihi-yerler_eskihisar-kalesi_6.html",
      image: "gorsel/tarihi_yerler/eskihisarkalesi.jpg"
    },
    {
      id: "osman_hamdi_bey",
      name: "Osman Hamdi Bey Evi ve Müzesi",
      category: "Müzeler",
      summary: "Ünlü Türk ressam ve arkeolog Osman Hamdi Bey'in 1884'te inşa ettirdiği, 'Kaplumbağa Terbiyecisi' dahil başyapıtlarını ürettiği tarihi konak.",
      detailUrl: "https://www.gebze.bel.tr/gebze-tarihi-yerler_osman-hamdi-bey-evi-ve-muzesi_7.html",
      image: "gorsel/tarihi_yerler/ohamdi.jpg"
    },
    {
      id: "tarihi_su_dolabi",
      name: "Tarihi Su Dolabı",
      category: "Tarihi Yapılar",
      summary: "Osmanlı döneminde kente su sağlayan tarihi su dolabı yapısı; restore edilerek kültür sohbetlerine ev sahipliği yapan bir mekan haline getirilmiştir.",
      detailUrl: "https://www.gebze.bel.tr",
      image: "gorsel/tarihi_yerler/sudolabi.jpg"
    }
  ];
  for (const p of places) {
    await setDoc(doc(db, "guide_places", p.id), { ...p, createdAt: serverTimestamp() }, { merge: true });
  }
  showToast("Resmi tarihi mekanlar eşitlendi!");
  loadGuidePlaces();
  loadDashboard();
};

// 3. Gezi Rehberi - Doğa Rotaları & Piknik
window.seedGuidePicnic = async () => {
  const rotalar = [
    {
      id: "ballikayalar_parkuru",
      title: "Ballıkayalar Tabiat Parkı & Kanyon Parkuru",
      type: "doga",
      neighborhood: "Tavşanlı Köyü",
      description: "1.5 kilometrelik derin kanyon boyunca uzanan şelaleler, göletler ve tırmanış kayalıklarıyla Marmara bölgesinin en gözde doğa yürüyüş parkuru.",
      walkingKm: "7.5 Km",
      image: "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80"
    },
    {
      id: "gazilerdagi_parkuru",
      title: "Gazilerdağı Tabiat Parkı Zirve Yürüyüşü",
      type: "doga",
      neighborhood: "Gaziler Mahallesi",
      description: "Çam ormanları içinde kuş cıvıltıları eşliğinde Gebze ve İzmit Körfezi manzarasına hakim seyir teraslı nefis trekking rotası.",
      walkingKm: "4.8 Km",
      image: "https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=800&q=80"
    },
    {
      id: "denizli_goleti",
      title: "Denizli Göleti Çevre Yürüyüş Rotası & Mesire",
      type: "mesire",
      neighborhood: "Denizli Köyü",
      description: "Gölet etrafında ahşap köprüler, dinlenme kamelyaları ve yemyeşil kır manzaralarıyla huzurlu yürüyüş ve doğa fotoğrafçılığı alanı.",
      walkingKm: "5.2 Km",
      image: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80"
    },
    {
      id: "mudarli_rotasi",
      title: "Mudarlı Köyü Meşe Ormanları Parkuru",
      type: "doga",
      neighborhood: "Mudarlı Köyü",
      description: "Kuzey Gebze kırsalında asırlık meşe ve gürgen ağaçları arasından geçen, temiz havası ve köy atmosferiyle doğaseverlerin vazgeçilmezi.",
      walkingKm: "6.0 Km",
      image: "https://images.unsplash.com/photo-1426604966848-d7adac402bff?auto=format&fit=crop&w=800&q=80"
    },
    {
      id: "ovacik_parkuru",
      title: "Ovacık Köyü & Vadi Doğa Parkuru",
      type: "doga",
      neighborhood: "Ovacık Köyü",
      description: "Orman içi patikalar ve dere kenarından ilerleyen orta seviye trekking rotası. Doğal pınarlar ve piknik noktaları barındırır.",
      walkingKm: "5.5 Km",
      image: "https://images.unsplash.com/photo-1511497584788-87676104235f?auto=format&fit=crop&w=800&q=80"
    }
  ];
  for (const r of rotalar) {
    await setDoc(doc(db, "guide_picnic", r.id), { ...r, createdAt: serverTimestamp() }, { merge: true });
  }
  showToast("5 adet resmi doğa yürüyüş rotası eşitlendi!");
  loadGuidePicnic();
};

// 4. Gezi Rehberi - Lezzet Durakları
window.seedGuideFoods = async () => {
  const lezzetler = [
    {
      id: "tarihi_corek",
      title: "Tarihi Gebze Çöreği & Çarşı Fırını",
      category: "Geleneksel Lezzetler",
      description: "Anason, mahlep ve özel mayayla hazırlanan, asırlık geleneksel Gebze çöreği ve simidi.",
      address: "Hacıhalil Mah. Tarihi Çarşı İçi No:18",
      image: "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80"
    },
    {
      id: "carsi_kofte",
      title: "Meşhur Tarihi Çarşı Köftecisi",
      category: "Köfte & Et Restoranı",
      description: "Özel harman kıyma ve geleneksel pişirme usulüyle Gebzelilerin yarım asırlık lezzet durağı.",
      address: "Cumhuriyet Meydanı Eski Çarşı No:7",
      image: "https://images.unsplash.com/photo-1529042410759-befb1204b468?auto=format&fit=crop&w=800&q=80"
    },
    {
      id: "eskihisar_balik",
      title: "Eskihisar Sahil Balıkçıları & Çay Bahçeleri",
      category: "Deniz Ürünleri & Balık",
      description: "İzmit Körfezi ve Eskihisar Kalesi manzarası eşliğinde taze mevsim balıkları ve sahil keyfi.",
      address: "Eskihisar Sahil Kordonu",
      image: "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=800&q=80"
    },
    {
      id: "koy_kahvalti",
      title: "Tavşanlı & Denizli Köy Kahvaltı Evleri",
      category: "Kahvaltı & Kafe",
      description: "Köy tereyağı, manda kaymağı ve organik bahçe ürünleriyle doğa eşliğinde serpme kahvaltı.",
      address: "Tavşanlı Köy Yolu No:24",
      image: "https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?auto=format&fit=crop&w=800&q=80"
    }
  ];
  for (const l of lezzetler) {
    await setDoc(doc(db, "guide_foods", l.id), { ...l, createdAt: serverTimestamp() }, { merge: true });
  }
  showToast("Resmi Gebze lezzet durakları eşitlendi!");
  loadGuideFoods();
};

// 5. Gezi Rehberi - Kamu Kurumları
window.seedGuideInstitutions = async () => {
  const kurumlar = [
    { id: "gebze_belediyesi", name: "Gebze Belediyesi Ana Hizmet Binası", category: "Belediye", address: "Mevlana Mah. Issıkgöl Cad. No:1", phone: "0262 642 04 30", url: "https://www.gebze.bel.tr" },
    { id: "gebze_kaymakamligi", name: "Gebze Kaymakamlığı & Hükümet Konağı", category: "Mülki İdare", address: "Hacıhalil Mah. Hükümet Cad. No:3", phone: "0262 641 10 01", url: "http://www.gebze.gov.tr" },
    { id: "gebze_kultur_merkezi", name: "Gebze Kültür Merkezi (GKM)", category: "Kültür & Sanat", address: "Hacıhalil Mah. Şehit Numan Dede Cad.", phone: "0262 644 19 62", url: "https://www.gebze.bel.tr" },
    { id: "fatih_devlet_hastanesi", name: "SBÜ Gebze Fatih Devlet Hastanesi", category: "Sağlık", address: "İnönü Mah. İbrahimağa Cad. No:131", phone: "0262 644 14 60", url: "https://gebzefatihdevlethastanesi.saglik.gov.tr" }
  ];
  for (const k of kurumlar) {
    await setDoc(doc(db, "guide_institutions", k.id), { ...k, createdAt: serverTimestamp() }, { merge: true });
  }
  showToast("Resmi kamu kurumları eşitlendi!");
  loadGuideInstitutions();
};

window.seedGuideAll = async () => {
  await seedGuidePlaces();
  await seedGuidePicnic();
  await seedGuideFoods();
  await seedGuideInstitutions();
  showToast("Tüm Gezi & Kent Rehberi koleksiyonları eşitlendi!");
};

// 6. Gündüz Bakımevleri & Kreşler
window.seedNurseries = async () => {
  const kresler = [
    {
      id: "kres_arapcesme",
      name: "Arapçeşme Gündüz Bakımevi & Çocuk Kreşi",
      neighborhood: "Arapçeşme",
      address: "Arapçeşme Mah. Gençlik Cad. No:14",
      capacity: 90,
      ageGroup: "3 - 6 Yaş",
      phone: "0262 642 04 30",
      imageUrl: "https://images.unsplash.com/photo-1576495199011-eb94736d05d6?auto=format&fit=crop&w=800&q=80",
      description: "Montessori eğitim modeli, spor ve sanat atölyeleriyle çocuklarımızın bilişsel ve sosyal gelişimini destekleyen modern belediye kreşi."
    },
    {
      id: "kres_mustafapasa",
      name: "Mustafapaşa Çocuk Gelişim Merkezi & Kreş",
      neighborhood: "Mustafapaşa",
      address: "Mustafapaşa Mah. Şehit Yılmaz Argon Cad. No:22",
      capacity: 80,
      ageGroup: "3 - 6 Yaş",
      phone: "0262 642 04 30",
      imageUrl: "https://images.unsplash.com/photo-1587654780291-39c9404d746b?auto=format&fit=crop&w=800&q=80",
      description: "Geniş oyun bahçesi, psikolojik danışmanlık rehberliği ve organik beslenme programı sunulmaktadır."
    },
    {
      id: "kres_beylikbagi",
      name: "Beylikbağı Bilim & Sanat Çocuk Kreşi",
      neighborhood: "Beylikbağı",
      address: "Beylikbağı Mah. Sarı Cami Yanı No:5",
      capacity: 100,
      ageGroup: "3 - 6 Yaş",
      phone: "0262 642 04 30",
      imageUrl: "https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?auto=format&fit=crop&w=800&q=80",
      description: "Robotik kodlama temelleri, yabancı dil atölyesi ve drama etkinlikleriyle donatılmıştır."
    },
    {
      id: "kres_yenikent",
      name: "Yenikent Minik Eller Gündüz Bakımevi",
      neighborhood: "Yenikent",
      address: "Yenikent Mah. Karakol Cad. No:18",
      capacity: 75,
      ageGroup: "3 - 6 Yaş",
      phone: "0262 642 04 30",
      imageUrl: "https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80",
      description: "Çağdaş eğitim müfredatı ve uzman eğitmen kadrosuyla çalışan annelere tam destek."
    }
  ];
  for (const k of kresler) {
    await setDoc(doc(db, "nurseries", k.id), { ...k, createdAt: serverTimestamp() }, { merge: true });
  }
  showToast("Belediye kreşleri eşitlendi!");
  loadNurseries();
  loadDashboard();
};

// 7. Nöbetçi Eczaneler
window.seedPharmacies = async () => {
  const eczaneler = [
    { id: "ecz_merkez", name: "Gebze Merkez Eczanesi", district: "Gebze Çarşı", address: "Hacıhalil Mah. Hükümet Cad. No:12", phone: "0262 641 12 34", hours: "Bugün 18:30 - Yarın 08:30" },
    { id: "ecz_fatih", name: "Fatih Devlet Eczanesi", district: "Fatih Hastane Yanı", address: "İnönü Mah. İbrahimağa Cad. No:135", phone: "0262 644 56 78", hours: "7/24 Açık Nöbetçi" },
    { id: "ecz_mustafapasa", name: "Çoban Mustafa Paşa Eczanesi", district: "Mustafapaşa", address: "Mustafapaşa Mah. Bağdat Cad. No:44", phone: "0262 642 98 76", hours: "Bugün 18:30 - Yarın 08:30" },
    { id: "ecz_tatlikuyu", name: "Tatlıkuyu Vadisi Eczanesi", district: "Tatlıkuyu", address: "Tatlıkuyu Mah. Körfez Cad. No:20", phone: "0262 646 11 22", hours: "Bugün 18:30 - Yarın 08:30" },
    { id: "ecz_eskihisar", name: "Eskihisar Sahil Eczanesi", district: "Eskihisar", address: "Eskihisar Mah. Sahil Yolu No:8", phone: "0262 643 33 44", hours: "Gece 24:00'e Kadar Açık" }
  ];
  for (const e of eczaneler) {
    await setDoc(doc(db, "pharmacies_on_duty", e.id), { ...e, createdAt: serverTimestamp() }, { merge: true });
  }
  showToast("Resmi nöbetçi eczaneler eşitlendi!");
  loadPharmacies();
  loadDashboard();
};

// 8. Pati Portalı - Mama Odakları & Klinikleri
window.seedFeedingPoints = async () => {
  const points = [
    { id: "fp_gaziler", title: "Gazilerdağı Tabiat Parkı Can Dostu Odağı", neighborhood: "Gaziler", description: "Orman yürüyüş yolu başlangıcı sol giriş alanı", status: "%100 Dolu", lastChecked: "Bugün" },
    { id: "fp_eskihisar", title: "Eskihisar Sahil Parkı Besleme Noktası", neighborhood: "Eskihisar", description: "Kale altı otopark arkası gölgelik alan", status: "%100 Dolu", lastChecked: "Bugün" },
    { id: "fp_denizli", title: "Denizli Göleti Kır Alanı Besleme Odağı", neighborhood: "Denizli Köyü", description: "Mesire alanı gölet kenarı güvenli bölge", status: "%50 Dolu", lastChecked: "Dün" },
    { id: "fp_pelitli", title: "Pelitli Can Dostları Doğal Yaşam Odağı", neighborhood: "Pelitli", description: "Kırsal alan otomatik su ve mama ünitesi", status: "%100 Dolu", lastChecked: "Bugün" }
  ];
  for (const p of points) {
    await setDoc(doc(db, "feeding_points", p.id), { ...p, createdAt: serverTimestamp() }, { merge: true });
  }
  showToast("Besleme odakları eşitlendi!");
  loadFeeding();
};

window.seedVetClinics = async () => {
  const clinics = [
    { id: "vet_belediye", name: "Gebze Belediyesi Sokak Hayvanları Tedavi ve Rehabilitasyon Merkezi", neighborhood: "Pelitli", address: "Pelitli Mah. Hayvan Barınağı Yolu", phone: "0262 642 04 30", dutyStatus: "7/24 Kesintisiz Acil Hizmet" },
    { id: "vet_merkez", name: "Gebze Pati Acil Veteriner Kliniği", neighborhood: "Hacıhalil", address: "Hacıhalil Mah. İsmetpaşa Cad. No:32", phone: "0262 641 80 80", dutyStatus: "7/24 Nöbetçi Klinik" },
    { id: "vet_marmara", name: "Marmara Veteriner Tıp Merkezi", neighborhood: "Mustafapaşa", address: "Mustafapaşa Mah. Şehit Numan Dede Cad. No:50", phone: "0262 646 90 90", dutyStatus: "Gece 24:00'e Kadar Nöbetçi" }
  ];
  for (const c of clinics) {
    await setDoc(doc(db, "vet_clinics", c.id), { ...c, createdAt: serverTimestamp() }, { merge: true });
  }
  showToast("Nöbetçi veteriner klinikleri eşitlendi!");
  loadVets();
};

// 9. E-Belediye Şablonu
window.seedEBelediyeOnly = async () => {
  const cats = [
    {
      id: 29, name: 'Vergi İşlemleri', icon: 'receipt_long',
      services: [
        { id: 21, name: 'Vergi / Borç Ödeme', description: 'Emlak, çevre temizlik, ilan-reklam borç sorgulama ve ödeme', url: 'https://portal.gebze.bel.tr/ui/user/login', hasModal: false },
        { id: 123, name: 'e-Beyan Bildirimleri (ULAKBEL)', description: 'Arsa, arazi, mesken, işyeri ve çevre temizlik e-beyan formları', url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/', hasModal: true },
        { id: 60, name: 'e-Beyan Bildirim Takip', description: 'Yapılan e-beyan bildirimlerinin durum sorgulaması', url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/#/Status', hasModal: false }
      ]
    },
    {
      id: 30, name: 'Gebze İletişim Merkezi (Çözüm Masası)', icon: 'support_agent',
      services: [
        { id: 124, name: 'Başvuru Formu (ULAKBEL)', description: 'İstek, şikayet, teşekkür, proje önerisi ve ihbar', url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/', hasModal: true },
        { id: 69, name: 'Başvuru Takip (ULAKBEL)', description: 'T.C. Kimlik veya Takip No ile sonuç sorgulama', url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/#/Status', hasModal: false }
      ]
    },
    {
      id: 31, name: 'İnteraktif Hizmetler', icon: 'touch_app',
      services: [
        { id: 45, name: 'e-Eksper', description: 'Gayrimenkul değerleme ve ekspertiz raporu', url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/eeksper#/', hasModal: false },
        { id: 51, name: 'e-İşyeri Ruhsat', description: 'Sıhhi ve gayrisıhhi müesseseler ruhsat başvurusu', url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-isyeri-ruhsat#/', hasModal: false },
        { id: 59, name: 'E-Moloz Hattı', description: 'İnşaat ve tadilat atıkları için moloz alım talebi', url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-moloz-hatti#/', hasModal: false },
        { id: 61, name: 'Sosyal Yardım Online Başvuru', description: 'Sosyal yardım ve destek online başvuru formu', url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/sosyal-yardimlar-online-basvuru-formu#/', hasModal: false }
      ]
    },
    {
      id: 32, name: 'İmar Yönetim Sistemi', icon: 'apartment',
      services: [
        { id: 127, name: 'İmar Durumu Başvurusu', description: 'Resmi parsel imar durumu belgesi başvurusu', url: 'https://eimar.gebze.bel.tr/', hasModal: false },
        { id: 128, name: 'Yapı Ruhsatı Başvuruları', description: 'Mimari ve statik proje onay süreçleri', url: 'https://eimar.gebze.bel.tr/', hasModal: false }
      ]
    }
  ];
  for (const c of cats) {
    await setDoc(doc(db, "ebelediye_categories", "cat_" + c.id), c, { merge: true });
  }
  showToast("E-Belediye şablonları ULAKBEL ve resmi portallarla eşitlendi!");
  loadEBelediye();
};

// 10. Mükerrer Veritabanı Temizliği (Deduplication)
window.deduplicateDatabase = async () => {
  const btn = document.getElementById("btnDeduplicate");
  if (btn) btn.disabled = true;
  try {
    const targets = [
      { name: 'vet_clinics', key: 'name' },
      { name: 'feeding_points', key: 'title' },
      { name: 'pet_adoptions', key: 'name' },
      { name: 'pharmacies_on_duty', key: 'name' },
      { name: 'assembly_areas', key: 'name' },
      { name: 'outages', key: 'title' },
      { name: 'municipal_news', key: 'title' },
      { name: 'polls', key: 'question' },
      { name: 'guide_places', key: 'name' },
      { name: 'guide_picnic', key: 'title' },
      { name: 'nurseries', key: 'name' }
    ];

    let totalDeleted = 0;
    for (const t of targets) {
      const snap = await getDocs(collection(db, t.name));
      const seen = new Map();
      for (const d of snap.docs) {
        const val = (d.data()[t.key] || '').toString().trim().toLowerCase();
        if (!val) continue;
        if (seen.has(val)) {
          await deleteDoc(doc(db, t.name, d.id));
          totalDeleted++;
        } else {
          seen.set(val, d.id);
        }
      }
    }
    showToast(`🧹 Temizlik tamamlandı: ${totalDeleted} adet mükerrer kayıt temizlendi.`);
    loadDashboard();
  } catch (e) {
    alert("Temizlik hatası: " + e.message);
  } finally {
    if (btn) btn.disabled = false;
  }
};

// 11. Veri Dışa Aktarma (Export CSV / JSON)
window.exportData = async (colName, format) => {
  try {
    const snap = await getDocs(collection(db, colName));
    const list = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    if (list.length === 0) { alert("Dışa aktarılacak kayıt bulunmuyor."); return; }

    const dateStr = new Date().toISOString().slice(0, 10);
    if (format === 'json') {
      const jsonStr = JSON.stringify(list, null, 2);
      downloadFile(`gebze_${colName}_${dateStr}.json`, "application/json", jsonStr);
    } else {
      let csv = "\uFEFF";
      if (colName === 'reports') {
        csv += "Takip No,Tarih,Vatandaş,Telefon,Mahalle,Adres,Kategori,Açıklama,Durum,Belediye Yanıtı\n";
        csv += list.map(r => [
          `"${r.ticketNo || r.id}"`,
          `"${r.createdAt?.toMillis ? new Date(r.createdAt.toMillis()).toLocaleString('tr-TR') : ''}"`,
          `"${(r.userName || '').replace(/"/g, '""')}"`,
          `"${r.userPhone || ''}"`,
          `"${r.neighborhood || ''}"`,
          `"${(r.address || '').replace(/"/g, '""')}"`,
          `"${r.category || ''}"`,
          `"${(r.description || '').replace(/"/g, '""')}"`,
          `"${r.status || 'Beklemede'}"`,
          `"${(r.response || r.adminNote || '').replace(/"/g, '""')}"`
        ].join(",")).join("\n");
      } else {
        const keys = Object.keys(list[0] || {});
        csv += keys.join(",") + "\n";
        csv += list.map(item => keys.map(k => `"${String(item[k] ?? '').replace(/"/g, '""')}"`).join(",")).join("\n");
      }
      downloadFile(`gebze_${colName}_${dateStr}.csv`, "text/csv;charset=utf-8;", csv);
    }
    showToast("Veri başarıyla dışa aktarıldı!");
  } catch (e) {
    alert("Dışa aktarma hatası: " + e.message);
  }
};

function downloadFile(filename, type, data) {
  const blob = new Blob([data], { type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// 12. Genel Silme Fonksiyonu
window.deleteDocItem = async (colName, docId, callback) => {
  if (!confirm("Bu kaydı kalıcı olarak silmek istediğinize emin misiniz?")) return;
  try {
    await deleteDoc(doc(db, colName, docId));
    showToast("Kayıt başarıyla silindi.");
    if (callback) callback();
    loadDashboard();
  } catch (e) {
    alert("Silme hatası: " + e.message);
  }
};

// 13. Lightbox & Toast
window.openLightbox = (url) => {
  if (!url) return;
  const lb = document.getElementById("imageLightbox");
  const img = document.getElementById("lightboxImg");
  if (lb && img) {
    img.src = url;
    lb.style.display = 'flex';
  }
};

window.closeLightbox = () => {
  const lb = document.getElementById("imageLightbox");
  if (lb) lb.style.display = 'none';
};

function showToast(msg) {
  const t = document.getElementById("toast");
  if (!t) return;
  t.innerText = msg;
  t.style.display = 'block';
  setTimeout(() => { t.style.display = 'none'; }, 3400);
}

// ─────────────────────────────────────────────────────────────────────────────
// 20. FORM DİNLEYİCİLERİ & DOM GÜVENLİĞİ
// ─────────────────────────────────────────────────────────────────────────────
function initFormListeners() {
  // 1. Haber Ekle
  document.getElementById("formAddNews")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      const generatedId = Math.floor(Date.now() / 1000);
      await addDoc(collection(db, "municipal_news"), {
        newsId: generatedId,
        title: document.getElementById("newsTitle").value.trim(),
        summary: document.getElementById("newsSummary").value.trim(),
        category: document.getElementById("newsCategory").value,
        publishedAtText: document.getElementById("newsDate").value.trim() || new Date().toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' }),
        image: document.getElementById("newsImage").value.trim() || "https://images.unsplash.com/photo-1585829365295-ab7cd400c167?auto=format&fit=crop&w=800&q=80",
        url: document.getElementById("newsUrl").value.trim() || "https://www.gebze.bel.tr/",
        pageIndex: 1,
        itemIndex: 1,
        publishedAt: serverTimestamp(),
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Haber canlı olarak mobil uygulamada yayınlandı!");
      loadNews();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 2. Etkinlik Ekle
  document.getElementById("formAddEvent")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      const title = document.getElementById("eventTitle").value.trim();
      const loc = document.getElementById("eventSubtitle").value.trim();
      const date = document.getElementById("eventDate").value.trim();
      const cat = document.getElementById("eventCategoryManual").value;

      await addDoc(collection(db, "events"), {
        title,
        name: title,
        location: loc,
        subtitle: loc,
        date,
        formattedDate: date,
        category: cat,
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Özel etkinlik sisteme eklendi!");
      loadEvents();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 3. Kesinti Ekle
  document.getElementById("formAddOutage")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      await addDoc(collection(db, "outages"), {
        title: document.getElementById("outageTitle").value.trim(),
        type: document.getElementById("outageType").value,
        provider: document.getElementById("outageProvider").value.trim() || "Altyapı",
        neighborhood: document.getElementById("outageNeighborhood").value.trim(),
        startDate: document.getElementById("outageStart").value.trim(),
        endDate: document.getElementById("outageEnd").value.trim(),
        status: document.getElementById("outageStatus").value,
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Planlı kesinti bildirimi kaydedildi!");
      loadOutages();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 4. Anket Ekle
  document.getElementById("formAddPoll")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    const questionText = document.getElementById("pollQuestion").value.trim();
    if (!questionText) return;
    btn.disabled = true;
    try {
      const qSnap = await getDocs(query(collection(db, "polls"), where("question", "==", questionText)));
      if (!qSnap.empty) {
        alert("Bu soruyla kayıtlı bir anket zaten var. Mükerrer kayıt engellendi.");
        btn.disabled = false;
        return;
      }
      const rawOpts = document.getElementById("pollOptions").value.split("\n").map(s => s.trim()).filter(Boolean);
      const votesMap = {};
      rawOpts.forEach((_, i) => votesMap[i] = 0);

      await addDoc(collection(db, "polls"), {
        question: questionText,
        description: document.getElementById("pollDesc").value.trim(),
        neighborhood: document.getElementById("pollNeighborhood").value.trim() || "Tüm Gebze",
        endDate: document.getElementById("pollEndDate").value.trim() || "Süresiz",
        options: rawOpts,
        votes: votesMap,
        isActive: true,
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Yeni anket oylamaya açıldı!");
      loadPolls();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 5. Gezi - Mekan Ekle
  document.getElementById("formAddGuidePlace")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      const name = document.getElementById("placeName").value.trim();
      const id = "place_" + Date.now();
      await setDoc(doc(db, "guide_places", id), {
        id,
        name,
        category: document.getElementById("placeCategory").value,
        summary: document.getElementById("placeSummary").value.trim(),
        image: document.getElementById("placeImage").value.trim(),
        detailUrl: document.getElementById("placeUrl").value.trim() || "https://www.gebze.bel.tr",
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Tarihi mekan rehbere eklendi!");
      loadGuidePlaces();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 6. Gezi - Doğa / Piknik Rota Ekle
  document.getElementById("formAddGuidePicnic")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      const id = "picnic_" + Date.now();
      await setDoc(doc(db, "guide_picnic", id), {
        id,
        title: document.getElementById("picnicTitle").value.trim(),
        type: document.getElementById("picnicType").value,
        neighborhood: document.getElementById("picnicHood").value.trim(),
        walkingKm: document.getElementById("picnicKm").value.trim(),
        image: document.getElementById("picnicImage").value.trim() || "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80",
        description: document.getElementById("picnicDesc").value.trim(),
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Doğa yürüyüş rotası kaydedildi!");
      loadGuidePicnic();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 7. Gezi - Lezzet Noktası Ekle
  document.getElementById("formAddGuideFood")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      const id = "food_" + Date.now();
      await setDoc(doc(db, "guide_foods", id), {
        id,
        title: document.getElementById("foodTitle").value.trim(),
        category: document.getElementById("foodCategory").value,
        address: document.getElementById("foodAddress").value.trim(),
        image: document.getElementById("foodImage").value.trim() || "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80",
        description: document.getElementById("foodDesc").value.trim(),
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Lezzet noktası kaydedildi!");
      loadGuideFoods();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 8. Gezi - Kurum Ekle
  document.getElementById("formAddGuideInst")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      const id = "inst_" + Date.now();
      await setDoc(doc(db, "guide_institutions", id), {
        id,
        name: document.getElementById("instName").value.trim(),
        category: document.getElementById("instCategory").value.trim() || "Kamu Kurumu",
        phone: document.getElementById("instPhone").value.trim(),
        address: document.getElementById("instAddress").value.trim(),
        url: document.getElementById("instUrl").value.trim() || "https://www.gebze.bel.tr",
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Kamu kurumu rehbere eklendi!");
      loadGuideInstitutions();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 9. Kreş Ekle
  document.getElementById("formAddNursery")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      const id = "nursery_" + Date.now();
      await setDoc(doc(db, "nurseries", id), {
        id,
        name: document.getElementById("nurseryName").value.trim(),
        neighborhood: document.getElementById("nurseryHood").value.trim(),
        capacity: parseInt(document.getElementById("nurseryCapacity").value, 10) || 80,
        ageGroup: document.getElementById("nurseryAge").value.trim() || "3 - 6 Yaş",
        phone: document.getElementById("nurseryPhone").value.trim() || "0262 642 04 30",
        address: document.getElementById("nurseryAddress").value.trim(),
        imageUrl: document.getElementById("nurseryImage").value.trim() || "https://images.unsplash.com/photo-1576495199011-eb94736d05d6?auto=format&fit=crop&w=800&q=80",
        description: document.getElementById("nurseryDesc").value.trim(),
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Yeni belediye kreşi sisteme eklendi!");
      loadNurseries();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 10. Can Dost Ekle
  document.getElementById("formAddPet")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      await addDoc(collection(db, "pet_adoptions"), {
        name: document.getElementById("petName").value.trim(),
        species: document.getElementById("petSpecies").value,
        breed: document.getElementById("petBreed").value.trim() || "Melez",
        gender: document.getElementById("petGender").value,
        age: document.getElementById("petAge").value.trim(),
        imageUrl: document.getElementById("petImage").value.trim() || "https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80",
        healthStatus: document.getElementById("petHealth").value.trim() || "Aşılı, çipli",
        description: document.getElementById("petDesc").value.trim(),
        isAdopted: false,
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Can dostumuz ilana eklendi!");
      loadPets();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 11. Mama Odak Ekle
  document.getElementById("formAddFeeding")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      await addDoc(collection(db, "feeding_points"), {
        title: document.getElementById("feedingTitle").value.trim(),
        neighborhood: document.getElementById("feedingHood").value.trim(),
        status: document.getElementById("feedingStatus").value,
        description: document.getElementById("feedingDesc").value.trim(),
        lastChecked: "Bugün",
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Mama & su odağı kaydedildi!");
      loadFeeding();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 12. Veteriner Ekle
  document.getElementById("formAddVet")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      await addDoc(collection(db, "vet_clinics"), {
        name: document.getElementById("vetName").value.trim(),
        neighborhood: document.getElementById("vetHood").value.trim(),
        phone: document.getElementById("vetPhone").value.trim(),
        dutyStatus: document.getElementById("vetDuty").value,
        address: document.getElementById("vetAddress").value.trim(),
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Veteriner kliniği sisteme kaydedildi!");
      loadVets();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 13. Eczane Ekle
  document.getElementById("formAddPharmacy")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      await addDoc(collection(db, "pharmacies_on_duty"), {
        name: document.getElementById("pharmacyName").value.trim(),
        district: document.getElementById("pharmacyDistrict").value.trim(),
        phone: document.getElementById("pharmacyPhone").value.trim(),
        hours: document.getElementById("pharmacyHours").value.trim() || "Bugün 18:30 - Yarın 08:30",
        address: document.getElementById("pharmacyAddress").value.trim(),
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Nöbetçi eczane listeye eklendi!");
      loadPharmacies();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 14. Afet Toplanma Alanı Ekle
  document.getElementById("formAddAssembly")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      await addDoc(collection(db, "assembly_areas"), {
        name: document.getElementById("assemblyName").value.trim(),
        neighborhood: document.getElementById("assemblyNeighborhood").value,
        street: document.getElementById("assemblyStreet").value.trim(),
        area: parseInt(document.getElementById("assemblyAreaM2").value, 10) || 5000,
        lat: parseFloat(document.getElementById("assemblyLat").value) || 40.8028,
        lng: parseFloat(document.getElementById("assemblyLng").value) || 29.4307,
        e: document.getElementById("assemblyHasElec").checked,
        w: document.getElementById("assemblyHasWater").checked,
        wc: document.getElementById("assemblyHasWc").checked,
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Toplanma alanı kaydedildi!");
      loadAssemblyAreas();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 15. Canlı Bildirim Yayını
  document.getElementById("formBroadcast")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    btn.disabled = true;
    try {
      const targetPage = document.getElementById("broadcastTargetPage")?.value || "news";
      const targetSelect = document.getElementById("broadcastTargetPage");
      const selectedOptText = targetSelect?.options[targetSelect.selectedIndex]?.text || "";
      const targetLabel = selectedOptText.replace(/^[^\s]+\s/, '').trim();
      await addDoc(collection(db, "broadcast_notifications"), {
        title: document.getElementById("broadcastTitle").value.trim(),
        message: document.getElementById("broadcastMessage").value.trim(),
        targetPage,
        actionType: targetPage,
        targetLabel,
        topic: document.getElementById("broadcastTopic").value,
        category: document.getElementById("broadcastCategory").value,
        priority: document.getElementById("broadcastPriority")?.value || "normal",
        neighborhood: document.getElementById("broadcastNeighborhood")?.value || "all",
        actionButtonLabel: document.getElementById("broadcastActionLabel")?.value.trim() || "",
        externalUrl: document.getElementById("broadcastExternalUrl")?.value.trim() || "",
        imageUrl: document.getElementById("broadcastImageUrl")?.value.trim() || "",
        createdAtText: new Date().toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }) + ' ' + new Date().toLocaleDateString('tr-TR'),
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Acil duyuru ve bildirim tüm cihazlara yayınlandı!");
      loadBroadcastHistory();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });

  // 16. Mahalle Çalışması Ekle
  document.getElementById("formAddWork")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector("button[type=submit]");
    const startVal = document.getElementById("workStart").value;
    const endVal = document.getElementById("workEnd").value;
    if (!startVal || !endVal) { alert("Başlangıç ve bitiş zamanı giriniz."); return; }

    const start = new Date(startVal);
    const end = new Date(endVal);
    if (end <= start) { alert("Bitiş zamanı başlangıçtan sonra olmalıdır."); return; }

    btn.disabled = true;
    try {
      await addDoc(collection(db, "neighborhood_works"), {
        category: document.getElementById("workCategory").value,
        title: document.getElementById("workTitle").value.trim(),
        description: document.getElementById("workDesc").value.trim(),
        neighborhood: document.getElementById("workNeighborhood").value,
        address: document.getElementById("workAddress").value.trim(),
        unit: document.getElementById("workUnit").value.trim(),
        startDate: Timestamp.fromDate(start),
        endDate: Timestamp.fromDate(end),
        createdAt: serverTimestamp()
      });
      e.target.reset();
      showToast("Mahalle saha çalışması kaydedildi!");
      loadWorks();
      loadDashboard();
    } catch (err) { alert(err.message); }
    finally { btn.disabled = false; }
  });
}

// DOM Hazırlık Kontrolü
if (document.readyState === 'loading') {
  document.addEventListener("DOMContentLoaded", initFormListeners);
} else {
  initFormListeners();
}

console.log("Gebze Dijital Yönetim Portalı Core JS yüklendi ve hazır.");
