import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import { getAuth, signOut } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";
import {
  getFirestore,
  collection,
  addDoc,
  getDocs,
  serverTimestamp,
  query,
  orderBy
} from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

// Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.firebasestorage.app",
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018"
};

// Firebase başlat
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

// Çıkış işlemi
const logoutLink = document.getElementById("logout-link");
if (logoutLink) {
  logoutLink.addEventListener("click", (e) => {
    e.preventDefault();
    signOut(auth).then(() => window.location.href = "login.html");
  });
}

// Gönderi ekleme
document.addEventListener("DOMContentLoaded", () => {
  const textarea = document.querySelector("textarea");
  const sendBtn = document.createElement("button");
  sendBtn.textContent = "Gönder";
  sendBtn.className = "btn";
  sendBtn.style.marginTop = "10px";
  textarea.parentNode.appendChild(sendBtn);

  sendBtn.addEventListener("click", async () => {
    const text = textarea.value.trim();
    const category = document.getElementById("post-category")?.value || "gundelik";
    if (!text) return alert("Lütfen bir içerik girin!");

    const user = auth.currentUser;
    if (!user) return alert("Gönderi paylaşmak için giriş yapmalısınız!");

    try {
      await addDoc(collection(db, "posts"), {
        title: text,
        authorName: user.userName || "Anonim",
        authorUid: user.uid,
        authorPhotoUrl: user.photoURL || "assets/avatars/avatar0.png",
        category,
        dailyPick: false,
        tags: ["etiket"],
        image: "",
        date: serverTimestamp(),
        likes: 0,
        comments: 0,
        views: 0,
        progressStep: 0
      });
      textarea.value = "";
      loadPosts();
    } catch (err) {
      console.error("Post eklenemedi:", err);
    }
  });

  loadPosts();
});

// Postları yükle
async function loadPosts() {
  const postContainer = document.querySelector(".posts-container");
  postContainer.innerHTML = "";

  const q = query(collection(db, "posts"), orderBy("date", "desc"));
  const snapshot = await getDocs(q);

  snapshot.forEach((docSnap) => {
    const post = docSnap.data();
    const date = post.date?.toDate() || new Date();
    const formattedDate = date.toLocaleString("tr-TR");

    const postElement = document.createElement("div");
    postElement.classList.add("post-container");
    postElement.setAttribute("data-category", post.category || "tum");

    postElement.innerHTML = `
      <div class="post-card" style="cursor:pointer;">
        <div class="post-header">
          <img src="${post.authorPhotoUrl || 'images/profile-pic.png'}" class="avatar" />
          <div class="author-info">
            <p class="author-name">${post.authorName || 'Kullanıcı'}</p>
            <p class="post-date">${formattedDate}</p>
          </div>
          <div class="progress-icons">
            <i class="fas fa-lightbulb ${post.progressStep >= 0 ? 'active' : ''}"></i>
            <i class="fas fa-tools ${post.progressStep >= 1 ? 'active' : ''}"></i>
            <i class="fas fa-check-circle ${post.progressStep >= 2 ? 'active' : ''}"></i>
          </div>
        </div>
        <div class="post-content"><p>${post.content || ''}</p></div>
        <div class="post-actions">
          <div class="action"><i class="far fa-thumbs-up"></i> <span>${post.likesCount || 0}</span></div>
          <div class="action"><i class="far fa-comment"></i> <span>${post.commentsCount || 0}</span></div>
          <div class="action"><i class="fa fa-share"></i></div>
          <div class="action"><i class="far fa-bookmark"></i></div>
        </div>
        <div class="step-section">
          <div class="step-title">💡 Eleştir</div>
          <div class="step-body hidden">${post.step1Note || 'Henüz bu aşamaya geçilmedi.'}</div>
          <div class="step-title">🛠 Düşündür</div>
          <div class="step-body hidden">${post.step2Note || 'Henüz bu aşamaya geçilmedi.'}</div>
          <div class="step-title">✅ Geliştir</div>
          <div class="step-body hidden">${post.step3Note || 'Henüz bu aşamaya geçilmedi.'}</div>
        </div>
      </div>`;

    postElement.querySelector(".post-card").addEventListener("click", () => {
      localStorage.setItem("selectedPost", JSON.stringify({ ...post, id: docSnap.id }));
      window.location.href = "post-detail.html";
    });

    postContainer.appendChild(postElement);
  });
}
