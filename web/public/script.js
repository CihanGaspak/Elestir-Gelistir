import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import { getAuth, signOut } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";
import { getFirestore, collection, addDoc, getDocs, serverTimestamp, query, orderBy } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

// Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.firebasestorage.app",
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018",
  measurementId: "G-4QNGS9HE61"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

// Çıkış işlemi
document.getElementById("logout-link").addEventListener("click", function (e) {
  e.preventDefault();
  signOut(auth)
    .then(() => {
      window.location.href = "login.html";
    })
    .catch((error) => {
      console.error("Çıkış hatası:", error);
    });
});

// Ayarlar menüsü
const settingsmenu = document.querySelector(".settings-menu");
const darkBtn = document.getElementById("dark-btn");

function settingsMenuToggle() {
  settingsmenu.classList.toggle("settings-menu-height");
}

document.querySelectorAll('.settings-menu-btn').forEach(btn => {
  btn.addEventListener('click', function (event) {
    event.preventDefault();
    settingsMenuToggle();
  });
});

document.addEventListener('click', function (event) {
  const settingsMenus = document.querySelectorAll('.settings-menu');
  settingsMenus.forEach(menu => {
    if (!menu.contains(event.target) && !menu.previousElementSibling.contains(event.target)) {
      menu.classList.remove('settings-menu-height');
    }
  });
});

// Tema
darkBtn.onclick = function () {
  darkBtn.classList.toggle("dark-btn-on");
  document.body.classList.toggle("dark-theme");

  if (localStorage.getItem("theme") == "light") {
    localStorage.setItem("theme", "dark");
  } else {
    localStorage.setItem("theme", "light");
  }
}

if (localStorage.getItem("theme") == "light") {
  darkBtn.classList.remove("dark-btn-on");
  document.body.classList.remove("dark-theme");
} else if (localStorage.getItem("theme") == "dark") {
  darkBtn.classList.add("dark-btn-on");
  document.body.classList.add("dark-theme");
} else {
  localStorage.setItem("theme", "light");
}

// ---------------------- GÖNDERİ EKLEME -----------------------
document.addEventListener("DOMContentLoaded", () => {
  const textarea = document.querySelector("textarea");
  const sendBtn = document.createElement("button");
  sendBtn.textContent = "Gönder";
  sendBtn.className = "btn";
  sendBtn.style.marginTop = "10px";
  textarea.parentNode.appendChild(sendBtn);

  sendBtn.addEventListener("click", async () => {
    const text = textarea.value.trim();
    if (!text) return alert("Lütfen bir içerik girin!");

    try {
      await addDoc(collection(db, "posts"), {
        title: text,
        author: "Cihan Gaspak",
        category: "gundelik",
        tags: ["etiket"],
        image: "",
        date: serverTimestamp(),
        likes: 0,
        comments: 0,
        views: 0
      });

      textarea.value = "";
      loadPosts();
    } catch (err) {
      console.error("Post eklenemedi:", err);
      alert("Gönderi eklenemedi.");
    }
  });
});

// ---------------------- POSTLARI FIRESTORE'DAN YÜKLE -----------------------
async function loadPosts() {
  const postContainer = document.querySelector('.posts-container');
  postContainer.innerHTML = "";

  const q = query(collection(db, "posts"), orderBy("date", "desc"));
  const querySnapshot = await getDocs(q);

  querySnapshot.forEach((doc) => {
    const post = doc.data();
    const date = post.date?.toDate() || new Date();
    const formattedDate = date.toLocaleDateString('tr-TR', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });

    const postElement = document.createElement('div');
    postElement.classList.add('post-container');
    postElement.setAttribute("data-category", post.category);

    postElement.innerHTML = `
      <div class="post-row">
        <div class="user-profile">
          <img src="images/profile-pic.png">
          <div>
            <p>${post.author}</p>
            <span>${formattedDate}</span>
          </div>
        </div>
      </div>
      <p class="post-text">${post.title}</p>
    `;

    postContainer.appendChild(postElement);
  });
}

window.onload = loadPosts;

// ---------------------- FİLTRELEME -----------------------
function filterPosts(category) {
  const posts = document.querySelectorAll('.post-container');
  const buttons = document.querySelectorAll('.filter-button');

  buttons.forEach(button => button.classList.remove('active'));
  event.target.classList.add('active');

  posts.forEach(post => {
    if (category === 'all') {
      post.style.display = "block";
    } else {
      post.style.display = post.dataset.category === category ? "block" : "none";
    }
  });
}
