<?php

class PreguntasModel
{
    private $conexion;

    public function __construct($conexion) {
        $this->conexion = $conexion;
    }

    public function getCategorias() {
        $sql = "SELECT categoria_id, nombre FROM categorias ORDER BY nombre";
        return $this->conexion->preparedQuery($sql);
    }

    /**
     * Inserta la pregunta y sus 4 opciones de respuesta.
     */
    public function sugerirPregunta($textoPregunta, $categoriaId, $opciones, $respuestaCorrectaIndex, $usuarioId) {

        // 1. Insertar la pregunta (estado = 'pendiente')
        $sqlPregunta = "INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id) VALUES (?, ?, 'pendiente', ?)";
        $tiposPregunta = 'isi'; // integer, string, integer
        $paramsPregunta = [$categoriaId, $textoPregunta, $usuarioId];

        $resultado = $this->conexion->preparedQuery($sqlPregunta, $tiposPregunta, $paramsPregunta);

        if ($resultado !== true) {
            return ['error' => 'Falló la inserción de la pregunta principal.'];
        }

        // 2. Obtener el ID de la pregunta insertada (Asumimos $this->conexion->conexion es la instancia mysqli)
        $preguntaId = $this->conexion->getInsertId();

        // 3. Insertar las 4 opciones de respuesta
        $sqlRespuesta = "INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES (?, ?, ?)";

        foreach ($opciones as $index => $textoRespuesta) {
            $esCorrecta = ($index == $respuestaCorrectaIndex) ? 1 : 0;
            $tiposRespuesta = 'isi'; // integer, string, integer(boolean)
            $paramsRespuesta = [$preguntaId, $textoRespuesta, $esCorrecta];

            $res = $this->conexion->preparedQuery($sqlRespuesta, $tiposRespuesta, $paramsRespuesta);

            if ($res !== true) {
                error_log("Fallo al insertar respuesta para pregunta ID: " . $preguntaId);
            }
        }

        return ['success' => 'Sugerencia enviada y respuestas guardadas.'];
    }

    public function getPreguntasPendientes() {
        $sql = "SELECT p.*, u.nombre_usuario as creador 
                FROM preguntas p 
                LEFT JOIN usuarios u ON p.creada_por_usuario_id = u.usuario_id
                WHERE p.estado = 'pendiente'";

        return $this->conexion->preparedQuery($sql);
    }

    public function getReportesPendientes() {
        // Selecciona preguntas con reportes activos
        $sql = "SELECT pr.reporte_id, pr.pregunta_id, pr.motivo, p.texto_pregunta, u.nombre_usuario as reportador
                FROM preguntas_reportadas pr
                JOIN preguntas p ON pr.pregunta_id = p.pregunta_id
                JOIN usuarios u ON pr.reportado_por_usuario_id = u.usuario_id
                WHERE pr.estado = 'reportado'";

        return $this->conexion->preparedQuery($sql);
    }

    public function aprobarPregunta($preguntaId, $editorId) {
        $sql = "UPDATE preguntas 
                SET estado = 'activa', aprobado_por_usuario_id = ? 
                WHERE pregunta_id = ?";

        return $this->conexion->preparedQuery($sql, 'ii', [$editorId, $preguntaId]) === true;
    }

    public function denegarPregunta($preguntaId) {
        $sql = "UPDATE preguntas SET estado = 'rechazada' WHERE pregunta_id = ?";

        return $this->conexion->preparedQuery($sql, 'i', [$preguntaId]) === true;
    }
}