/**
 * Script para la vista de edición de perfil
 * Maneja validación de contraseña y mapa de ubicación
 */

const password = document.getElementById('password');
const confirmPassword = document.getElementById('confirmPassword');
const form = document.getElementById('formEditar');

function validatePassword() {
    // Solo validar si al menos uno de los campos de contraseña tiene valor
    if (password.value === '' && confirmPassword.value === '') {
        confirmPassword.setCustomValidity('');
        confirmPassword.classList.remove('is-invalid');
        return true;
    }

    if (password.value !== confirmPassword.value) {
        confirmPassword.setCustomValidity("Las contraseñas no coinciden");
        confirmPassword.classList.add('is-invalid');
        return false;
    } else {
        confirmPassword.setCustomValidity('');
        confirmPassword.classList.remove('is-invalid');
        return true;
    }
}

password.onchange = validatePassword;
confirmPassword.onkeyup = validatePassword;

form.onsubmit = function(e) {
    if (!validatePassword()) {
        e.preventDefault();
        return false;
    }
    return true;
};

document.addEventListener('DOMContentLoaded', function() {
    const anioActual = new Date().getFullYear();
    document.getElementById('anioNacimiento').max = anioActual - 1;

    // Javascript del Mapa
    let map = L.map('map').setView([-34.6037, -58.3816], 13);
    let marker;

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    L.Control.geocoder({
        geocoder: L.Control.Geocoder.nominatim({
            serviceUrl: window.location.origin + '/proxyNominatim.php?'
        }),
        defaultMarkGeocode: false
    })
            .on('markgeocode', function (e){
                let latlng = e.geocode.center;
                let address = e.geocode.properties.address;

                console.log('Geocode result:', e.geocode);

                map.setView(latlng, 15);

                if(marker){
                    marker.setLatLng(latlng);
                } else {
                    marker = L.marker(latlng).addTo(map);
                }

                document.getElementById('pais').value = address.country || '';
                document.getElementById('provincia').value = address.state || '';
                document.getElementById('ciudad').value = address.city || address.town || address.village || '';
            })
            .addTo(map);

    // Si hay ubicación actual, intentar mostrarla en el mapa
    const paisActual = document.getElementById('pais').value;
    const provinciaActual = document.getElementById('provincia').value;
    const ciudadActual = document.getElementById('ciudad').value;

    if (paisActual || provinciaActual || ciudadActual) {
        const ubicacionTexto = [ciudadActual, provinciaActual, paisActual].filter(Boolean).join(', ');
        if (ubicacionTexto) {
            fetch('/proxyNominatim.php?q=' + encodeURIComponent(ubicacionTexto))
                .then(response => response.json())
                .then(data => {
                    if (data.length > 0) {
                        const result = data[0];
                        const lat = parseFloat(result.lat);
                        const lon = parseFloat(result.lon);
                        map.setView([lat, lon], 10);
                        marker = L.marker([lat, lon]).addTo(map);
                    }
                })
                .catch(error => console.error('Error al cargar ubicación:', error));
        }
    }
});
