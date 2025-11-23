document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll("a, button").forEach(el => {
        el.addEventListener("click", () => soundManager.play("click"));
    });
});