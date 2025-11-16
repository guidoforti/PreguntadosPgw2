<?php

class AdminModel
{
    private $conexion;

    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }

    /**
     * Obtiene el total de jugadores registrados
     */
    public function obtenerTotalJugadores($filtroFecha = null)
    {
        $sql = "SELECT COUNT(*) as total FROM usuarios WHERE rol = 'usuario'";
        $sql .= $this->aplicarFiltroFecha('usuarios.fecha_creacion', $filtroFecha);

        $resultado = $this->conexion->query($sql);
        if (is_array($resultado) && isset($resultado['error'])) {
            return 0;
        }
        return ($resultado && is_array($resultado) && count($resultado) > 0) ? $resultado[0]['total'] : 0;
    }

    /**
     * Obtiene el total de partidas jugadas
     */
    public function obtenerTotalPartidasJugadas($filtroFecha = null)
    {
        $sql = "SELECT COUNT(*) as total FROM partidas_usuario WHERE estado IN ('finalizada', 'perdida')";
        $sql .= $this->aplicarFiltroFecha('partidas_usuario.fecha_fin', $filtroFecha);

        $resultado = $this->conexion->query($sql);
        if (is_array($resultado) && isset($resultado['error'])) {
            return 0;
        }
        return ($resultado && is_array($resultado) && count($resultado) > 0) ? $resultado[0]['total'] : 0;
    }

    /**
     * Obtiene el total de preguntas activas en el juego
     * Nota: La tabla preguntas no tiene columna de fecha, por lo que no se filtra por período
     */
    public function obtenerTotalPreguntasEnJuego($filtroFecha = null)
    {
        $sql = "SELECT COUNT(*) as total FROM preguntas WHERE estado = 'activa'";

        $resultado = $this->conexion->query($sql);
        if (is_array($resultado) && isset($resultado['error'])) {
            return 0;
        }
        return ($resultado && is_array($resultado) && count($resultado) > 0) ? $resultado[0]['total'] : 0;
    }

    /**
     * Obtiene el total de preguntas creadas
     * Nota: La tabla preguntas no tiene columna de fecha, por lo que no se filtra por período
     */
    public function obtenerTotalPreguntasCreadas($filtroFecha = null)
    {
        $sql = "SELECT COUNT(*) as total FROM preguntas";

        $resultado = $this->conexion->query($sql);
        if (is_array($resultado) && isset($resultado['error'])) {
            return 0;
        }
        return ($resultado && is_array($resultado) && count($resultado) > 0) ? $resultado[0]['total'] : 0;
    }

    /**
     * Obtiene el total de usuarios nuevos en el período especificado
     */
    public function obtenerUsuariosNuevos($filtroFecha = null)
    {
        $sql = "SELECT COUNT(*) as total FROM usuarios WHERE rol = 'usuario'";
        $sql .= $this->aplicarFiltroFecha('usuarios.fecha_creacion', $filtroFecha);

        $resultado = $this->conexion->query($sql);
        if (is_array($resultado) && isset($resultado['error'])) {
            return 0;
        }
        return ($resultado && is_array($resultado) && count($resultado) > 0) ? $resultado[0]['total'] : 0;
    }

    /**
     * Obtiene el porcentaje de respuestas correctas por usuario
     */
    public function obtenerPorcentajeRespuestasCorrectasPorUsuario($filtroFecha = null)
    {
        $sql = "SELECT
                    u.usuario_id,
                    u.nombre_usuario,
                    COUNT(ru.respuesta_usuario_id) as total_respuestas,
                    SUM(CASE WHEN ru.fue_correcta = TRUE THEN 1 ELSE 0 END) as respuestas_correctas,
                    ROUND(
                        (SUM(CASE WHEN ru.fue_correcta = TRUE THEN 1 ELSE 0 END) / COUNT(ru.respuesta_usuario_id)) * 100, 2
                    ) as porcentaje_acierto
                FROM usuarios u
                LEFT JOIN respuestas_usuario ru ON u.usuario_id = ru.usuario_id";

        if ($filtroFecha) {
            $sql .= " WHERE 1=1 " . $this->aplicarFiltroFecha('ru.fecha_respuesta', $filtroFecha);
        }

        $sql .= " GROUP BY u.usuario_id, u.nombre_usuario
                 HAVING COUNT(ru.respuesta_usuario_id) > 0
                 ORDER BY porcentaje_acierto DESC";

        $resultado = $this->conexion->query($sql);
        if (is_array($resultado) && isset($resultado['error'])) {
            return [];
        }
        return is_array($resultado) ? $resultado : [];
    }

    /**
     * Obtiene el número de usuarios por país
     */
    public function obtenerUsuariosPorPais($filtroFecha = null)
    {
        $sql = "SELECT
                    p.nombre as pais,
                    COUNT(u.usuario_id) as cantidad_usuarios
                FROM usuarios u
                INNER JOIN ciudades c ON u.ciudad_id = c.ciudad_id
                INNER JOIN provincias pr ON c.provincia_id = pr.provincia_id
                INNER JOIN paises p ON pr.pais_id = p.pais_id
                WHERE u.rol = 'usuario'";

        if ($filtroFecha) {
            $sql .= $this->aplicarFiltroFecha('u.fecha_creacion', $filtroFecha);
        }

        $sql .= " GROUP BY p.pais_id, p.nombre
                 ORDER BY cantidad_usuarios DESC";

        $resultado = $this->conexion->query($sql);
        if (is_array($resultado) && isset($resultado['error'])) {
            return [];
        }
        return is_array($resultado) ? $resultado : [];
    }

    /**
     * Obtiene el número de usuarios por sexo
     */
    public function obtenerUsuariosPorSexo($filtroFecha = null)
    {
        $sql = "SELECT
                    u.sexo,
                    COUNT(u.usuario_id) as cantidad_usuarios
                FROM usuarios u
                WHERE u.rol = 'usuario' AND u.sexo IS NOT NULL";

        if ($filtroFecha) {
            $sql .= $this->aplicarFiltroFecha('u.fecha_creacion', $filtroFecha);
        }

        $sql .= " GROUP BY u.sexo
                 ORDER BY cantidad_usuarios DESC";

        $resultado = $this->conexion->query($sql);
        if (is_array($resultado) && isset($resultado['error'])) {
            return [];
        }
        return is_array($resultado) ? $resultado : [];
    }

    /**
     * Obtiene el número de usuarios por grupo de edad
     * Menores: < 18, Medio: 18-64, Jubilados: 65+
     */
    public function obtenerUsuariosPorGrupoEdad($filtroFecha = null)
    {
        $anioActual = date('Y');

        $sql = "SELECT
                    CASE
                        WHEN ({$anioActual} - ano_nacimiento) < 18 THEN 'Menores'
                        WHEN ({$anioActual} - ano_nacimiento) BETWEEN 18 AND 64 THEN 'Medio'
                        WHEN ({$anioActual} - ano_nacimiento) >= 65 THEN 'Jubilados'
                        ELSE 'Desconocido'
                    END as grupo_edad,
                    COUNT(usuario_id) as cantidad_usuarios
                FROM usuarios
                WHERE rol = 'usuario'";

        if ($filtroFecha) {
            $sql .= $this->aplicarFiltroFecha('fecha_creacion', $filtroFecha);
        }

        $sql .= " GROUP BY grupo_edad
                 ORDER BY
                    CASE
                        WHEN grupo_edad = 'Menores' THEN 1
                        WHEN grupo_edad = 'Medio' THEN 2
                        WHEN grupo_edad = 'Jubilados' THEN 3
                        ELSE 4
                    END";

        $resultado = $this->conexion->query($sql);
        if (is_array($resultado) && isset($resultado['error'])) {
            return [];
        }
        return is_array($resultado) ? $resultado : [];
    }

    /**
     * Obtiene las estadísticas del dashboard (resumen general)
     */
    public function obtenerEstadisticasGenerales($filtroFecha = null)
    {
        return [
            'totalJugadores' => $this->obtenerTotalJugadores($filtroFecha),
            'totalPartidasJugadas' => $this->obtenerTotalPartidasJugadas($filtroFecha),
            'totalPreguntasEnJuego' => $this->obtenerTotalPreguntasEnJuego($filtroFecha),
            'totalPreguntasCreadas' => $this->obtenerTotalPreguntasCreadas($filtroFecha),
            'usuariosNuevos' => $this->obtenerUsuariosNuevos($filtroFecha),
        ];
    }

    /**
     * Aplica un filtro de fecha según el tipo especificado
     * Tipos: 'dia', 'semana', 'mes', 'año'
     */
    private function aplicarFiltroFecha($campo, $tipoFiltro = null, $conAnd = true)
    {
        if (!$tipoFiltro) {
            return '';
        }

        $prefijo = $conAnd ? ' AND ' : ' WHERE ';

        switch ($tipoFiltro) {
            case 'dia':
                return $prefijo . "DATE({$campo}) = CURDATE()";
            case 'semana':
                return $prefijo . "YEARWEEK({$campo}) = YEARWEEK(NOW())";
            case 'mes':
                return $prefijo . "YEAR({$campo}) = YEAR(NOW()) AND MONTH({$campo}) = MONTH(NOW())";
            case 'año':
                return $prefijo . "YEAR({$campo}) = YEAR(NOW())";
            default:
                return '';
        }
    }
}
