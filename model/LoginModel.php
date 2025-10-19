<?php

class LoginModel
{

    private $conexion;

    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }

    public function getUserWith($user, $password)
    {
        $sql = "SELECT * FROM usuarios WHERE nombre_usuario = '$user'";
        $resultado = $this->conexion->query($sql);

        if (!$resultado) {
            return ['error' => 'Usuario o contraseña incorrecta'];
        }

        $usuario = $resultado[0];

        if (!password_verify($password, $usuario['contrasena_hash'])) {
            return ['error' => 'Usuario o contraseña incorrecta'];
        }

        return ['success' => 'Inicio de sesión exitoso', 'usuario' => $usuario];
    }


}