var settingsmenu = document.querySelector(".settings-menu")
var darkBtn = document.getElementById("dark-btn")

// Ayarlar menüsünü açma-kapama
function settingsMenuToggle() {
    settingsmenu.classList.toggle("settings-menu-height");
}

// Tema değiştirme butonunun işlevi
darkBtn.onclick = function() {
    darkBtn.classList.toggle("dark-btn-on");
    document.body.classList.toggle("dark-theme");

    if(localStorage.getItem("theme") == "light") {
        localStorage.setItem("theme", "dark");
    } else {
        localStorage.setItem("theme", "light");
    }
}

// Sayfanın yüklenmesiyle birlikte tema kontrolü ve ayarlamalar
if(localStorage.getItem("theme") == "light") {
    darkBtn.classList.remove("dark-btn-on");
    document.body.classList.remove("dark-theme");
} else if(localStorage.getItem("theme") == "dark") {
    darkBtn.classList.add("dark-btn-on");
    document.body.classList.add("dark-theme");
} else {
    localStorage.setItem("theme", "light");
}

// Ayarlar menüsünü sadece menü butonuna tıklanarak açma
document.querySelectorAll('.settings-menu-btn').forEach(btn => {
    btn.addEventListener('click', function(event) {
        event.preventDefault();
        settingsMenuToggle();
    });
});

// Sayfanın başka bir yerine tıklanıldığında menüyü kapat
document.addEventListener('click', function(event) {
    const settingsMenus = document.querySelectorAll('.settings-menu');
    settingsMenus.forEach(menu => {
        if (!menu.contains(event.target) && !menu.previousElementSibling.contains(event.target)) {
            menu.classList.remove('settings-menu-height');
        }
    });
});


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
                        <div class="post-options-container">
                            <a href="#" class="post-options-btn"><i class="fa-solid fa-ellipsis-vertical"></i></a>
                            <div class="post-options-menu">
                                <ul>
                                    <li class="edit-post"><i class="fa-solid fa-edit"></i> Düzenle</li>
                                    <li class="delete-post"><i class="fa-solid fa-trash"></i> Sil</li>
                                    <li class="report-post"><i class="fa-solid fa-flag"></i> Şikayet Et</li>
                                </ul>
                            </div>
                        </div>                    
                    </div>                     
                    <p class="post-text">${post.title}                          
                        ${post.tags ? post.tags.map(tag => `<a href="#">${tag}</a>`).join(' ') : ''}                     
                    </p>                     
                    ${post.image ? `<img src="${post.image}" class="post-img">` : ""}                     
                    <div class="post-row">                         
                        <div class="activity-icons">                             
                            <div class="like-button" data-id="${post.id}" data-liked="false"> 
                                <img src="images/like.png" class="like-icon"> 
                                <span class="like-count">${post.likes}</span>
                            </div>                             
                            <div><img src="images/comments.png"> ${post.comments}</div>                             
                            <div><img src="images/share.png"> ${post.views}</div>                         
                        </div>                         
                        <div class="post-profile-icon">                             
                            <img src="images/profile-pic.png"> <i class="fa-solid fa-caret-down"></i>                         
                        </div>                     
                    </div>                 
                `;                  

                postContainer.appendChild(postElement);             

            });             

            // Beğenme butonlarına event listener ekleyelim
            document.querySelectorAll('.like-button').forEach(button => {
                button.addEventListener('click', function() {
                    let likeIcon = this.querySelector('.like-icon');
                    let likeCountElement = this.querySelector('.like-count');
                    let currentLikes = parseInt(likeCountElement.textContent);
                    let isLiked = this.getAttribute("data-liked") === "true";

                    if (isLiked) {
                        // Beğeniyi geri çek
                        likeIcon.src = "images/like.png"; // Normal icon
                        likeCountElement.textContent = currentLikes - 1;
                        this.setAttribute("data-liked", "false");
                    } else {
                        // Beğen
                        likeIcon.src = "images/like-blue.png"; // Mavi icon
                        likeCountElement.textContent = currentLikes + 1;
                        this.setAttribute("data-liked", "true");
                    }
                });
            });

            // Post seçenekleri menüsünü açma-kapama
            document.querySelectorAll('.post-options-btn').forEach(btn => {
                btn.addEventListener('click', function(event) {
                    event.preventDefault();
                    let menu = this.nextElementSibling;
                    menu.classList.toggle('active');
                });
            });

            // Sayfanın başka bir yerine tıklandığında menüyü kapat
            document.addEventListener('click', function(event) {
                const optionMenus = document.querySelectorAll('.post-options-menu');
                optionMenus.forEach(menu => {
                    if (!menu.contains(event.target) && !menu.previousElementSibling.contains(event.target)) {
                        menu.classList.remove('active');
                    }
                });
            });

            // Post silme işlemi
            document.querySelectorAll('.delete-post').forEach(deleteBtn => {
                deleteBtn.addEventListener('click', function() {
                    let postElement = this.closest('.post-container');
                    postElement.remove();
                });
            });

        })         
        .catch(error => console.error('Error loading posts:', error)); 
}



// Sayfa yüklendiğinde postları yükle
window.onload = loadPosts;
