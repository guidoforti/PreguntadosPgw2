<?php

class RankingController
{
    private $model;
    private $modelUsuarios;
    private $renderer;

    public function __construct($model, $modelUsuarios, $renderer)
    {
        $this->model = $model;
        $this->modelUsuarios = $modelUsuarios;
        $this->renderer = $renderer;
    }

    public function base()
    {
        $this->verRanking();
    }

    public function verRanking()
    {
        SecurityHelper::checkRole(['usuario', 'editor', 'admin']);

        $usuarios = $this->model->getRankingGlobal();

        $usuariosConRango = [];
        $posicion = 1;

        if ($usuarios && is_array($usuarios)) {
            foreach ($usuarios as $usuario) {
                $rango = $this->modelUsuarios->obtenerRango($usuario['ranking']);

                $usuariosConRango[] = [
                    'posicion' => $posicion,
                    'usuario_id' => $usuario['usuario_id'],
                    'nombre_usuario' => $usuario['nombre_usuario'],
                    'ranking' => $usuario['ranking'],
                    'url_foto_perfil' => $usuario['url_foto_perfil'],
                    'rango' => $rango
                ];

                $posicion++;
            }
        }

        $usuario_id = $_SESSION['usuario_id'] ?? null;
        $historialEnriquecido = [];
        $estadisticas = null;
        $tienePartidas = false;

        if ($usuario_id) {
            $historialEnriquecido = $this->model->getHistorialEnriquecido($usuario_id, 10);
            $tienePartidas = count($historialEnriquecido) > 0;

            $estadisticas = $this->model->getEstadisticasUsuario($usuario_id);
            if ($estadisticas && is_array($estadisticas) && !empty($estadisticas)) {
                $estadisticas = $estadisticas[0];
            } else {
                $estadisticas = null;
            }
        }

        $data = [
            'usuarios' => $usuariosConRango,
            'totalUsuarios' => count($usuariosConRango),
            'historial' => $historialEnriquecido,
            'estadisticas' => $estadisticas,
            'tienePartidas' => $tienePartidas
        ];

        $this->renderer->render("ranking", $data);
    }
}