/**
 * Script para la vista de perfil
 * Maneja el mapa de ubicación del usuario
 */

document.addEventListener('DOMContentLoaded', function() {
    // Obtener datos del mapa desde los atributos data
    const mapElement = document.getElementById('map');

    if (!mapElement) {
        console.warn('Elemento del mapa no encontrado');
        return;
    }

    const ubicacion = mapElement.dataset.ubicacion || '';
    const nombreUsuario = mapElement.dataset.usuario || '';

    if (!ubicacion || ubicacion.trim() === '') {
        mapElement.innerHTML = '<div class="p-4 text-center text-muted"><p>Ubicación no disponible</p></div>';
        return;
    }

    // Cargar ubicación desde Nominatim
    fetch('/proxyNominatim.php?q=' + encodeURIComponent(ubicacion))
        .then(response => response.json())
        .then(data => {
            if (data.length > 0) {
                const result = data[0];
                const lat = parseFloat(result.lat);
                const lon = parseFloat(result.lon);

                // Inicializar mapa
                const map = L.map('map').setView([lat, lon], 6);

                // Agregar capa de tiles
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '© OpenStreetMap contributors',
                    maxZoom: 19
                }).addTo(map);

                // Agregar marcador
                L.marker([lat, lon])
                    .bindPopup(`<b>${nombreUsuario}</b><br/>${ubicacion}`)
                    .addTo(map);
            } else {
                mapElement.innerHTML = '<div class="p-4 text-center text-muted"><p>No se encontró la ubicación</p></div>';
            }
        })
        .catch(error => {
            console.error('Error al cargar ubicación:', error);
            mapElement.innerHTML = '<div class="p-4 text-center text-muted"><p>Error al cargar el mapa</p></div>';
        });
});
