<?php

class UsuarioModel
{

    private $conexion;


    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }


    public function registrar($nombreCompleto, $anioNacimiento, $sexo, $email, $nombreUsuario, $contraseniaUno, $contraseniaDos, $imagen, $paisNombre, $provinciaNombre, $ciudadNombre)
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
        if ($this->existeEmail($email)) {
            return ['error' => 'El correo electrónico ya está registrado.'];
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

            $paisId = $this->obtenerOCrear('paises', $paisNombre);
            $provinciaId = $this->obtenerOCrear('provincias', $provinciaNombre, ['pais_id' => $paisId]);
            $ciudadId = $this->obtenerOCrear('ciudades', $ciudadNombre, ['provincia_id' => $provinciaId]);

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
        $tokenVerificacion = bin2hex(random_bytes(16));

        // Insert SQL
        $sql = "INSERT INTO usuarios (
            nombre_completo, nombre_usuario, email, contrasena_hash, ano_nacimiento, 
            sexo, ciudad_id, url_foto_perfil, rol, token_verificacion, esta_verificado
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        $tipos = 'ssssisisssi';

        $parametros = [
            $nombreCompleto,
            $nombreUsuario,
            $email,
            $contrasenaHash,
            $anioNacimiento,
            $sexo,
            $ciudadId,
            $rutaRelativa,
            'usuario',
            $tokenVerificacion,
            0
        ];

        $resultado = $this->conexion->preparedQuery($sql, $tipos, $parametros);

        if ($resultado === true) {
            return ['success' => 'Usuario registrado correctamente', 'token' => $tokenVerificacion, 'email' => $email];
        } else {
            return ['error' => 'El usuario no se pudo registrar correctamente'];
        }
    }

    public function deleteUsuarioById($id)
    {
        $sql = "DELETE FROM usuarios where id = ?";
        $this->conexion->preparedQuery($sql, 'i', [$id]);
    }

    public function getUsuarioById($id)
    {
        $sql = "SELECT * FROM usuarios WHERE usuario_id = ?";
        $resultado = $this->conexion->preparedQuery($sql, 'i', [$id]);
        if (!empty($resultado)) {
            return $resultado[0];
        }
        return null;
    }

    public function updateUsuario($id, $nombreCompleto, $anioNacimiento, $sexo, $email, $nombreUsuario, $contraseniaUno, $contraseniaDos, $imagen, $rol, $estadoDeVerificacion)
    {
        try {
            if (empty($id)) {
                return ['error' => 'ID de usuario no proporcionado'];
            }

            // verifico si el usuario existe
            $usuarioActual = $this->getUsuarioById($id);
            if (!$usuarioActual) {
                return ['error' => 'El usuario no existe'];
            }

            // valido que el nombre de usuario no esté en uso por otro usuario
            if ($usuarioActual['nombre_usuario'] !== $nombreUsuario && $this->existeNombreUsuario($nombreUsuario)) {
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

            // Procesar imagen si se proporcionó una nueva
            $rutaRelativa = $usuarioActual['url_foto_perfil']; // Mantener la imagen actual por defecto

            if ($imagen && $imagen['error'] === UPLOAD_ERR_OK) {

                $tipoMime = mime_content_type($imagen['tmp_name']);
                $formatosPermitidos = ['image/jpeg', 'image/png', 'image/gif'];

                if (!in_array($tipoMime, $formatosPermitidos)) {
                    return ['error' => 'Formato de imagen no permitido (solo JPG, PNG o GIF)'];
                }


                if ($imagen['size'] > 2 * 1024 * 1024) {
                    return ['error' => 'La imagen supera el tamaño máximo de 2MB'];
                }


                $rutaBase = __DIR__ . "/../imagenes/usuario/";
                if (!is_dir($rutaBase)) {
                    mkdir($rutaBase, 0777, true);
                }


                $ext = pathinfo($imagen['name'], PATHINFO_EXTENSION);
                $nombreSeguro = 'profile_' . uniqid() . '.' . strtolower($ext);
                $rutaFinal = $rutaBase . $nombreSeguro;
                $rutaRelativa = "imagenes/usuario/" . $nombreSeguro;


                if (!move_uploaded_file($imagen['tmp_name'], $rutaFinal)) {
                    return ['error' => 'Error al guardar la imagen'];
                }

                // Si había una imagen anterior, la eliminamos
                if (!empty($usuarioActual['url_foto_perfil'])) {
                    $rutaImagenAnterior = __DIR__ . '/../' . $usuarioActual['url_foto_perfil'];
                    if (file_exists($rutaImagenAnterior)) {
                        @unlink($rutaImagenAnterior);
                    }
                }
            }

            // hasheamos la contraseña si se proporcionó una nueva
            $contrasenaHash = !empty($contraseniaUno)
                ? password_hash($contraseniaUno, PASSWORD_DEFAULT)
                : $usuarioActual['contrasena_hash'];

            // Actualizo en la base de datos con consulta preparada
            $sql = "UPDATE usuarios SET 
            nombre_completo = ?,
            nombre_usuario = ?,
            email = ?,
            contrasena_hash = ?,
            ano_nacimiento = ?,
            sexo = ?,
            url_foto_perfil = ?,
            rol = ?,
            esta_verificado = ?
            WHERE usuario_id = ?";

            $tipos = 'sssiisssii';

            $parametros = [
                $nombreCompleto,
                $nombreUsuario,
                $email,
                $contrasenaHash,
                $anioNacimiento,
                $sexo,
                $rutaRelativa,
                $rol,
                $estadoDeVerificacion,
                $id
            ];
            $this->conexion->preparedQuery($sql, $tipos, $parametros);

            return ['success' => 'Usuario actualizado correctamente'];
        } catch (Exception $e) {

            return ['error' => 'Ocurrió un error al actualizar el usuario'];
        }
    }

    public function modificarRanking($id, $puntos)
    {
        try {
            // Le decimos a mmysql que él mismo haga la suma en vez de obterner el rankign sumarlo y updatearlo, asi tenemos atomicidad.
            // seguro contra condiciones de carrera.
            //el greatest nos asegura atomicidaad y dejar en 0 si por ej tiene 5 puntos y pierde 15.
            $sql = "UPDATE usuarios SET ranking = GREATEST(ranking + ?, 0) WHERE usuario_id = ?";
            $resultadoUpdate = $this->conexion->preparedQuery($sql, 'ii', [$puntos, $id]);

            if (!$resultadoUpdate) {
                throw new Exception("Error al actualizar el ranking (ID no encontrado o sin cambios).");
            }

            // leemos el nuevo valor para devolverlo.
            $sql_select = "SELECT ranking FROM usuarios WHERE usuario_id = ?";
            $resultado = $this->conexion->preparedQuery($sql_select, 'i', [$id]);

            if (empty($resultado)) {
                throw new Exception("Usuario no encontrado post-actualización.");
            }

            $nuevoRanking = $resultado[0]['ranking'];

            return [
                'success' => true,
                'error' => false,
                'message' => 'Ranking actualizado correctamente',
                'rankingActualizado' => $nuevoRanking
            ];
        } catch (Exception $e) {
            error_log("Error en modificarRanking: " . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Ocurrió un error al actualizar el ranking del usuario'
            ];
        }
    }

    public function existeNombreUsuario($nombreUsuario)
    {
        $estaPresente = false;
        $sql = "SELECT * FROM usuarios where nombre_usuario = ?";
        $resultado = $this->conexion->preparedQuery($sql, 's', [$nombreUsuario]);
        return !empty($resultado);
    }

    public function sonContraseniasIguales($contraseniaUno, $contraseniaDos)
    {
        $sonIguales = true;
        if ($contraseniaUno != $contraseniaDos) {
            $sonIguales = false;
        }
        return $sonIguales;
    }

    public function existeEmail($email)
    {
        $sql = "SELECT usuario_id FROM usuarios WHERE email = ?";
        $resultado = $this->conexion->preparedQuery($sql, 's', [$email]);

        return !empty($resultado);
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

    public function esAnioNacimientoValido($anioNacimiento)
    {
        $anioValido = true;
        try {
            $anioNacimientoInt = (int)$anioNacimiento;
            if ($anioNacimientoInt < 1900) {
                $anioValido = false;
            }
        } catch (\Throwable $th) {
            $anioValido = false;
        }
        return $anioValido;
    }

    public function validarCuenta($token)
    {
        $sql = "UPDATE usuarios SET esta_verificado = 1, token_verificacion = NULL 
                WHERE token_verificacion = ?";
        // preparedQuery debe devolver true si el UPDATE fue exitoso (y afectó filas)
        return $this->conexion->preparedQuery($sql, 's', [$token]) === true;
    }

    private function obtenerOCrear($tabla, $nombre, $extra = [])
    {

        $columnas = ['nombre'];
        $valores = [$nombre];
        $tipos = 's';


        foreach ($extra as $col => $val) {
            $columnas[] = $col;
            $valores[] = $val;
            $tipos .= is_int($val) ? 'i' : 's';
        }

        $placeholders = implode(',', array_fill(0, count($columnas), '?'));
        $tipos = str_repeat('s', count($valores));

        $sqlInsert = "INSERT IGNORE INTO $tabla (" . implode(',', $columnas) . ") VALUES ($placeholders)";
        $this->conexion->preparedQuery($sqlInsert, $tipos, $valores);

        $where = [];
        $whereValores = [];
        foreach ($columnas as $i => $col) {
            $where[] = "$col = ?";
            $whereValores[] = $valores[$i];
        }

        $idColumn = [
            'paises' => 'pais_id',
            'provincias' => 'provincia_id',
            'ciudades' => 'ciudad_id'
        ][$tabla] ?? "{$tabla}_id";

        $sqlSelect = "SELECT $idColumn as id FROM $tabla WHERE " . implode(' AND ', $where) . " LIMIT 1";
        $resultado = $this->conexion->preparedQuery($sqlSelect, $tipos, $whereValores);

        return $resultado[0]['id'] ?? null;
    }

    public function getUsuarioConUbicacion($usuario_id)
    {
        $sql = "SELECT
                    u.*,
                    c.nombre as ciudad_nombre,
                    p.nombre as provincia_nombre,
                    pa.nombre as pais_nombre
                FROM usuarios u
                LEFT JOIN ciudades c ON u.ciudad_id = c.ciudad_id
                LEFT JOIN provincias p ON c.provincia_id = p.provincia_id
                LEFT JOIN paises pa ON p.pais_id = pa.pais_id
                WHERE u.usuario_id = ? AND u.esta_verificado = TRUE";

        $resultado = $this->conexion->preparedQuery($sql, 'i', [$usuario_id]);

        if (!empty($resultado)) {
            return $resultado[0];
        }
        return null;
    }

    public function obtenerRango($puntos)
    {
        $basePath = "imagenes/rangos/";
        if ($puntos > 300) {
            return [
                "nombre" => "Diamante",
                "imagen" => $basePath . "diamante.png",
                "color" => "text-info" // Un color de Bootstrap
            ];
        } elseif ($puntos > 200) {
            return [
                "nombre" => "Platino",
                "imagen" => $basePath . "platino.png",
                "color" => "text-primary"
            ];
        } elseif ($puntos > 100) {
            return [
                "nombre" => "Oro",
                "imagen" => $basePath . "oro.png",
                "color" => "text-warning"
            ];
        } else {
            return [
                "nombre" => "Bronce",
                "imagen" => $basePath . "bronce.png",
                "color" => "text-secondary"
            ];
        }
    }
}
