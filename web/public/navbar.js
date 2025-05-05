// Firebase App modülünü yükle
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import { getAuth, signOut } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";

// Firebase konfigürasyonu
const firebaseConfig = {
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.appspot.com",
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018"
};

// Firebase başlat
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

// navbar.html dosyasını yükle
fetch("navbar.html")
  .then(res => res.text())
  .then(html => {
    document.getElementById("navbar-placeholder").innerHTML = html;

    // Aç/kapat işlemi
    window.toggleDropdown = function () {
      const dropdown = document.getElementById("dropdown");
      dropdown?.classList.toggle("show");
    };

    // Çıkış işlemi
    window.logout = function () {
      signOut(auth)
        .then(() => {
          console.log("Çıkış başarılı.");
          window.location.href = "login.html";
        })
        .catch((error) => {
          console.error("Çıkış hatası:", error);
          alert("Çıkış yapılamadı.");
        });
    };

    // Menü dışında tıklanınca kapat
    document.addEventListener("click", function (e) {
      const menu = document.querySelector(".profile-menu");
      if (!menu?.contains(e.target)) {
        document.getElementById("dropdown")?.classList.remove("show");
      }
    });
  })
  .catch(error => {
    console.error("Navbar yüklenemedi:", error);
  });
