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
        if (!s) {
            console.warn("[soundManager] No existe sonido:", name);
            return;
        }

        if (!s.playing()) {
            console.log("[soundManager] Reproduciendo sonido:", name);
            s.play();
        } else {
            console.log("[soundManager] Sonido ya estaba sonando:", name);
        }
    },

    stop(name) {
        const s = this.sounds[name];
        if (!s) return;

        if (s.playing()) {
            console.log("[soundManager] Deteniendo sonido:", name);
            s.fade(s.volume(), 0, 500);
            s.once('fade', function(){
                s.stop();
                console.log("[soundManager] Sonido parado:", name);
            });
        }
    }
};
