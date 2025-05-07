import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import { getAuth, onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";

// Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.appspot.com",
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

// Navbar HTML dosyasını yükle
fetch("navbar.html")
  .then(res => res.text())
  .then(html => {
    document.getElementById("navbar-placeholder").innerHTML = html;

    // Toggle dropdown
    window.toggleDropdown = function () {
      const dropdown = document.getElementById("dropdown");
      dropdown?.classList.toggle("show");
    };

    // Logout
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

    // Dışarı tıklanınca menüyü kapat
    document.addEventListener("click", function (e) {
      const menu = document.querySelector(".profile-menu");
      if (!menu?.contains(e.target)) {
        document.getElementById("dropdown")?.classList.remove("show");
      }
    });

    // Auth kullanıcı yüklendiğinde profil bilgilerini güncelle
    onAuthStateChanged(auth, (user) => {
      if (user) {
        const profileLink = document.getElementById("profile-link");
        const profilePic = document.getElementById("profilePic");

        if (profileLink) {
          profileLink.href = `profile.html?uid=${user.uid}`;
        }

        if (profilePic && user.photoURL) {
          profilePic.src = user.photoURL;
        }
      }
    });
  })
  .catch(error => {
    console.error("Navbar yüklenemedi:", error);
  });
