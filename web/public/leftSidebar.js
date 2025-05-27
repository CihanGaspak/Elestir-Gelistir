import { initializeApp, getApps } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import {
  getFirestore,
  collection,
  getDocs
} from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

// Firebase yapılandırması
const firebaseConfig = {
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.appspot.com",
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018"
};

// Firebase başlat
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
const db = getFirestore(app);

// Filtreleme fonksiyonu
window.applyFilters = async function () {
  const selectedCategory = document.getElementById("filter-category")?.value;
  const minLikes = parseInt(document.getElementById("filter-likes")?.value || "0");
  const selectedStep = parseInt(document.getElementById("filter-step")?.value || "0");

  const snapshot = await getDocs(collection(db, "posts"));
  const filteredPosts = snapshot.docs.filter(doc => {
    const data = doc.data();

    if (selectedCategory && data.category !== selectedCategory) return false;
    if ((data.likesCount || 0) < minLikes) return false;
    if (selectedStep && data.progressStep !== selectedStep) return false;

    return true;
  });

  const postFeed = document.getElementById("post-feed");
  postFeed.innerHTML = "";

  if (filteredPosts.length === 0) {
    postFeed.innerHTML = `
      <div class="empty-message">
        <img src="assets/no-posts.png">
        <h3>Oops! 🤷‍♂️</h3>
        <p>Bu filtreye uygun bir gönderi bulunamadı.</p>
      </div>
    `;
    return;
  }

  filteredPosts.forEach(doc => {
    const data = doc.data();
    const postCard = `
      <div class="post-card">
        <div class="post-header">
          <img src="${data.authorPhotoUrl || 'assets/avatars/avatar1.png'}" class="avatar" alt="Avatar">
          <div>
            <p class="author-name">${data.authorName || 'Kullanıcı'}</p>
            <p class="post-date">${new Date(data.date?.seconds * 1000).toLocaleDateString("tr-TR")}</p>
          </div>
        </div>
        <div class="post-content"><p>${data.content || '...'}</p></div>
        <div class="step-section">
          <div class="step-title">💡 Eleştir</div>
          <div class="step-body">${data.progressStep >= 1 ? (data.step1Note || 'Henüz not girilmemiş.') : 'Henüz bu aşamaya geçilmedi.'}</div>
          <div class="step-title">🛠 Düşündür</div>
          <div class="step-body">${data.progressStep >= 2 ? (data.step2Note || 'Henüz not girilmemiş.') : 'Henüz bu aşamaya geçilmedi.'}</div>
          <div class="step-title">✅ Geliştir</div>
          <div class="step-body">${data.progressStep >= 3 ? (data.step3Note || 'Henüz not girilmemiş.') : 'Henüz bu aşamaya geçilmedi.'}</div>
        </div>
        <div class="post-meta" style="margin-top: 10px; font-size: 13px; color: #555;">
          <span><b>Kategori:</b> ${data.category}</span> |
          <span><b>Beğeni:</b> ${data.likesCount || 0}</span> |
          <span><b>Aşama:</b> ${data.progressStep}</span>
        </div>
      </div>
    `;
    postFeed.insertAdjacentHTML("beforeend", postCard);
  });
};
