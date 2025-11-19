<?php

class SecurityHelper
{

    public static function checkRole(array $rolesPermitidos) {
        // Asume 'guest' o 'usuario' si la sesión no está lista o el rol no está definido.
        $rolActual = $_SESSION['rol'] ?? 'guest';

        if (!in_array($rolActual, $rolesPermitidos)) {
            // Si el rol NO está autorizado, destruimos la sesión y redirigimos al login.
            session_destroy();

            // Limpiar la cookie de sesión
            if (ini_get("session.use_cookies")) {
                $params = session_get_cookie_params();
                setcookie(session_name(), '', time() - 42000,
                    $params["path"], $params["domain"],
                    $params["secure"], $params["httponly"]
                );
            }

            // Redirigir al login
            header("Location: /login/loginForm");
            exit; // CRÍTICO: Detener la ejecución del script del controlador.
        }
        // Si el rol es válido, la función termina y el código del controlador continúa.
    }

}