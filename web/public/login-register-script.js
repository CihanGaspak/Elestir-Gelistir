// Firebase modüllerini al
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";
import { getFirestore, doc, setDoc } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

// Firebase yapılandırması
const firebaseConfig = {
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.firebasestorage.app",
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018",
  measurementId: "G-4QNGS9HE61"
};

// Firebase'i başlat
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app); // Firestore'u başlat

// Giriş işlemi
document.getElementById("login-form").addEventListener("submit", function (e) {
  e.preventDefault();
  const email = document.getElementById("login-email").value;
  const password = document.getElementById("login-password").value;

  signInWithEmailAndPassword(auth, email, password)
    .then((userCredential) => {
      alert("Giriş başarılı!");
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
      // Kullanıcı adını Firestore'da "users" koleksiyonunda user.uid ile kayıt et
      return setDoc(doc(db, "users", user.uid), {
        username: username,
        email: email
      }).then(() => {
        alert("Kayıt başarılı!");
        window.location.href = "login.html";
      });
    })
    .catch((error) => {
      alert("Kayıt hatası: " + error.message);
    });
});
