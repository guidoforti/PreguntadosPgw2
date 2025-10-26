<?php

class SecurityHelper
{

    public static function checkRole(array $rolesPermitidos) {
        // Asume 'guest' o 'usuario' si la sesión no está lista o el rol no está definido.
        $rolActual = $_SESSION['rol'] ?? 'guest';

        if (!in_array($rolActual, $rolesPermitidos)) {
            // Si el rol NO está autorizado, forzamos la redirección.
            // La redirección lo lleva al home/lobby con un mensaje de error.
            header("Location: /preguntados/home?error=Permiso_Insuficiente");
            exit; // CRÍTICO: Detener la ejecución del script del controlador.
        }
        // Si el rol es válido, la función termina y el código del controlador continúa.
    }

}