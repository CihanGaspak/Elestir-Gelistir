var settingsmenu = document.querySelector(".settings-menu")
var darkBtn = document.getElementById("dark-btn")

function settingsMenuToggle(){
    settingsmenu.classList.toggle("settings-menu-height");
}
darkBtn.onclick = function(){
    darkBtn.classList.toggle("dark-btn-on");
    document.body.classList.toggle("dark-theme");

    if(localStorage.getItem("theme") == "light"){
        localStorage.setItem("theme", "dark");
    }
    else{
        localStorage.setItem("theme", "light");
    }

}

if(localStorage.getItem("theme") == "light"){
    darkBtn.classList.remove("dark-btn-on");
    document.body.classList.remove("dark-theme");
}
else if(localStorage.getItem("theme") == "dark"){
    darkBtn.classList.add("dark-btn-on");
    document.body.classList.add("dark-theme");
}
else{
    localStorage.setItem("theme", "light");
}

/*----- Filtreleme----- */
function filterPosts(category) {
    let posts = document.querySelectorAll('.post-container');
    let buttons = document.querySelectorAll('.filter-button');

    // Aktif butonu güncelle
    buttons.forEach(button => button.classList.remove('active'));
    event.target.classList.add('active');

    // Filtreleme işlemi
    posts.forEach(post => {
        // Filtreleme koşulu `data-category` ile yapılacak
        if (category === 'all') {
            post.style.display = "block";
        } else {
            post.style.display = post.dataset.category === category ? "block" : "none";
        }
    });
}

function loadPosts() {
    fetch('posts.json')
        .then(response => response.json())
        .then(posts => {
            const postContainer = document.querySelector('.posts-container');
            postContainer.innerHTML = ""; // Önceki içerikleri temizle

            posts.forEach(post => {
                const postElement = document.createElement('div');
                postElement.classList.add('post-container');
                postElement.setAttribute('data-category', post.category);

                // Tarihi biçimlendir
                const postDate = new Date(post.date);
                const formattedDate = postDate.toLocaleDateString('tr-TR', {
                    day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
                });

                // Post içeriğini oluştur
                postElement.innerHTML = `
                    <div class="post-row">
                        <div class="user-profile">
                            <img src="images/profile-pic.png">
                            <div>
                                <p>${post.author}</p>
                                <span>${formattedDate}</span>
                            </div>
                        </div>
                        <a href="#"><i class="fa-solid fa-ellipsis-vertical"></i></a>
                    </div>
                    <p class="post-text">${post.title} 
                        ${post.tags ? post.tags.map(tag => `<a href="#">${tag}</a>`).join(' ') : ''}
                    </p>
                    ${post.image ? `<img src="${post.image}" class="post-img">` : ""}
                    <div class="post-row">
                        <div class="activity-icons">
                            <div><img src="images/like.png"> ${post.likes}</div>
                            <div><img src="images/comments.png"> ${post.comments}</div>
                            <div><img src="images/search.png"> ${post.views}</div>
                        </div>
                        <div class="post-profile-icon">
                            <img src="images/profile-pic.png"> <i class="fa-solid fa-caret-down"></i>
                        </div>
                    </div>
                `;

                postContainer.appendChild(postElement);
            });
        })
        .catch(error => console.error('Error loading posts:', error));
}

// Sayfa yüklendiğinde postları yükle
window.onload = loadPosts;
