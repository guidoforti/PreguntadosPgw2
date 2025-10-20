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
        $sql = "SELECT * FROM usuarios WHERE nombre_usuario = ?";
        $resultado = $this->conexion->preparedQuery($sql, 's', [$user]);

        if (empty($resultado)) {
            return ['error' => 'Usuario o contraseña incorrecta'];
        }

        $usuario = $resultado[0];

        if ($usuario['esta_verificado'] == 0) {
            return ['error' => 'Tu cuenta aún no ha sido activada. Revisa tu email para completar el registro.'];
        }

        if (!password_verify($password, $usuario['contrasena_hash'])) {
            return ['error' => 'Usuario o contraseña incorrecta'];
        }

        return ['success' => 'Inicio de sesión exitoso', 'usuario' => $usuario];
    }


}