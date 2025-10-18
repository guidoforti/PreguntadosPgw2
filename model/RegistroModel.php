<?php

class RegistroModel
{

    private $conexion;


    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }


    public function registrar($nombreCompleto, $anioNacimiento, $sexo, $email, $nombreUsuario, $contraseniaUno, $contraseniaDos, $imagen)
    {
        if ($this->existeNombreUsuario($nombreUsuario)) {
            return ['error' => 'el nombre de usuario no esta disponible'];
        }
        if (!$this->sonContraseniasIguales($contraseniaUno, $contraseniaDos)) {
            return ['error' => 'las contraseñas no coinciden'];
        }
        if (!$this->esEmailValido($email)) {
            return ['error' => 'El email no tiene un formato o dominio valido'];
        }

        // muevo la imagen a los files correctos y persisto el pokemon
        $direccioBase = "../imagenes/usuario/";
        if (isset($imagen) && $imagen['error'] == 0) {
            $nombreDeLaImagen = basename($imagen["name"]);
            $direccioFinalDeImagen = $direccioBase . $nombreDeLaImagen;
            move_uploaded_file($imagen["tmp_name"], $direccioFinalDeImagen);
        } else {
            return ['error' => 'error al guardar la imagen'];
        }

        $contrasenaHash = password_hash($contraseniaUno, PASSWORD_DEFAULT);
        $contrasenaHash = password_hash($contraseniaUno, PASSWORD_DEFAULT);
        $ciudadId = 1; // Asegúrate de obtener este valor de alguna manera

        $sql = "INSERT INTO usuarios (
                nombre_completo, 
                nombre_usuario, 
                email, 
                contrasena_hash, 
                ano_nacimiento, 
                sexo, 
                ciudad_id, 
                url_foto_perfil, 
                rol, 
                esta_verificado
            ) VALUES (
                '$nombreCompleto',
                '$nombreUsuario',
                '$email',
                '$contrasenaHash',
                $anioNacimiento,
                '$sexo',
                $ciudadId,
                $direccioFinalDeImagen,
                'usuario',
                0)";

        $resultado = $this->conexion->query($sql);

        if ($resultado) {
            return ['success' => 'Usuario registrado correctamente'];
        } else {
            return ['error' => 'El usuario no se pudo registrar correctamente'];
        }

    }

    public function existeNombreUsuario($nombreUsuario)
    {
        $estaPresente = false;
        $sql = "SELECT * FROM usuarios where nombre_usuario = $nombreUsuario";
        $resultado = $this->conexion->query($sql);
        if ($resultado) {
            $estaPresente = true;
        }
        return $estaPresente;
    }

    public function sonContraseniasIguales($contraseniaUno, $contraseniaDos)
    {
        $sonIguales = true;
        if ($contraseniaUno != $contraseniaDos) {
            $sonIguales = false;
        }
        return $sonIguales;
    }

    public function esEmailValido($email)
    {
        $esValido = true;

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $esValido = false;
        }

        // Extraer el dominio del email
        $dominio = strtolower(substr(strrchr($email, "@"), 1));

        // Lista de dominios permitidos
        $dominiosPermitidos = [
            'gmail.com',
            'hotmail.com',
            'outlook.com',
            'yahoo.com',
            'yahoo.com.ar',
            'yahoo.es',
            'hotmail.com.ar',
            'outlook.com.ar'
        ];

        if (!in_array($dominio, $dominiosPermitidos)) {
            $esValido = false;
        }

        return $esValido;
    }
}