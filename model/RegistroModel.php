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
        // Validaciones de datos lógicas
        if ($this->existeNombreUsuario($nombreUsuario)) {
            return ['error' => 'El nombre de usuario no está disponible'];
        }
        if (!$this->sonContraseniasIguales($contraseniaUno, $contraseniaDos)) {
            return ['error' => 'Las contraseñas no coinciden'];
        }
        if (!$this->esEmailValido($email)) {
            return ['error' => 'El email no tiene un formato o dominio válido'];
        }
        if (!$this->esAnioNacimientoValido($anioNacimiento)) {
            return ['error' => 'El año de nacimiento no es válido'];
        }

        // Validación y guardado de imagen
        $rutaBase = __DIR__ . "/../imagenes/usuario/";
        if (!is_dir($rutaBase)) {
            mkdir($rutaBase, 0777, true);
        }

        $rutaRelativa = null; // se guardará en BD
        if ($imagen && $imagen['error'] === UPLOAD_ERR_OK) {
            $tipoMime = mime_content_type($imagen['tmp_name']);
            $tamaño = $imagen['size'];

            // Validar formato
            $formatosPermitidos = ['image/jpeg', 'image/png', 'image/gif'];
            if (!in_array($tipoMime, $formatosPermitidos)) {
                return ['error' => 'Formato de imagen no permitido (solo JPG, PNG o GIF)'];
            }

            // Validar tamaño (máx 2 MB)
            if ($tamaño > 2 * 1024 * 1024) {
                return ['error' => 'La imagen supera el tamaño máximo de 2MB'];
            }

            // Obtener extensión segura
            $ext = pathinfo($imagen['name'], PATHINFO_EXTENSION);
            $fechaActual = new DateTime();
            $nombreSeguro = 'profile_' . $fechaActual->format('YmdHisv') . '.' . strtolower($ext);

            // Construir rutas
            $rutaFinal = $rutaBase . $nombreSeguro;
            $rutaRelativa = "imagenes/usuario/" . $nombreSeguro;

            if (!move_uploaded_file($imagen['tmp_name'], $rutaFinal)) {
                return ['error' => 'Error al guardar la imagen'];
            }
        }

        // Hash de contraseña
        $contrasenaHash = password_hash($contraseniaUno, PASSWORD_DEFAULT);
        $ciudadId = 1; // Temporal hasta integrar mapa

        // Insert SQL
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
                    " . ($rutaRelativa ? "'$rutaRelativa'" : "NULL") . ",
                    'usuario',
                    0
                )";

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
        $sql = "SELECT * FROM usuarios where nombre_usuario = '$nombreUsuario'";
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

    public function esAnioNacimientoValido($anioNacimiento) {
        $anioValido = true;
        try {
            $anioNacimientoInt = (int) $anioNacimiento;
            if( $anioNacimientoInt < 1900 ) {
                $anioValido = false;
            }
            
        } catch (\Throwable $th) {
            $anioValido = false;
        }
        return $anioValido;
    }
}