import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import {
  getFirestore,
  doc,
  updateDoc,
  increment,
  arrayUnion,
  arrayRemove
} from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyByrxwGrUPfIFUjsG2Nsv6niu5aM_5v4wM",
  authDomain: "elestir-gelistir.firebaseapp.com",
  projectId: "elestir-gelistir",
  storageBucket: "elestir-gelistir.appspot.com",
  messagingSenderId: "329858460105",
  appId: "1:329858460105:web:0a1940df3d7b57593b6018"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Görüntülenme sayacı
export async function increaseViewCount(postId) {
  const postRef = doc(db, "posts", postId);
  await updateDoc(postRef, { views: increment(1) });
}

// Beğeni işlemi
export async function toggleLike(postId, currentUserId, likedBy) {
  const postRef = doc(db, "posts", postId);
  const isLiked = likedBy.includes(currentUserId);

  await updateDoc(postRef, isLiked
    ? {
        likesCount: increment(-1),
        likedBy: arrayRemove(currentUserId),
      }
    : {
        likesCount: increment(1),
        likedBy: arrayUnion(currentUserId),
      });
}

// Kaydetme işlemi
export async function toggleSave(postId, currentUserId, savedBy) {
  const postRef = doc(db, "posts", postId);
  const isSaved = savedBy.includes(currentUserId);

  await updateDoc(postRef, isSaved
    ? {
        savedBy: arrayRemove(currentUserId),
      }
    : {
        savedBy: arrayUnion(currentUserId),
      });
}
