<?php

class PerfilController
{
    private $modelUsuarios;
    private $modelRanking;
    private $renderer;

    public function __construct($modelUsuarios, $modelRanking, $renderer)
    {
        $this->modelUsuarios = $modelUsuarios;
        $this->modelRanking = $modelRanking;
        $this->renderer = $renderer;
    }

    public function base()
    {
        $this->ver();
    }

    public function ver()
    {
        SecurityHelper::checkRole(['usuario', 'editor', 'admin']);

        $usuario_id = $_GET['usuario_id'] ?? $_SESSION['usuario_id'] ?? null;

        if (!$usuario_id) {
            header("Location: /");
            exit;
        }

        $usuario = $this->modelUsuarios->getUsuarioConUbicacion($usuario_id);

        if (!$usuario) {
            header("Location: /");
            exit;
        }

        $estadisticas = $this->modelRanking->getEstadisticasUsuario($usuario_id);
        if ($estadisticas && is_array($estadisticas) && !empty($estadisticas)) {
            $estadisticas = $estadisticas[0];
        } else {
            $estadisticas = null;
        }

        $historial = $this->modelRanking->getHistorialEnriquecido($usuario_id);

        $rango = $this->modelUsuarios->obtenerRango($usuario['ranking']);

        $ubicacion_completa = implode(', ', array_filter([
            $usuario['ciudad_nombre'],
            $usuario['provincia_nombre'],
            $usuario['pais_nombre']
        ]));

        $anioActual = date('Y');
        $edad = $anioActual - $usuario['ano_nacimiento'];

        $sexoMap = [
            'M' => 'Masculino',
            'F' => 'Femenino',
            'X' => 'No especificado'
        ];
        $sexoTexto = $sexoMap[$usuario['sexo']] ?? 'No especificado';

        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https://' : 'http://';
        $host = $_SERVER['HTTP_HOST'];
        $profile_url = $protocol . $host . '/perfil/ver?usuario_id=' . $usuario_id;

        $qr_url = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=' . urlencode($profile_url);

        $esMiPerfil = ($_SESSION['usuario_id'] ?? null) === $usuario_id;

        $data = [
            'usuario' => [
                'usuario_id' => $usuario['usuario_id'],
                'nombre_completo' => $usuario['nombre_completo'],
                'nombre_usuario' => $usuario['nombre_usuario'],
                'ranking' => $usuario['ranking'],
                'url_foto_perfil' => $usuario['url_foto_perfil'],
                'ciudad_nombre' => $usuario['ciudad_nombre'],
                'provincia_nombre' => $usuario['provincia_nombre'],
                'pais_nombre' => $usuario['pais_nombre'],
                'ubicacion_completa' => $ubicacion_completa,
                'rango' => $rango,
                'edad' => $edad,
                'sexo' => $sexoTexto
            ],
            'estadisticas' => $estadisticas,
            'historial' => $historial,
            'profile_url' => $profile_url,
            'qr_url' => $qr_url,
            'esMiPerfil' => $esMiPerfil
        ];

        $this->renderer->render("perfil", $data);
    }

    public function editarForm()
    {
        SecurityHelper::checkRole(['usuario', 'editor', 'admin']);

        $usuario_id = $_SESSION['usuario_id'] ?? null;

        if (!$usuario_id) {
            header("Location: /");
            exit;
        }

        $usuario = $this->modelUsuarios->getUsuarioConUbicacion($usuario_id);

        if (!$usuario) {
            header("Location: /");
            exit;
        }

        $data = [
            'usuario' => [
                'usuario_id' => $usuario['usuario_id'],
                'nombre_completo' => $usuario['nombre_completo'],
                'nombre_usuario' => $usuario['nombre_usuario'],
                'email' => $usuario['email'],
                'ano_nacimiento' => $usuario['ano_nacimiento'],
                'sexo' => $usuario['sexo'],
                'url_foto_perfil' => $usuario['url_foto_perfil'],
                'ciudad_nombre' => $usuario['ciudad_nombre'],
                'provincia_nombre' => $usuario['provincia_nombre'],
                'pais_nombre' => $usuario['pais_nombre']
            ],
            'sexo_M' => $usuario['sexo'] === 'M' ? 'checked' : '',
            'sexo_F' => $usuario['sexo'] === 'F' ? 'checked' : '',
            'sexo_X' => $usuario['sexo'] === 'X' ? 'checked' : '',
            'anioActual' => date('Y'),
            'exito' => null,
            'error' => null
        ];

        if (isset($_SESSION['flash_success'])) {
            $data['exito'] = $_SESSION['flash_success'];
            unset($_SESSION['flash_success']);
        }
        if (isset($_SESSION['flash_error'])) {
            $data['error'] = $_SESSION['flash_error'];
            unset($_SESSION['flash_error']);
        }

        $this->renderer->render("editarPerfil", $data);
    }

    public function actualizar()
    {
        SecurityHelper::checkRole(['usuario', 'editor', 'admin']);

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            header("Location: /perfil/editarForm");
            exit;
        }

        $usuario_id = $_SESSION['usuario_id'] ?? null;

        if (!$usuario_id) {
            header("Location: /");
            exit;
        }

        $nombreCompleto   = $_POST['nombreCompleto'] ?? null;
        $anioNacimiento   = $_POST['anioNacimiento'] ?? null;
        $sexo             = $_POST['sexo'] ?? null;
        $email            = $_POST['email'] ?? null;
        $nombreUsuario    = $_POST['nombreUsuario'] ?? null;
        $contraseniaUno   = $_POST['password'] ?? null;
        $contraseniaDos   = $_POST['confirmPassword'] ?? null;
        $imagen           = $_FILES['fotoPerfil'] ?? null;
        $paisNombre       = $_POST['paisNombre'] ?? null;
        $provinciaNombre  = $_POST['provinciaNombre'] ?? null;
        $ciudadNombre     = $_POST['ciudadNombre'] ?? null;

        $campos = compact('nombreCompleto', 'anioNacimiento', 'sexo', 'email', 'nombreUsuario');
        foreach ($campos as $clave => $valor) {
            if (empty($valor)) {
                $_SESSION['flash_error'] = "El campo '$clave' es obligatorio.";
                header("Location: /perfil/editarForm");
                exit;
            }
        }

        $resultado = $this->modelUsuarios->actualizarPerfil(
            $usuario_id,
            $nombreCompleto,
            $anioNacimiento,
            $sexo,
            $email,
            $nombreUsuario,
            $contraseniaUno,
            $contraseniaDos,
            $imagen,
            $paisNombre,
            $provinciaNombre,
            $ciudadNombre
        );

        if (isset($resultado['error'])) {
            $_SESSION['flash_error'] = $resultado['error'];
            header("Location: /perfil/editarForm");
        } elseif (isset($resultado['success'])) {
            $_SESSION['flash_success'] = $resultado['success'];
            header("Location: /perfil/ver");
        } else {
            $_SESSION['flash_error'] = "Error desconocido al actualizar el perfil.";
            header("Location: /perfil/editarForm");
        }
        exit;
    }
}