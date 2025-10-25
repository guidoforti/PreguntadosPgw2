<?php

class SecurityHelper
{

    public static function validarRol(array $rolesPermitidos){
        $rolActual = $_SESSION['rol'] ?? null;
        if(!in_array($rolActual, $rolesPermitidos)){
            header("Location: /preguntados/home?error=UsuarioNoAutorizado");
            exit;
        }
    }

}