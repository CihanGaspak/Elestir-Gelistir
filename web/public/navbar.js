import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import { getAuth, onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";
import { getFirestore, doc, getDoc } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

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
const db = getFirestore(app);

// Navbar HTML dosyasını yükle
fetch("navbar.html")
  .then(res => res.text())
  .then(html => {
    document.getElementById("navbar-placeholder").innerHTML = html;


  // Arama kutusu işlevleri
const searchInput = document.getElementById("search-input");
const clearBtn = document.getElementById("clear-btn");
const searchHistoryDiv = document.getElementById("search-history");
const searchResultsUl = document.getElementById("search-results");

let searchHistory = JSON.parse(localStorage.getItem("userSearchHistory")) || [];
let allUsers = [];

// Geçmişi göster
function renderSearchHistory() {
  if (searchHistory.length === 0) {
    searchHistoryDiv.innerHTML = `<div style="padding: 8px 12px; color:#888;">Henüz arama geçmişiniz yok.</div>`;
    return;
  }

  searchHistoryDiv.innerHTML = searchHistory.map((term, index) => `
    <div class="history-item">
      <span onclick="searchUser('${term}')">
        <i class="fa fa-clock"></i> ${term}
      </span>
      <span class="history-remove" onclick="removeHistoryItem(${index})">Kaldır</span>
    </div>
  `).join("");
}

function addToHistory(term) {
  term = term.trim();
  if (!term) return;
  searchHistory = searchHistory.filter(t => t !== term);
  searchHistory.unshift(term);
  if (searchHistory.length > 5) searchHistory.pop();
  localStorage.setItem("userSearchHistory", JSON.stringify(searchHistory));
  renderSearchHistory();
}

window.removeHistoryItem = function(index) {
  searchHistory.splice(index, 1);
  localStorage.setItem("userSearchHistory", JSON.stringify(searchHistory));
  renderSearchHistory();
};

window.searchUser = function(term) {
  searchInput.value = term;
  clearBtn.style.display = "inline-block";
  searchUsersFromFirestore(term.toLowerCase());
};

searchInput.addEventListener("input", () => {
  const query = searchInput.value.trim().toLowerCase();
  clearBtn.style.display = query ? "inline-block" : "none";
  if (!query) {
    searchResultsUl.innerHTML = "";
    renderSearchHistory();
  } else {
    searchHistoryDiv.innerHTML = "";
    searchUsersFromFirestore(query);
  }
});

clearBtn.addEventListener("click", () => {
  searchInput.value = "";
  clearBtn.style.display = "none";
  searchResultsUl.innerHTML = "";
  renderSearchHistory();
});

document.addEventListener("click", function (e) {
  const wrapper = document.getElementById("search-container");
  if (!wrapper.contains(e.target)) {
    searchHistoryDiv.innerHTML = "";
    searchResultsUl.innerHTML = "";
  }
});

searchInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter") {
    const term = searchInput.value.trim();
    if (term) {
      addToHistory(term);
      searchUsersFromFirestore(term.toLowerCase());
    }
  }
});

async function searchUsersFromFirestore(query) {
  if (!allUsers.length) {
    const { getDocs, collection } = await import("https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js");
    const qSnapshot = await getDocs(collection(db, "users"));
    allUsers = qSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  }

  const users = allUsers.filter(user => user.username?.toLowerCase().includes(query));
  renderSearchResults(users);
}

function renderSearchResults(users) {
  if (users.length === 0) {
    searchResultsUl.innerHTML = `<li>Sonuç bulunamadı.</li>`;
    return;
  }

  searchResultsUl.innerHTML = "";

  users.forEach(user => {
    const li = document.createElement("li");
    const img = document.createElement("img");
    img.src = user.photoUrl || 'assets/avatars/avatar1.png';
    img.alt = "Avatar";

    const span = document.createElement("span");
    span.textContent = user.username || "(isimsiz)";

    li.appendChild(img);
    li.appendChild(span);

    li.addEventListener("click", () => {
  addToHistory(user.username);
  window.location.href = `profile.html?uid=${user.id}`;
});


    searchResultsUl.appendChild(li);
  });
}
const searchWrapper = document.getElementById("search-wrapper");


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

    // 🔥 Auth kullanıcı yüklendiğinde Firestore'dan kullanıcı bilgilerini çekip navbar'da göster
    onAuthStateChanged(auth, async (user) => {
      if (user) {
        const profileLink = document.getElementById("profile-link");
        const profilePic = document.getElementById("profilePic");

        if (profileLink) {
          profileLink.href = `profile.html?uid=${user.uid}`;
        }

        // Firestore'dan kullanıcı bilgisi çek
        try {
          const userSnap = await getDoc(doc(db, "users", user.uid));
          if (userSnap.exists()) {
            const userData = userSnap.data();
            if (profilePic) {
              profilePic.src = userData.photoUrl || 'assets/avatars/avatar1.png';
            }
          } else {
            console.warn("Kullanıcı Firestore'da bulunamadı.");
            if (profilePic) {
              profilePic.src = 'assets/avatars/avatar1.png';
            }
          }
        } catch (err) {
          console.error("Kullanıcı verisi çekilirken hata:", err);
          if (profilePic) {
            profilePic.src = 'assets/avatars/avatar1.png';
          }
        }
      }
    });
  })
  .catch(error => {
    console.error("Navbar yüklenemedi:", error);
  });



