// postDetail.js
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import {
  getFirestore, doc, getDoc, updateDoc, increment, collection,
  getDocs, query, orderBy, addDoc
} from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";
import { getAuth, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";

const app = initializeApp({
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.appspot.com",
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018"
});

const db = getFirestore(app);
const auth = getAuth(app);
const postId = new URLSearchParams(window.location.search).get("id");
const postRef = doc(db, "posts", postId);
let currentUser = null;
let currentNoteIndex = 0;

onAuthStateChanged(auth, async (user) => {
  currentUser = user;
  if (postId && user) {
    await updateDoc(postRef, { views: increment(1) });
    loadPost();
    loadComments();
  }
});

async function loadPost() {
  const snap = await getDoc(postRef);
  if (!snap.exists()) return;
  const post = snap.data();
  const uid = currentUser.uid;

  document.getElementById("post-container").innerHTML = `
    <div class="header">
      <img src="${post.authorPhotoUrl}" class="avatar" />
      <div>
        <div style="font-weight: bold;">${post.authorName}</div>
        <div style="font-size: 12px; color: gray;">${new Date(post.date.seconds * 1000).toLocaleString("tr-TR")}</div>
      </div>
    </div>
    <div style="margin: 20px 0; font-size: 16px;">${post.content}</div>
    <div class="actions">
      <span id="likeBtn"><i class="${post.likedBy?.includes(uid) ? 'fas' : 'far'} fa-thumbs-up"></i> <span id="likeCount">${post.likesCount || 0}</span></span>
      <span><i class="far fa-comment"></i> <span id="commentCount">0</span></span>
      <span id="saveBtn"><i class="${post.savedBy?.includes(uid) ? 'fas' : 'far'} fa-bookmark"></i></span>
      <span><i class="fas fa-share"></i></span>
      <span><i class="far fa-eye"></i> <span id="viewCount">${(post.views || 0) + 1}</span></span>
    </div>
    <div id="steps"></div>
    <h3>Yorum Yap</h3>
    <textarea id="commentInput" rows="3" maxlength="140" placeholder="Yorum yaz..."></textarea>
    <div style="display:flex; justify-content:space-between; margin-top:8px;">
      <span id="charCount">0 / 140</span>
      <button id="sendCommentBtn" disabled>Gönder</button>
    </div>
    <br />
    <h3>Yorumlar</h3>
    <div id="comments"></div>`;

  document.getElementById("likeBtn").onclick = async () => {
    const liked = post.likedBy || [];
    const isLiked = liked.includes(uid);
    const newLiked = isLiked ? liked.filter(u => u !== uid) : [...liked, uid];
    await updateDoc(postRef, {
      likedBy: newLiked,
      likesCount: increment(isLiked ? -1 : 1)
    });
    loadPost();
  };

  document.getElementById("saveBtn").onclick = async () => {
    const saved = post.savedBy || [];
    const isSaved = saved.includes(uid);
    const newSaved = isSaved ? saved.filter(u => u !== uid) : [...saved, uid];
    await updateDoc(postRef, {
      savedBy: newSaved
    });
    loadPost();
  };

  document.querySelector(".fa-share").parentElement.onclick = () => {
    const url = window.location.href;
    navigator.clipboard.writeText(url);
    alert("Bağlantı panoya kopyalandı!");
  };

  const steps = document.getElementById("steps");
  const titles = ["Eleştir", "Düşün", "Geliştir"];
  const step = post.progressStep || 0;
  const isOwner = uid === post.authorId;
  steps.innerHTML = titles.map((t, i) => `
    <div class="step-card ${isOwner && step >= i ? 'editable' : ''}">
      <div style="display:flex;justify-content:space-between;align-items:center;">
        <strong>${step >= i ? t : "Henüz bu aşamaya geçilmedi"}</strong>
        ${isOwner && step >= i ? `<button onclick="editNote(${i})">Düzenle</button>` : ''}
      </div>
      ${step >= i ? `<p id="note-${i}">${post[`step${i + 1}Note`] || "Not eklenmemiş."}</p>` : ''}
    </div>`).join('');

  document.getElementById("commentInput").addEventListener("input", e => {
    const val = e.target.value.trim();
    document.getElementById("charCount").textContent = `${val.length} / 140`;
    document.getElementById("sendCommentBtn").disabled = val.length === 0;
  });

  document.getElementById("sendCommentBtn").addEventListener("click", async () => {
    const text = document.getElementById("commentInput").value.trim();
    const userSnap = await getDoc(doc(db, "users", currentUser.uid));
    const user = userSnap.data();
    await addDoc(collection(postRef, "comments"), {
      text,
      authorId: currentUser.uid,
      authorName: user.username || "Kullanıcı",
      authorPhotoUrl: user.photoUrl || "",
      date: new Date(),
      likedBy: []
    });

    await updateDoc(postRef, {
      commentsCount: increment(1)
    });

    loadComments();
    document.getElementById("commentInput").value = "";
    document.getElementById("charCount").textContent = "0 / 140";
    document.getElementById("sendCommentBtn").disabled = true;
  });
}

async function loadComments() {
    const q = query(collection(postRef, "comments"), orderBy("date", "desc"));
    const snap = await getDocs(q);
    document.getElementById("commentCount").textContent = snap.size;
  
    const container = document.getElementById("comments");
    container.innerHTML = "";
  
    snap.forEach(docSnap => {
      const c = docSnap.data();
      const cid = docSnap.id;
      const date = new Date(c.date.seconds * 1000).toLocaleString("tr-TR");
      const likedBy = c.likedBy || [];
      const isLiked = currentUser && likedBy.includes(currentUser.uid);
      const likeCount = likedBy.length;
  
      container.innerHTML += `
        <div class="comment" data-id="${cid}">
          <div class="top">
            <img src="${c.authorPhotoUrl}" class="avatar" />
            <div>
              <div style="font-weight:bold;">${c.authorName}</div>
              <div style="font-size:12px;color:gray;">${date}</div>
            </div>
          </div>
          <div style="margin-top:10px;">${c.text}</div>
          <div class="comment-footer">
            <span class="comment-like" data-cid="${cid}">
              <i class="${isLiked ? 'fas' : 'far'} fa-heart" style="color:${isLiked ? 'red' : '#999'};"></i>
              <span>${likeCount}</span>
            </span>
          </div>
        </div>
      `;
    });
  }
  

window.editNote = function(i) {
  currentNoteIndex = i;
  const noteText = document.getElementById(`note-${i}`)?.innerText || "";
  document.getElementById("noteInput").value = noteText === "Not eklenmemiş." ? "" : noteText;
  document.getElementById("noteModal").style.display = "flex";
};

window.closeModal = function() {
  document.getElementById("noteModal").style.display = "none";
};

window.saveNote = async function() {
  const newNote = document.getElementById("noteInput").value.trim();
  await updateDoc(postRef, {
    [`step${currentNoteIndex + 1}Note`]: newNote,
    progressStep: currentNoteIndex + 1 > 2 ? 3 : currentNoteIndex + 1
  });
  closeModal();
  loadPost();
}

document.addEventListener("click", async (e) => {
    const likeBtn = e.target.closest(".comment-like");
    if (!likeBtn || !currentUser) return;
  
    const cid = likeBtn.dataset.cid;
    const commentRef = doc(postRef, "comments", cid);
    const snap = await getDoc(commentRef);
    if (!snap.exists()) return;
  
    let likedBy = snap.data().likedBy || [];
    const hasLiked = likedBy.includes(currentUser.uid);
  
    if (hasLiked) {
      likedBy = likedBy.filter(uid => uid !== currentUser.uid);
    } else {
      likedBy.push(currentUser.uid);
    }
  
    await updateDoc(commentRef, { likedBy });
    loadComments();
  });

// İlk yükleme
if (auth.currentUser) {
  loadPost();
  loadComments();
}