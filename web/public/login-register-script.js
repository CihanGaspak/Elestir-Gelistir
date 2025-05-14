// Firebase modüllerini al
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import {
  getFirestore,
  doc,
  setDoc,
  serverTimestamp // BU EKLENDİ
} from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";
import {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword
} from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";

// Firebase yapılandırması
const firebaseConfig = {
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.appspot.com", // düzeltildi
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018"
};

// Firebase'i başlat
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

// Sayfa yüklendiğinde form geçişlerini ayarla
document.addEventListener("DOMContentLoaded", () => {
  const container = document.querySelector(".container");
  const registerBtn = document.querySelector(".register-btn");
  const loginBtn = document.querySelector(".login-btn");

  registerBtn?.addEventListener("click", () => container.classList.add("active"));
  loginBtn?.addEventListener("click", () => container.classList.remove("active"));
});

// Giriş işlemi
document.getElementById("login-form").addEventListener("submit", function (e) {
  e.preventDefault();
  const email = document.getElementById("login-email").value;
  const password = document.getElementById("login-password").value;

  signInWithEmailAndPassword(auth, email, password)
    .then(() => {
      window.location.href = "index.html";
    })
    .catch((error) => {
      alert("Giriş hatası: " + error.message);
    });
});

// Kayıt işlemi
document.getElementById("register-form").addEventListener("submit", function (e) {
  e.preventDefault();
  const username = document.getElementById("register-username").value;
  const email = document.getElementById("register-email").value;
  const password = document.getElementById("register-password").value;

  createUserWithEmailAndPassword(auth, email, password)
    .then((userCredential) => {
      const user = userCredential.user;
      return setDoc(doc(db, "users", user.uid), {
        uid: user.uid,
        username: username,
        email: email,
        photoUrl: "assets/avatars/avatar1.png",
        joinedAt: serverTimestamp(),
        usefulness: 0.0,
      });
    })
    .then(() => {
      window.location.href = "index.html"; // ✅ Direkt giriş sonrası index.html'e yönlendirme
    })
    .catch((error) => {
      alert("Kayıt hatası: " + error.message);
    });
});
