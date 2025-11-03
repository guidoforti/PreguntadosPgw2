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

        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https://' : 'http://';
        $host = $_SERVER['HTTP_HOST'];
        $profile_url = $protocol . $host . '/perfil/ver?usuario_id=' . $usuario_id;

        $qr_url = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=' . urlencode($profile_url);

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
                'rango' => $rango
            ],
            'estadisticas' => $estadisticas,
            'historial' => $historial,
            'profile_url' => $profile_url,
            'qr_url' => $qr_url
        ];

        $this->renderer->render("perfil", $data);
    }
}