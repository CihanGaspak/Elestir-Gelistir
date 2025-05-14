export function showProfileEditWidget(userData) {
  document.getElementById("edit-profile-widget")?.remove();

  const widget = document.createElement("div");
  widget.id = "edit-profile-widget";
  widget.style = `
    position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);
    background: white; padding: 24px; border-radius: 16px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.2); z-index: 9999; max-width: 420px;
    font-family: Arial, sans-serif;
  `;

  widget.innerHTML = `
    <h2 style="margin-bottom: 15px;">🔧 Profili Düzenle</h2>
    <label style="font-weight:bold;">Kullanıcı Adı</label>
    <input id="edit-username" placeholder="Ad Soyad" value="${userData.username || ''}"
      style="width:100%;margin-bottom:10px;padding:10px;font-size:15px;border-radius:8px;border:1px solid #ddd;">
    <div id="username-status" style="margin-bottom: 15px;font-size: 13px;"></div>

    <label style="font-weight:bold;">Avatar Seç</label>
    <div id="avatar-options" style="display:grid;grid-template-columns:repeat(5, 1fr);gap:15px;margin:15px 0;">
      ${Array.from({ length: 10 }, (_, i) => i + 1).map(i => `
        <img src="assets/avatars/avatar${i}.png" data-avatar="assets/avatars/avatar${i}.png"
          style="width:60px;height:60px;border-radius:50%;cursor:pointer;border:${userData.photoUrl?.includes(`avatar${i}.png`) ? '3px solid orange' : '2px solid #ddd'};transition: 0.2s;">
      `).join('')}
    </div>

    <div style="display:flex;justify-content:flex-end;gap:10px;">
  <button id="cancel-edit-btn" style="background:#ff4d4d;color:white;padding:10px 20px;border:none;border-radius:8px;cursor:pointer;font-weight:bold;">İptal</button>
  <button id="save-profile-btn" disabled style="background:#ccc;color:#333;padding:10px 20px;border:none;border-radius:8px;cursor:not-allowed;font-weight:bold;">Kaydet</button>
</div>

  `;

  document.body.appendChild(widget);

  let selectedAvatar = userData.photoUrl || 'assets/avatars/avatar1.png';
  let currentUsername = userData.username || '';

  document.querySelectorAll("#avatar-options img").forEach(img => {
    img.addEventListener("click", () => {
      document.querySelectorAll("#avatar-options img").forEach(i => i.style.border = "2px solid #ddd");
      img.style.border = "3px solid orange";
      selectedAvatar = img.getAttribute("data-avatar");
      checkForChanges();
    });
  });

  document.getElementById("cancel-edit-btn").onclick = () => widget.remove();

  const usernameInput = document.getElementById("edit-username");
  const saveBtn = document.getElementById("save-profile-btn");
  const statusDiv = document.getElementById("username-status");

  let isUsernameValid = false;
  let usernameAvailable = false;

  async function checkUsernameAvailability(username) {
    let errors = [];
    if (!username) {
      errors.push("✅ Boş olamaz.");
    }
    if (!/^[a-zA-Z0-9_]+$/.test(username)) errors.push("✅ Sadece harf, rakam ve alt çizgi olabilir.");
    if (username.length < 3) errors.push("✅ En az 3 karakter olmalı.");
    if (username.includes(" ")) errors.push("✅ Boşluk içeremez.");

    if (errors.length > 0) {
      statusDiv.innerHTML = `<ul style="color:red;margin:0;padding-left:18px;">${errors.map(e => `<li>${e}</li>`).join('')}</ul>`;
      isUsernameValid = false;
      usernameAvailable = false;
      checkForChanges();
      return;
    }

    const { getFirestore, collection, query, where, getDocs } = await import("https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js");
    const db = getFirestore();
    const q = query(collection(db, "users"), where("username", "==", username));
    const snap = await getDocs(q);

    const isTaken = snap.docs.some(doc => doc.id !== userData.uid);

    if (isTaken) {
      statusDiv.innerHTML = `<ul style="color:red;margin:0;padding-left:18px;"><li>✅ Bu kullanıcı adı zaten alınmış.</li></ul>`;
      isUsernameValid = false;
      usernameAvailable = false;
    } else {
      statusDiv.innerHTML = `<ul style="color:green;margin:0;padding-left:18px;"><li>✅ Kullanıcı adı kullanılabilir.</li></ul>`;
      isUsernameValid = true;
      usernameAvailable = true;
    }
    checkForChanges();
  }

  function checkForChanges() {
    const newUsername = usernameInput.value.trim();
    const usernameChanged = newUsername !== currentUsername;
    const avatarChanged = selectedAvatar !== userData.photoUrl;

    if (
      (!usernameChanged && !avatarChanged) ||
      (usernameChanged && (!isUsernameValid || !usernameAvailable))
    ) {
      disableButton();
    } else {
      enableButton();
    }
  }

  function disableButton() {
    saveBtn.disabled = true;
    saveBtn.style.background = "#ccc";
    saveBtn.style.cursor = "not-allowed";
  }

  function enableButton() {
    saveBtn.disabled = false;
    saveBtn.style.background = "#ffa726";
    saveBtn.style.cursor = "pointer";
  }

  usernameInput.addEventListener("input", () => {
    const newUsername = usernameInput.value.trim();
    if (newUsername !== currentUsername) {
      checkUsernameAvailability(newUsername);
    } else {
      statusDiv.innerHTML = '';
      isUsernameValid = true;
      usernameAvailable = true;
      checkForChanges();
    }
  });

  document.getElementById("save-profile-btn").onclick = async () => {
    const newUsername = usernameInput.value.trim();
    if (!newUsername) return alert("Ad boş olamaz.");

    const { getFirestore, doc, updateDoc } = await import("https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js");
    const db = getFirestore();

    try {
      await updateDoc(doc(db, "users", userData.uid), {
        username: newUsername,
        photoUrl: selectedAvatar
      });
      widget.remove();
      location.reload();
    } catch (err) {
      console.error("Güncelleme hatası:", err);
      alert("Profil güncellenirken hata oluştu.");
    }
  };

  // İlk durum kontrol
  disableButton();
}
