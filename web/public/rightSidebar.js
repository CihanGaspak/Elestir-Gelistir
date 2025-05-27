console.log("✅ rightSidebar.js çalıştı!");

import { initializeApp, getApps, getApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import {
  getFirestore,
  collection,
  query,
  orderBy,
  limit,
  getDocs
} from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

// Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.appspot.com",
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018"
};

const app = getApps().length ? getApp() : initializeApp(firebaseConfig);
const db = getFirestore(app);

// ⏱ Süre hesaplama
function zamanFarkiHesapla(tarih) {
  const simdi = new Date();
  const farkMs = simdi - tarih;

  const dakika = 60 * 1000;
  const saat = 60 * dakika;
  const gun = 24 * saat;
  const hafta = 7 * gun;
  const ay = 30 * gun;
  const yil = 365 * gun;

  if (farkMs < dakika) return "şimdi katıldı";
  if (farkMs < saat) return `${Math.floor(farkMs / dakika)} dk önce katıldı`;
  if (farkMs < gun) return `${Math.floor(farkMs / saat)} saat önce katıldı`;
  if (farkMs < hafta) return `${Math.floor(farkMs / gun)} gün önce katıldı`;
  if (farkMs < ay) return `${Math.floor(farkMs / hafta)} hafta önce katıldı`;
  if (farkMs < yil) return `${Math.floor(farkMs / ay)} ay önce katıldı`;
  return `${Math.floor(farkMs / yil)} yıl önce katıldı`;
}


// 👤 Yeni Katılanlar
async function loadRecentUsers() {
  const usersRef = collection(db, "users");
  const q = query(usersRef, orderBy("joinedAt", "desc"), limit(3));
  const snapshot = await getDocs(q);

  const list = document.getElementById("new-users");
  if (!list) return;
  list.innerHTML = "";

  snapshot.forEach(doc => {
    const user = doc.data();
    const avatar = user.photoUrl || "assets/avatars/avatar1.png";
    const username = user.username || "Kullanıcı";
    const joinedDateObj = user.joinedAt?.toDate?.();
    const relative = joinedDateObj ? zamanFarkiHesapla(joinedDateObj) : "Tarih yok";
  
    const li = document.createElement("li");
    li.innerHTML = `
      <a href="profile.html?uid=${doc.id}" style="text-decoration: none; color: inherit;">
        <div class="new-user-card">
          <img class="mini-avatar" src="${avatar}" alt="${username}" />
          <div class="new-user-info">
            <span>@${username}</span>
            <span>${relative}</span>
          </div>
        </div>
      </a>
    `;
    list.appendChild(li);
  });
}

// 🏆 En Çok Yardımcı Olanlar
async function loadTopHelpers() {
  const helpersList = document.getElementById("top-helpers");
  if (!helpersList) return;
  helpersList.innerHTML = "";

  const q = query(collection(db, "users"), orderBy("usefulness", "desc"), limit(3));
  const snapshot = await getDocs(q);

  snapshot.forEach((doc) => {
    const user = doc.data();
    const avatar = user.photoUrl || "assets/avatars/avatar1.png";
    const username = user.username || "Kullanıcı";
    const usefulness = user.usefulness ?? "0";

    const li = document.createElement("li");
    li.innerHTML = `
  <a href="profile.html?uid=${doc.id}" style="text-decoration: none; color: inherit;">
    <div class="helper-card">
      <img class="mini-avatar" src="${avatar}" alt="${username}" />
      <span class="helper-username">@${username}</span>
      <span class="helper-score">${usefulness}</span>
    </div>
  </a>
`;

    helpersList.appendChild(li);
  });
}

// 👴 Müdavimler
async function loadVeteranUsers() {
  const list = document.getElementById("veteran-users");
  if (!list) return;
  list.innerHTML = "";

  const q = query(collection(db, "users"), orderBy("joinedAt", "asc"), limit(3));
  const snapshot = await getDocs(q);

  snapshot.forEach((doc) => {
    const user = doc.data();
    const avatar = user.photoUrl || "assets/avatars/avatar1.png";
    const username = user.username || "Kullanıcı";
    const joinedDate = user.joinedAt?.toDate?.();
    const kacGunOnce = joinedDate
      ? `${Math.floor((Date.now() - joinedDate.getTime()) / (1000 * 60 * 60 * 24))} gündür üye`
      : "Bilinmiyor";
  
    const li = document.createElement("li");
    li.innerHTML = `
      <a href="profile.html?uid=${doc.id}" style="text-decoration: none; color: inherit;">
        <div class="veteran-card">
          <img class="mini-avatar" src="${avatar}" alt="${username}" />
          <div class="veteran-info">
            <span>@${username}</span>
            <span>${kacGunOnce}</span>
          </div>
        </div>
      </a>
    `;
    list.appendChild(li);
  });
  
}


// 📊 Popüler Kategoriler
async function loadPopularCategories() {
  const categoryCount = {};
  const snapshot = await getDocs(collection(db, "posts"));

  snapshot.forEach((doc) => {
    const data = doc.data();
    const cat = data.category || "Diğer";
    categoryCount[cat] = (categoryCount[cat] || 0) + 1;
  });

  // En çok kullanılan ilk 5 kategori
  const sortedCategories = Object.entries(categoryCount)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  const categoryIcons = {
    "Eğitim": "🎓",
    "Spor": "🏋️",
    "Tamirat": "🛠",
    "Araç Bakım": "🚗",
    "Sağlık": "🩺",
    "Teknoloji": "💻",
    "Kişisel Gelişim": "📘",
    "Sanat": "🎨",
    "Yazılım": "👨‍💻",
    "Diğer": "📌"
  };

  const container = document.getElementById("popular-categories");
  if (!container) return;

  container.innerHTML = "";

  sortedCategories.forEach(([category, count]) => {
    const icon = categoryIcons[category] || "📌";
    const li = document.createElement("li");
    li.innerHTML = `${icon} ${category} <small>(${count})</small>`;
    container.appendChild(li);
  });
}

// Çalıştır
const interval = setInterval(() => {
  const container = document.getElementById("new-users");
  if (container) {
    clearInterval(interval);
    loadRecentUsers();
    loadTopHelpers();
    loadVeteranUsers();
    loadPopularCategories();
  }
}, 100);
