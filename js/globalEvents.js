console.log("[globalEvents] cargado");

document.addEventListener("click", (e) => {
    const link = e.target.closest("a");
    if (!link) return;
    if (link.classList.contains('no-ajax-load') || link.href.includes('/perfil/')) {
        console.log("[Navegación] Detectado enlace de Perfil o no-ajax. Recargando página.");
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
    if (path.startsWith("/jugarPartida")) {

        if (soundManager.sounds.menu.playing()) {
            soundManager.stop("menu");
        }

        if (path.includes("/finalizar")) {
            if (soundManager.sounds.question.playing()) {
                soundManager.stop("question");
            }
        }
        else {
            if (!soundManager.sounds.question.playing()) {
                soundManager.play("question");
            }
        }

    }
    else {
        if (soundManager.sounds.question.playing()) {
            soundManager.stop("question");
        }
        if (soundManager.sounds.victoryGame.playing()) soundManager.stop("victoryGame");
        if (soundManager.sounds.loseGame.playing()) soundManager.stop("loseGame");

        if (!soundManager.sounds.menu.playing()) {
            soundManager.play("menu");
        }
    }
};


const executeScripts = (container) => {
    const scripts = container.querySelectorAll("script");

    scripts.forEach((oldScript) => {
        const newScript = document.createElement("script");

        // Copiamos los atributos del script original (src, type, etc.)
        Array.from(oldScript.attributes).forEach(attr => {
            newScript.setAttribute(attr.name, attr.value);
        });

        // Si tiene contenido inline, lo copiamos
        if (oldScript.innerHTML) {
            newScript.appendChild(document.createTextNode(oldScript.innerHTML));
        }

        // Reemplazamos el viejo (muerto) por el nuevo (vivo)
        oldScript.parentNode.replaceChild(newScript, oldScript);
    });
};

// Primer control al cargar la página
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

window.addEventListener('popstate', () => {
    controlMenuMusic(window.location.pathname);
    window.location.reload();
});