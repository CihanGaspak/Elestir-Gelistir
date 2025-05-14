// postDetail.js
import { db, auth } from './firebase.js';
import { doc, getDoc, updateDoc, increment, collection, getDocs, query, orderBy, addDoc } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";
import { onAuthStateChanged } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";

document.addEventListener("DOMContentLoaded", () => {
  const postId = new URLSearchParams(window.location.search).get("id");
  if (!postId) return alert("Post ID bulunamadı!");

  const postRef = doc(db, "posts", postId);
  let currentUser = null;
  let currentPost = null;
  let comments = [];

  onAuthStateChanged(auth, async (user) => {
    currentUser = user;
    if (user) {
      await updateDoc(postRef, { views: increment(1) });
      await refreshPostPage();
    }
  });

  async function refreshPostPage() {
    await loadPost();
    renderPost();
    renderSteps();
    await loadComments();
  }

  async function loadPost() {
    const snap = await getDoc(postRef);
    if (!snap.exists()) return document.getElementById("post-container").innerHTML = "<div>Gönderi bulunamadı!</div>";
    currentPost = snap.data();
    renderPost();
  }

  async function renderPost() {
  const post = currentPost;
  const uid = currentUser.uid;
  const isLiked = post.likedBy?.includes(uid);
  const isSaved = post.savedBy?.includes(uid);

  let authorData = { username: "Kullanıcı", photoUrl: "assets/avatars/avatar1.png" };
  try {
    const userSnap = await getDoc(doc(db, "users", post.authorId));
    if (userSnap.exists()) {
      authorData = userSnap.data();
    }
  } catch (e) {
    console.error("Yazar bilgisi alınamadı:", e);
  }

  document.getElementById("post-container").innerHTML = `
    <div style="display: flex; align-items: center;">
      <img src="${authorData.photoUrl}" style="width: 40px; height: 40px; border-radius: 50%; object-fit: cover;">
      <div style="margin-left: 10px;">
        <div style="font-weight: bold; font-size: 16px;">${authorData.username}</div>
        <div style="font-size: 12px; color: gray;">${timeAgo(new Date(post.date?.seconds * 1000))}</div>
      </div>
      <div style="margin-left: auto; padding: 8px 12px; background: #FFF3E0; border-radius: 12px;">
        <div style="display: flex; gap: 4px;">
          ${[0,1,2].map(i => `
            <i class="${getStepIconClass(i)}" style="color: ${i <= post.progressStep ? 'orange' : '#DDD'};"></i>
          `).join('')}
        </div>
        <div style="display: flex; align-items: center; margin-top: 4px;">
          <i class="${getCategoryIconClass(post.category)}" style="color: black; font-size: 16px;"></i>
          <span style="margin-left: 4px; font-size: 12px; color: black;">${capitalize(post.category)}</span>
        </div>
      </div>
    </div>
    <div style="margin:20px 0;">${post.content}</div>
    <div class="actions">
      <span id="likeBtn" style="cursor:pointer;"><i class="${isLiked ? 'fas' : 'far'} fa-thumbs-up" style="color:${isLiked ? 'orange' : 'black'};"></i> ${post.likesCount || 0}</span>
      <span><i class="far fa-comment"></i> <span id="commentCount">${post.commentsCount || 0}</span></span>
      <span id="saveBtn" style="cursor:pointer;"><i class="${isSaved ? 'fas' : 'far'} fa-bookmark" style="color:${isSaved ? 'orange' : 'black'};"></i></span>
      <span id="shareBtn" style="cursor:pointer;"><i class="fas fa-share"></i></span>
      <span><i class="far fa-eye"></i> ${post.views || 0}</span>
    </div>
    <div id="steps" style="margin-top: 20px;"></div>
    <h3>Yorum Yap</h3>
    <textarea id="commentInput" rows="3" maxlength="140" placeholder="Yorum yaz..."></textarea>
    <div style="display:flex; justify-content:space-between; margin-top:8px;">
      <span id="charCount">0 / 140</span>
      <button id="sendCommentBtn" disabled>Gönder</button>
    </div>
    <h3>Yorumlar</h3>
    <div id="comments"></div>
  `;

  document.getElementById("likeBtn").onclick = toggleLike;
  document.getElementById("saveBtn").onclick = toggleSave;
  document.getElementById("shareBtn").onclick = () => {
    navigator.clipboard.writeText(window.location.href);
    alert("Bağlantı panoya kopyalandı!");
  };
  document.getElementById("sendCommentBtn").onclick = sendComment;
  document.getElementById("commentInput").addEventListener("input", e => {
    document.getElementById("charCount").innerText = `${e.target.value.length} / 140`;
    document.getElementById("sendCommentBtn").disabled = e.target.value.trim().length === 0;
  });

  renderSteps();
}
 function renderSteps() {
  const post = currentPost;
  if (!post) return;

  const step = post.progressStep ?? 0;
  const isOwner = currentUser?.uid === post.authorId;

  const titles = ["Eleştir", "Düşün", "Geliştir"];
  const icons = ["fas fa-lightbulb", "fas fa-tools", "fas fa-check-circle"];

  const stepsEl = document.getElementById("steps");
  if (!stepsEl) return;

  stepsEl.innerHTML = titles.map((t, i) => {
    // i = 0 ➡️ Eleştir, i = 1 ➡️ Düşün, i = 2 ➡️ Geliştir
    // step === 0 ➡️ sadece Eleştir gösterilmeli, diğerleri gri
    const isStepReached = step >= i;

    if (isOwner) {
      if (isStepReached) {
        return `
          <div class="step-card">
            <div style="display:flex;justify-content:space-between;align-items:center;">
              <h4><i class="${icons[i]}" style="color:orange;"></i> ${t}</h4>
              <button onclick="editNote(${i})">Düzenle</button>
            </div>
            <p id="note-${i}">${post[`step${i + 1}Note`] || "Not eklenmemiş."}</p>
          </div>
        `;
      } else {
        return `
          <div class="step-card">
            <div style="display:flex;justify-content:space-between;align-items:center;">
              <h4><i class="${icons[i]}" style="color:gray;"></i> Henüz bu aşamaya geçilmedi</h4>
            </div>
          </div>
        `;
      }
    } else {
      if (isStepReached) {
        return `
          <div class="step-card">
            <div style="display:flex;justify-content:space-between;align-items:center;">
              <h4><i class="${icons[i]}" style="color:orange;"></i> ${t}</h4>
            </div>
            <p id="note-${i}">${post[`step${i + 1}Note`] || "Not eklenmemiş."}</p>
          </div>
        `;
      } else {
        return `
          <div class="step-card">
            <div style="display:flex;justify-content:space-between;align-items:center;">
              <h4><i class="${icons[i]}" style="color:gray;"></i> Henüz bu aşamaya geçilmedi</h4>
            </div>
          </div>
        `;
      }
    }
  }).join('');
}


  window.editNote = async function (i) {
    const oldNote = currentPost[`step${i + 1}Note`] || "";
    const newNote = prompt(`"${["Eleştir", "Düşün", "Geliştir"][i]}" Notunu Güncelle:`, oldNote);
    if (newNote === null) return;

    let newProgress = currentPost.progressStep || 0;
    if (newNote && newProgress < i + 1) {
      newProgress = i + 1;
    }

    await updateDoc(postRef, {
      [`step${i + 1}Note`]: newNote,
      progressStep: newProgress
    });

    await refreshPostPage();  // ✅ Merkezden her şeyi tazele
  };

  async function toggleLike() {
    const uid = currentUser.uid;
    const isLiked = currentPost.likedBy?.includes(uid);

    const updatedLikedBy = isLiked
      ? currentPost.likedBy.filter(u => u !== uid)
      : [...(currentPost.likedBy || []), uid];

    const updatedLikesCount = (currentPost.likesCount || 0) + (isLiked ? -1 : 1);

    await updateDoc(postRef, {
      likedBy: updatedLikedBy,
      likesCount: updatedLikesCount
    });

    // Local güncelle
    currentPost.likedBy = updatedLikedBy;
    currentPost.likesCount = updatedLikesCount;

    // Yalnızca buton UI'ı güncelle
    document.getElementById("likeBtn").innerHTML = `
      <i class="${updatedLikedBy.includes(uid) ? 'fas' : 'far'} fa-thumbs-up" style="color:${updatedLikedBy.includes(uid) ? 'orange' : 'black'};"></i> ${updatedLikesCount}
    `;
}

async function toggleSave() {
    const uid = currentUser.uid;
    const isSaved = currentPost.savedBy?.includes(uid);

    const updatedSavedBy = isSaved
      ? currentPost.savedBy.filter(u => u !== uid)
      : [...(currentPost.savedBy || []), uid];

    await updateDoc(postRef, { savedBy: updatedSavedBy });

    // Local güncelle
    currentPost.savedBy = updatedSavedBy;

    // Yalnızca buton UI'ı güncelle
    document.getElementById("saveBtn").innerHTML = `
      <i class="${updatedSavedBy.includes(uid) ? 'fas' : 'far'} fa-bookmark" style="color:${updatedSavedBy.includes(uid) ? 'orange' : 'black'};"></i>
    `;
}


  async function loadComments() {
    const snap = await getDocs(query(collection(postRef, "comments"), orderBy("date", "desc")));
    comments = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    renderComments();
  }

  async function renderComments() {
  const container = document.getElementById("comments");
  container.innerHTML = comments.length === 0 ? "<div>Henüz yorum yok.</div>" : "";

  for (const c of comments) {
    let authorData = { username: "Kullanıcı", photoUrl: "assets/avatars/avatar1.png" };
    try {
      const userSnap = await getDoc(doc(db, "users", c.authorId));
      if (userSnap.exists()) {
        authorData = userSnap.data();
      }
    } catch (e) {
      console.error("Yorum yazar bilgisi alınamadı:", e);
    }

    const isLiked = c.likedBy?.includes(currentUser.uid);

    container.innerHTML += `
      <div class="comment" id="comment-${c.id}" style="
        display:flex; 
        justify-content:space-between; 
        align-items:center; 
        background:#fff; 
        border-radius:12px; 
        padding:12px 16px; 
        margin-bottom:12px; 
        box-shadow:0 2px 8px rgba(0,0,0,0.05);">
        
        <div style="display:flex; align-items:flex-start; gap:12px; flex-grow:1;">
          <img src="${authorData.photoUrl}" style="width:40px;height:40px; border-radius:50%; object-fit:cover;">
          <div>
            <div style="display:flex; align-items:center; gap:6px; font-weight:600; font-size:14px;">
              ${authorData.username} 
              <span style="color:#999; font-size:12px;">${timeAgo(new Date(c.date.seconds * 1000))}</span>
            </div>
            <div style="font-size:15px; margin-top:4px;">${c.text}</div>
          </div>
        </div>
        
        <div id="like-btn-${c.id}" style="cursor:pointer; display:flex; align-items:center; gap:4px; font-size:15px;" onclick="toggleCommentLike('${c.id}')">
          <i class="${isLiked ? 'fas' : 'far'} fa-heart" style="color:${isLiked ? 'orange' : '#ccc'};"></i> ${c.likedBy?.length || 0}
        </div>
      </div>
    `;
  }
}


  window.toggleCommentLike = async function (cid) {
    const ref = doc(postRef, "comments", cid);
    const snap = await getDoc(ref);
    if (!snap.exists()) return;
    let data = snap.data();
    let likedBy = data.likedBy || [];
    let isLiked = likedBy.includes(currentUser.uid);

    if (isLiked) {
      likedBy = likedBy.filter(uid => uid !== currentUser.uid);
    } else {
      likedBy.push(currentUser.uid);
    }

    await updateDoc(ref, { likedBy });

    const likeBtn = document.getElementById(`like-btn-${cid}`);
    if (likeBtn) {
      likeBtn.innerHTML = `<i class="${isLiked ? 'far' : 'fas'} fa-heart" style="color:${isLiked ? 'gray' : 'orange'};"></i> ${likedBy.length}`;
    }
  };

  async function sendComment() {
  const text = document.getElementById("commentInput").value.trim();
  if (!text) return;

  try {
    // Yorum ekle
    await addDoc(collection(postRef, "comments"), {
      text,
      date: new Date(),
      authorId: currentUser.uid,
      likedBy: []
    });

    // İlerleme 1 yap (eğer daha düşükse)
    if ((currentPost.progressStep || 0) < 1) {
      await updateDoc(postRef, { progressStep: 1 });
    }

    // 🔥 Yorum sayısını +1 artır (Firestore güvenli yöntem)
    await updateDoc(postRef, {
      commentsCount: increment(1)
    });

    document.getElementById("commentInput").value = "";
    await loadComments();
  } catch (error) {
    console.error("Yorum eklenirken hata:", error);
  }
}


  function timeAgo(date) {
    const now = new Date();
    const seconds = Math.floor((now - date) / 1000);
    const intervals = [[31536000, "yıl"], [2592000, "ay"], [86400, "gün"], [3600, "saat"], [60, "dakika"]];
    for (const [secs, label] of intervals) {
      const interval = Math.floor(seconds / secs);
      if (interval >= 1) return `${interval} ${label} önce`;
    }
    return "Az önce";
  }

  function getCategoryIconClass(category) {
  switch ((category || '').toLowerCase()) {
    case 'tümü': return 'fas fa-infinity';
    case 'eğitim': return 'fas fa-graduation-cap';
    case 'spor': return 'fas fa-dumbbell';
    case 'tamirat': return 'fas fa-tools';
    case 'araç bakım': return 'fas fa-car';
    case 'sağlık': return 'fas fa-heartbeat';
    case 'teknoloji': return 'fas fa-laptop-code';
    case 'kişisel gelişim': return 'fas fa-user-graduate';
    case 'sanat': return 'fas fa-paint-brush';
    case 'yazılım': return 'fas fa-code';
    default: return 'fas fa-folder';
  }
}

function getStepIconClass(index) {
  switch (index) {
    case 0: return 'fas fa-lightbulb';
    case 1: return 'fas fa-tools';
    case 2: return 'fas fa-check-circle';
    default: return 'fas fa-question-circle';
  }
}

function capitalize(str) {
  return str && str.length ? str[0].toUpperCase() + str.slice(1).toLowerCase() : '';
}

});
