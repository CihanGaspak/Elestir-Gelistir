import { db, auth } from './firebase.js';
import { doc, updateDoc } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

// 👇 Beğeni toggle fonksiyonu
export async function toggleLike(postId, uid, likedByArray) {
    const isLiked = likedByArray.includes(auth.currentUser.uid);
    const postRef = doc(db, "posts", postId);

    await updateDoc(postRef, {
        likedBy: isLiked ? likedByArray.filter(u => u !== auth.currentUser.uid) : [...likedByArray, auth.currentUser.uid],
        likesCount: likedByArray.length + (isLiked ? -1 : 1)
    });

    const likeBtn = document.getElementById(`like-${postId}`);
    if (likeBtn) {
        likeBtn.innerHTML = `
            <i class="${isLiked ? 'far' : 'fas'} fa-thumbs-up" style="color:${isLiked ? 'black' : 'orange'};"></i> ${likedByArray.length + (isLiked ? -1 : 1)}
        `;
    }
}

// 👇 Kaydetme toggle fonksiyonu
export async function toggleSave(postId, uid, savedByArray) {
    const isSaved = savedByArray.includes(auth.currentUser.uid);
    const postRef = doc(db, "posts", postId);

    await updateDoc(postRef, {
        savedBy: isSaved ? savedByArray.filter(u => u !== auth.currentUser.uid) : [...savedByArray, auth.currentUser.uid]
    });

    const saveBtn = document.getElementById(`save-${postId}`);
    if (saveBtn) {
        saveBtn.innerHTML = `
            <i class="${isSaved ? 'far' : 'fas'} fa-bookmark" style="color:${isSaved ? 'black' : 'orange'};"></i>
        `;
    }
}
