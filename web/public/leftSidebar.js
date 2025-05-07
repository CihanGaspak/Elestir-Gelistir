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

// 🔁 Yalnızca 1 kez initialize et
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
const db = getFirestore(app);

// Filtreleme işlemi
window.applyFilters = async function () {
  const showGelistir = document.getElementById("filter-gelistir").checked;
  const selectedCategory = document.getElementById("filter-category").value;
  const minLikes = parseInt(document.getElementById("filter-likes").value || "0");

  const snapshot = await getDocs(collection(db, "posts"));
  const filteredPosts = snapshot.docs.filter(doc => {
    const data = doc.data();
    if (showGelistir && data.progressStep < 3) return false;
    if (selectedCategory && data.category !== selectedCategory) return false;
    if ((data.likesCount || 0) < minLikes) return false;
    return true;
  });

  const postFeed = document.getElementById("post-feed");
  postFeed.innerHTML = "";
  filteredPosts.forEach(doc => {
    if (typeof generatePostHTML === "function") {
      postFeed.innerHTML += generatePostHTML(doc.data(), doc.id, "");
    }
  });
};
