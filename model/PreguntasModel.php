<?php
// model/PreguntasModel.php

class PreguntasModel {
    private $conexion;

    public function __construct($conexion) {
        $this->conexion = $conexion;
    }

    public function getCategorias() {
        $sql = "SELECT categoria_id, nombre FROM categorias ORDER BY nombre";
        return $this->conexion->preparedQuery($sql); // Asume SELECT sin parámetros
    }

    public function sugerirPregunta($textoPregunta, $categoriaId, $opciones, $respuestaCorrectaIndex, $usuarioId) {

        $sqlPregunta = "INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id) VALUES (?, ?, 'pendiente', ?)";
        $tiposPregunta = 'isi';
        $paramsPregunta = [$categoriaId, $textoPregunta, $usuarioId];

        $resultado = $this->conexion->preparedQuery($sqlPregunta, $tiposPregunta, $paramsPregunta);

        if ($resultado === true) {
            return ['success' => 'Sugerencia enviada.'];
        }

        return ['error' => 'Falló la inserción de la pregunta.'];
    }

    public function getPreguntasPendientes() {
        $sql = "SELECT p.*, u.nombre_usuario as creador 
                FROM preguntas p 
                LEFT JOIN usuarios u ON p.creada_por_usuario_id = u.usuario_id
                WHERE p.estado = 'pendiente'";

        return $this->conexion->preparedQuery($sql);
    }

    public function getReportesPendientes() {
        $sql = "SELECT pr.*, p.texto_pregunta 
                FROM preguntas_reportadas pr
                JOIN preguntas p ON pr.pregunta_id = p.pregunta_id
                WHERE pr.estado = 'reportado'";

        return $this->conexion->preparedQuery($sql);
    }

    public function aprobarPregunta($preguntaId, $editorId) {
        $sql = "UPDATE preguntas 
                SET estado = 'activa', aprobado_por_usuario_id = ? 
                WHERE pregunta_id = ?";

        return $this->conexion->preparedQuery($sql, 'ii', [$editorId, $preguntaId]);
    }

    public function denegarPregunta($preguntaId) {
        $sql = "UPDATE preguntas SET estado = 'rechazada' WHERE pregunta_id = ?";

        return $this->conexion->preparedQuery($sql, 'i', [$preguntaId]);
    }
}