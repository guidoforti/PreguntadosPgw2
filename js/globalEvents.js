console.log("[globalEvents] cargado");

document.addEventListener("click", (e) => {
    const link = e.target.closest("a");
    if (!link) return;
    if (link.closest('.leaflet-container')) {
        return;
    }

    if (link.classList.contains('no-ajax-load') ||
        link.href.includes('/perfil/') ||
        link.href.includes('/logout')) {
        return;
    }
    e.preventDefault();
    console.log("[AJAX] Click interceptado en link:", link.href);
    soundManager.play("click");
    setTimeout(() => {
        loadView(link.href);
    }, 180);
});

const appContent = document.getElementById('app-content');

const controlMenuMusic = (path) => {
    if (typeof IS_LOGGED_IN !== 'undefined' && !IS_LOGGED_IN) {
        if (typeof soundManager !== 'undefined') {
            soundManager.stop("menu");
            soundManager.stop("question");
            soundManager.stop("victoryGame");
            soundManager.stop("loseGame");
        }
        return;
    }

    if (path.startsWith("/jugarPartida")) {
        if (soundManager.sounds.menu.playing()) soundManager.stop("menu");

        if (path.includes("/finalizar")) {
            if (soundManager.sounds.question.playing()) soundManager.stop("question");
        }
        else {
            if (!soundManager.sounds.question.playing()) soundManager.play("question");
        }
    }
    else {
        if (soundManager.sounds.question.playing()) soundManager.stop("question");
        if (soundManager.sounds.victoryGame.playing()) soundManager.stop("victoryGame");
        if (soundManager.sounds.loseGame.playing()) soundManager.stop("loseGame");
        if (!soundManager.sounds.menu.playing()) soundManager.play("menu");
    }
};

document.addEventListener('DOMContentLoaded', () => {
    const logoutLinks = document.querySelectorAll('a[href*="logout"]');
    logoutLinks.forEach(link => {
        link.addEventListener('click', () => {
            if (typeof soundManager !== 'undefined') {
                console.log("[Logout] Apagando todo...");
                Howler.stop();
            }
        });
    });
});


const executeScripts = (container) => {
    const scripts = container.querySelectorAll("script");

    scripts.forEach((oldScript) => {
        const newScript = document.createElement("script");

        Array.from(oldScript.attributes).forEach(attr => {
            newScript.setAttribute(attr.name, attr.value);
        });

        if (oldScript.innerHTML) {
            newScript.appendChild(document.createTextNode(oldScript.innerHTML));
        }

        oldScript.parentNode.replaceChild(newScript, oldScript);
    });
};

controlMenuMusic(window.location.pathname);

const loadView = (url) => {
    const url_ajax = url + (url.includes('?') ? '&' : '?') + 'ajax=true';
    console.log("[AJAX] URL para fetch:", url_ajax);

    fetch(url_ajax)
        .then(response => {
            if (!response.ok) throw new Error("Response not OK");
            return response.text();
        })
        .then(html => {
            const appContent = document.getElementById('app-content');
            if (!appContent) throw new Error("No se encontró el contenedor app-content");

            html = html.replace("AJAX_END", "");
            appContent.innerHTML = html;

            executeScripts(appContent);

            history.pushState(null, '', url);
            controlMenuMusic(url);
        })
        .catch(error => {
            console.error("[AJAX] Fallo en la carga de la vista:", error);
            window.location.href = url;
        });
};

controlMenuMusic(window.location.pathname);
window.addEventListener('popstate', () => {
    controlMenuMusic(window.location.pathname);
    window.location.reload();
});