<?php

class RankingModel
{
    private $conexion;

    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }

    public function getRankingGlobal($limite = 100)
    {
        $sql = "SELECT usuario_id, nombre_usuario, ranking, url_foto_perfil
                FROM usuarios
                WHERE esta_verificado = TRUE
                ORDER BY ranking DESC
                LIMIT ?";

        return $this->conexion->preparedQuery($sql, 'i', [$limite]);
    }

    public function getHistorialUsuario($usuario_id, $limite = 100)
    {
        $sql = "SELECT partida_id, puntaje, estado, fecha_inicio, fecha_fin
                FROM partidas_usuario
                WHERE usuario_id = ?
                ORDER BY fecha_inicio DESC
                LIMIT ?";

        return $this->conexion->preparedQuery($sql, 'ii', [$usuario_id, $limite]);
    }

    public function getEstadisticasUsuario($usuario_id)
    {
        $sql = "SELECT
                    COUNT(*) as total_partidas,
                    SUM(CASE WHEN estado = 'finalizada' THEN 1 ELSE 0 END) as victorias,
                    ROUND(AVG(puntaje), 1) as puntaje_promedio,
                    MAX(puntaje) as mejor_puntaje
                FROM partidas_usuario
                WHERE usuario_id = ?";

        return $this->conexion->preparedQuery($sql, 'i', [$usuario_id]);
    }

    public function getHistorialEnriquecido($usuario_id, $limite = 100)
    {
        $mapaPuntuacion = [
            0 => -15, 1 => -10, 2 => -10, 3 => -5, 4 => -5,
            5 => -5, 6 => 5, 7 => 5, 8 => 5, 9 => 10, 10 => 15
        ];

        $historial = $this->getHistorialUsuario($usuario_id, $limite);
        $historialEnriquecido = [];

        if ($historial && is_array($historial)) {
            foreach ($historial as $partida) {
                $fechaInicio = strtotime($partida['fecha_inicio']);
                $fechaFin = $partida['fecha_fin'] ? strtotime($partida['fecha_fin']) : null;
                $duracion = "En curso";
                $es_en_curso = false;

                if ($fechaFin) {
                    $segundos = $fechaFin - $fechaInicio;
                    $minutos = floor($segundos / 60);
                    $segs = $segundos % 60;
                    $duracion = "{$minutos}m {$segs}s";
                }

                $estado = $partida['estado'];
                $badge_clase = 'secondary';
                $resultado_texto = 'Interrumpida';
                $puntaje = $partida['puntaje'];
                $puntos_ranking = $mapaPuntuacion[$puntaje] ?? 0;
                $puntos_signo = ($puntos_ranking >= 0) ? '+' : '-';
                $puntos_clase = ($puntos_ranking >= 0) ? 'text-success' : 'text-danger';

                if ($estado === 'finalizada') {
                    $badge_clase = 'success';
                    $resultado_texto = 'Victoria';
                } elseif ($estado === 'perdida') {
                    $badge_clase = 'danger';
                    $resultado_texto = 'Derrota';
                } elseif ($estado === 'abandonada') {
                    $badge_clase = 'danger';
                    $resultado_texto = 'Abandonada';
                    $puntos_ranking = abs($mapaPuntuacion[0]);
                    $puntos_signo = '-';
                    $puntos_clase = 'text-danger';
                } elseif ($estado === 'en_curso') {
                    // Esta es la partida ACTIVA actual
                    $badge_clase = 'secondary';
                    $resultado_texto = 'Interrumpida';
                    $duracion = "En curso";
                    $puntos_ranking = 0;
                    $puntos_signo = '';
                    $puntos_clase = 'text-muted';
                    $es_en_curso = true;
                }

                $fecha_formateada = date('M d, H:i', $fechaInicio);

                $historialEnriquecido[] = [
                    'partida_id' => $partida['partida_id'],
                    'puntaje' => $puntaje,
                    'estado' => $estado,
                    'fecha_formateada' => $fecha_formateada,
                    'duracion' => $duracion,
                    'puntos_ranking' => abs($puntos_ranking),
                    'puntos_signo' => $puntos_signo,
                    'puntos_clase' => $puntos_clase,
                    'badge_clase' => $badge_clase,
                    'resultado_texto' => $resultado_texto,
                    'es_en_curso' => $es_en_curso
                ];
            }
        }

        return $historialEnriquecido;
    }
}