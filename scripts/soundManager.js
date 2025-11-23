const soundManager = {
    sounds: {
        click: new Howl({src: ['/sonidos/click.mp3'], volume: 1})
    },

    play(name) {
        const s = this.sounds[name];
        if (s) s.play();
    },

    stop(name) {
        const s = this.sounds[name];
        if (s) s.stop();
    },

    stopAll() {
        Object.values(this.sounds).forEach(s => s.stop());
    },

    setVolume(name, volume) {
        const s = this.sounds[name];
        if (s) s.volume(volume);
    }
};