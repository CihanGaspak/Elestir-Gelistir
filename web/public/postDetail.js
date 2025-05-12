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
      await loadPost();
      await loadComments();
    }
  });

  async function loadPost() {
    const snap = await getDoc(postRef);
    if (!snap.exists()) return document.getElementById("post-container").innerHTML = "<div>Gönderi bulunamadı!</div>";
    currentPost = snap.data();
    renderPost();
    renderSteps();
    await updateCommentCount();
  }

  function renderPost() {
    const post = currentPost;
    const uid = currentUser.uid;
    const isLiked = post.likedBy?.includes(uid);
    const isSaved = post.savedBy?.includes(uid);

    document.getElementById("post-container").innerHTML = `
      <div class="header">
        <img class="avatar" src="${post.authorPhotoUrl || 'assets/avatars/avatar1.png'}">
        <div>
          <div>${post.authorName}</div>
          <div style="font-size:12px;color:gray;">${timeAgo(new Date(post.date?.seconds * 1000))}</div>
        </div>
      </div>
      <div style="margin:20px 0;">${post.content}</div>
      <div class="actions">
        <span id="likeBtn"><i class="${isLiked ? 'fas' : 'far'} fa-thumbs-up"></i> ${post.likesCount || 0}</span>
        <span><i class="far fa-comment"></i> <span id="commentCount">0</span></span>
        <span id="saveBtn"><i class="${isSaved ? 'fas' : 'far'} fa-bookmark"></i></span>
        <span id="shareBtn"><i class="fas fa-share"></i></span>
        <span><i class="far fa-eye"></i> ${post.views || 0}</span>
      </div>
      <div id="steps"></div>
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
  }

  function renderSteps() {
  const post = currentPost;
  if (!post) return;

  const step = post.progressStep || 0;
  const isOwner = currentUser?.uid === post.authorId;
  const titles = ["Eleştir", "Düşün", "Geliştir"];
  const icons = ["fas fa-exclamation-circle", "fas fa-lightbulb", "fas fa-tools"];

  const stepsEl = document.getElementById("steps");
  if (!stepsEl) return;

  stepsEl.innerHTML = titles.map((t, i) => `
    <div class="step-card">
      <div style="display:flex;justify-content:space-between;align-items:center;">
        <h4><i class="${icons[i]}" style="color:orange;"></i> ${step >= i + 1 ? t : "Henüz bu aşamaya geçilmedi"}</h4>
        ${isOwner && step >= i + 1 ? `<button onclick="editNote(${i})">Düzenle</button>` : ''}
      </div>
      ${step >= i + 1 ? `<p id="note-${i}">${post[`step${i + 1}Note`] || "Not eklenmemiş."}</p>` : ''}
    </div>
  `).join('');
}

  window.editNote = async function (i) {
    const oldNote = currentPost[`step${i + 1}Note`] || "";
    const newNote = prompt(`"${["Eleştir", "Düşün", "Geliştir"][i]}" Notunu Güncelle:`, oldNote);
    if (newNote === null) return;
    await updateDoc(postRef, {
      [`step${i + 1}Note`]: newNote,
      progressStep: Math.max(currentPost.progressStep || 0, i + 1)
    });
    await loadPost();
  }

  async function toggleLike() {
    const uid = currentUser.uid;
    const isLiked = currentPost.likedBy?.includes(uid);
    await updateDoc(postRef, {
      likesCount: increment(isLiked ? -1 : 1),
      likedBy: isLiked ? currentPost.likedBy.filter(u => u !== uid) : [...(currentPost.likedBy || []), uid]
    });
    await loadPost();
  }

  async function toggleSave() {
    const uid = currentUser.uid;
    const isSaved = currentPost.savedBy?.includes(uid);
    await updateDoc(postRef, {
      savedBy: isSaved ? currentPost.savedBy.filter(u => u !== uid) : [...(currentPost.savedBy || []), uid]
    });
    await loadPost();
  }

  async function loadComments() {
    const snap = await getDocs(query(collection(postRef, "comments"), orderBy("date", "desc")));
    comments = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    renderComments();
    await updateCommentCount();
  }

  function renderComments() {
    const container = document.getElementById("comments");
    container.innerHTML = comments.length === 0 ? "<div>Henüz yorum yok.</div>" : "";
    comments.forEach(c => {
      container.innerHTML += `
        <div class="comment">
          <div style="display:flex;align-items:center;gap:10px;">
            <img class="avatar" src="${c.authorPhotoUrl || 'assets/avatars/avatar1.png'}" style="width:32px;height:32px;">
            <div>
              <strong>${c.authorName || 'Kullanıcı'}</strong>
              <div style="font-size:12px;color:gray;">${timeAgo(new Date(c.date.seconds * 1000))}</div>
            </div>
            <div style="margin-left:auto;cursor:pointer;" onclick="toggleCommentLike('${c.id}')">
              <i class="far fa-heart"></i> ${(c.likedBy || []).length}
            </div>
          </div>
          <div style="margin-top:6px;">${c.text}</div>
        </div>
      `;
    });
  }

  window.toggleCommentLike = async function (cid) {
    const ref = doc(postRef, "comments", cid);
    const snap = await getDoc(ref);
    if (!snap.exists()) return;
    let likedBy = snap.data().likedBy || [];
    likedBy = likedBy.includes(currentUser.uid) ? likedBy.filter(uid => uid !== currentUser.uid) : [...likedBy, currentUser.uid];
    await updateDoc(ref, { likedBy });
    await loadComments();
  }

  async function sendComment() {
    const text = document.getElementById("commentInput").value.trim();
    if (!text) return;
    await addDoc(collection(postRef, "comments"), {
      text,
      date: new Date(),
      authorId: currentUser.uid,
      authorName: currentUser.displayName || 'Kullanıcı',
      authorPhotoUrl: currentUser.photoURL || 'assets/avatars/avatar1.png',
      likedBy: []
    });
    if ((currentPost.progressStep || 0) < 1) {
      await updateDoc(postRef, { progressStep: 1 });
    }
    document.getElementById("commentInput").value = "";
    await loadComments();
    await loadPost();
  }

  async function updateCommentCount() {
    const q = query(collection(postRef, "comments"));
    const snap = await getDocs(q);
    document.getElementById("commentCount").innerText = snap.size;
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
  await loadPost();
}

});
