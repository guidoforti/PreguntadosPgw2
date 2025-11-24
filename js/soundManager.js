console.log("[soundManager] cargado");

document.addEventListener("click", () => {
    if (Howler.ctx.state === "suspended") {
        Howler.ctx.resume();
    }
}, { once: true });

const soundManager = {
    sounds: {
        click: new Howl({
            src: ['/sonidos/click.mp3'],
            volume: 1,
            loop: false
        }),
        menu: new Howl({
            src: ['/sonidos/menu.mp3'],
            volume: 0.6,
            loop: true
        }),
        question: new Howl({
            src: ['/sonidos/question.mp3'],
            volume: 0.4,
            loop:true
        }),
        wheel: new Howl({
            src: ['/sonidos/wheel.mp3'],
            volume: 1,
            loop: false
        }),
        correctAnswer: new Howl({
            src: ['/sonidos/correctanswer.mp3'],
            volume: 0.7,
            loop: false
        }),
        incorrectAnswer: new Howl({
            src: ['/sonidos/incorrectanswer.mp3'],
            volume: 0.7,
            loop: false
        }),
        victoryGame: new Howl({
            src: ['/sonidos/victorygame.mp3'],
            volume: 0.7,
            loop: true
        }),
        loseGame: new Howl({
            src: ['/sonidos/losegame.mp3'],
            volume: 0.7,
            loop: true
        }),
        alert: new Howl({
            src: ['/sonidos/alert.mp3'],
            volume: 0.7,
            loop: false
        })
    },

    play(name) {
        const s = this.sounds[name];
        if (!s) return;
        if (s.loop() && s.playing()) return;
        s.play();
    },

    stop(name) {
        const s = this.sounds[name];
        if (s && s.playing()) {
            s.fade(s.volume(), 0, 500);
            s.once('fade', function(){ s.stop(); s.volume(0.6); });
        }
    }
};

document.addEventListener('DOMContentLoaded', () => {
    const muteBtn = document.getElementById('btn-mute');
    const muteIcon = document.getElementById('icon-mute');
    const isMuted = localStorage.getItem('musicMuted') === 'true';
    if (typeof Howler !== 'undefined') {
        Howler.mute(isMuted);
    }
    updateMuteIcon(isMuted);
    if (muteBtn) {
        muteBtn.addEventListener('click', (e) => {
            e.preventDefault();
            const newMuteState = !Howler._muted;
            Howler.mute(newMuteState);
            localStorage.setItem('musicMuted', newMuteState); // Guardamos para el futuro
            updateMuteIcon(newMuteState);
        });
    }

    function updateMuteIcon(muted) {
        if (!muteIcon) return;
        if (muted) {
            muteIcon.classList.remove('fa-volume-up');
            muteIcon.classList.add('fa-volume-mute');
            muteIcon.style.opacity = "0.5";
        } else {
            muteIcon.classList.remove('fa-volume-mute');
            muteIcon.classList.add('fa-volume-up');
            muteIcon.style.opacity = "1";
        }
    }
});