// login.js

import { initializeApp } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-app.js";
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-auth.js";

// Firebase config
const firebaseConfig = {
    apiKey: "AIzaSyD8aaeQI_Umy-4Vm3sv86T9-kND12bvbOg",
    authDomain: "elestir-gelistir-web.firebaseapp.com",
    projectId: "elestir-gelistir-web",
    storageBucket: "elestir-gelistir-web.firebasestorage.app",
    messagingSenderId: "590820548557",
    appId: "1:590820548557:web:3cde5d0da928d043136e84"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

// Register form submission
const registerForm = document.getElementById('register-form');
registerForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    
    const username = document.getElementById('register-username').value;
    const email = document.getElementById('register-email').value;
    const password = document.getElementById('register-password').value;

    try {
        const userCredential = await createUserWithEmailAndPassword(auth, email, password);
        alert("Kayıt başarılı!");
        
        // Formu sıfırlıyoruz
        registerForm.reset(); 

        // Yönlendirme işlemi
        setTimeout(() => {
            window.location.href = "login.html";  // Yönlendirme
        }, 1000);  // 1 saniye gecikme
    } catch (error) {
        alert("Kayıt sırasında hata oluştu: " + error.message);
    }
});

// Login form submission
const loginForm = document.getElementById('login-form');
loginForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;

    try {
        const userCredential = await signInWithEmailAndPassword(auth, email, password);
        alert("Giriş başarılı!");
        
        // Formu sıfırlıyoruz
        loginForm.reset(); 

        // Yönlendirme işlemi
        setTimeout(() => {
            window.location.href = "index.html";  // Giriş yaptıktan sonra index.html'e yönlendir
        }, 1000);  // 1 saniye gecikme
    } catch (error) {
        alert("Giriş sırasında hata oluştu: " + error.message);
    }
});

// Toggle between login and register forms
const container = document.querySelector('.container');
const registerBtn = document.querySelector('.register-btn');
const loginBtn = document.querySelector('.login-btn');

registerBtn.addEventListener('click', () => {
    container.classList.add('active');
});

loginBtn.addEventListener('click', () => {
    container.classList.remove('active');
});

// Çıkış yapma işlemi
logoutLink.addEventListener('click', async (event) => {
  event.preventDefault();

  const auth = getAuth();

  try {
      await signOut(auth);  // Firebase'den çıkış yap
      alert("Çıkış yapıldı!");  // Basit alert test mesajı

      // Çıkış sonrası durumu kontrol et
      if (auth.currentUser === null) {
          console.log('Başarıyla çıkış yapıldı');
      }

      // Kullanıcıyı login sayfasına yönlendir
      window.location.href = "login.html";
  } catch (error) {
      alert("Çıkış sırasında hata oluştu: " + error.message);
  }
});



