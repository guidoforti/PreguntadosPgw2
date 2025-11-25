<?php

class PreguntasModel
{
    private $conexion;

    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }

    public function sugerirPregunta($textoPregunta, $categoriaId, $opciones, $respuestaCorrectaIndex, $usuarioId)
    {

        $sqlPregunta = "INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, fecha_creacion) VALUES (?, ?, 'pendiente', ?, NOW())";
        $tiposPregunta = 'isi'; // integer, string, integer
        $paramsPregunta = [$categoriaId, $textoPregunta, $usuarioId];

        $resultado = $this->conexion->preparedQuery($sqlPregunta, $tiposPregunta, $paramsPregunta);

        if ($resultado !== true) {
            return ['error' => 'Falló la inserción de la pregunta principal.'];
        }


        $preguntaId = $this->conexion->getInsertId();

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

    public function recalcularDificultadDePreguntasDePartida($listaDeIds)
    {
        $TOTAL_PARA_PONDERAR = 10;
        $TOTAL_CORRECTA_PARA_PONDERAR = 5;

        $listaDeIds = array_values(array_unique(array_filter($listaDeIds, 'is_numeric')));
        $listaDeIds = array_map('intval', $listaDeIds);
        $in = implode(',', $listaDeIds);

        $sqlTotales = "SELECT pregunta_id, SUM(fue_correcta) AS respuestas_correctas, COUNT(*) AS respuestas_totales
                   FROM respuestas_usuario
                   WHERE pregunta_id IN ($in)
                   GROUP BY pregunta_id";

        $totales = $this->conexion->query($sqlTotales);

        $sqlUpdate = "UPDATE preguntas SET dificultad = ? WHERE pregunta_id = ?";
        $contador = 0;
        if ($totales !== null && is_array($totales)) {
            foreach ($totales as $linea) {
                $preguntaId = $linea['pregunta_id'];
                $totalDeRespuestas = $linea['respuestas_totales'];
                $totalDeRespuestasCorrectas = $linea['respuestas_correctas'];

                $totalPonderado = $TOTAL_PARA_PONDERAR + $totalDeRespuestas;
                $correctasPonderadas = $TOTAL_CORRECTA_PARA_PONDERAR + $totalDeRespuestasCorrectas;

                $ratioCorrectas = $correctasPonderadas / $totalPonderado;
                $nuevaDificultad = round(1.0 - $ratioCorrectas, 2);

                $this->conexion->preparedQuery($sqlUpdate, 'di', [$nuevaDificultad, $preguntaId]);
                $contador++;
            }
        }

        return "RECALCULO COMPLETADO . $contador PREGUNTAS ACTUALIZADAS";
    }

    public function getCategorias()
    {
        $sql = "SELECT categoria_id, nombre, color_hex FROM categorias ORDER BY nombre";
        return $this->conexion->preparedQuery($sql);
    }

    public function getPreguntasPendientes()
    {
        $sql = "SELECT p.*, u.nombre_usuario as creador 
                FROM preguntas p 
                LEFT JOIN usuarios u ON p.creada_por_usuario_id = u.usuario_id
                WHERE p.estado = 'pendiente'";

        return $this->conexion->preparedQuery($sql);
    }

    public function getReportesPendientes()
    {
        $sql = "SELECT pr.reporte_id, pr.pregunta_id, pr.motivo, p.texto_pregunta, u.nombre_usuario as reportador
                FROM preguntas_reportadas pr
                JOIN preguntas p ON pr.pregunta_id = p.pregunta_id
                JOIN usuarios u ON pr.reportado_por_usuario_id = u.usuario_id
                WHERE pr.estado = 'reportado'";

        return $this->conexion->preparedQuery($sql);
    }

    public function aprobarPregunta($preguntaId, $editorId)
    {
        $sql = "UPDATE preguntas 
                SET estado = 'activa', aprobado_por_usuario_id = ? 
                WHERE pregunta_id = ?";

        return $this->conexion->preparedQuery($sql, 'ii', [$editorId, $preguntaId]) === true;
    }

    public function denegarPregunta($preguntaId)
    {
        $sql = "UPDATE preguntas SET estado = 'rechazada' WHERE pregunta_id = ?";

        return $this->conexion->preparedQuery($sql, 'i', [$preguntaId]) === true;
    }

    public function aprobarReporte($reporteId, $editorId){
        $sql_get_id = "SELECT pregunta_id FROM preguntas_reportadas WHERE reporte_id = ?";
        $resultado = $this->conexion->preparedQuery($sql_get_id, 'i', [$reporteId]);
        $preguntaId = $resultado[0]['pregunta_id'] ?? null;

        if (!$preguntaId) {
            return false;
        }

        $sql_reporte = "UPDATE preguntas_reportadas 
                        SET estado = 'aprobado', revisado_por_usuario_id = ? 
                        WHERE reporte_id = ?";
        $this->conexion->preparedQuery($sql_reporte, 'ii', [$editorId, $reporteId]);

        return true;
    }

    public function rechazarReporte($reporteId, $editorId){
        $sql_get_id = "SELECT pregunta_id FROM preguntas_reportadas WHERE reporte_id = ?";
        $resultado = $this->conexion->preparedQuery($sql_get_id, 'i', [$reporteId]);
        $preguntaId = $resultado[0]['pregunta_id'] ?? null;

        if (!$preguntaId) {
            return false;
        }

        $sql_reporte = "UPDATE preguntas_reportadas 
                        SET estado = 'rechazado', revisado_por_usuario_id = ? 
                        WHERE reporte_id = ?";
        $this->conexion->preparedQuery($sql_reporte, 'ii', [$editorId, $reporteId]);

        $sql_pregunta = "UPDATE preguntas SET estado = 'activa' WHERE pregunta_id = ?";
        $this->conexion->preparedQuery($sql_pregunta, 'i', [$preguntaId]);

        return true;
    }

    public function getCategoriasOrderById()
    {
        $sql = "SELECT categoria_id, nombre, color_hex FROM categorias ORDER BY categoria_id";
        return $this->conexion->preparedQuery($sql);
    }

    public function crearCategoria($nombre, $color_hex){

        $sql = "INSERT INTO categorias (nombre, color_hex) VALUES (?, ?)";
        $resultado = $this->conexion->preparedQuery($sql, 'ss', [$nombre, $color_hex]);
        if($resultado === true){
            return ['success' => true, 'categoria_id' => $this->conexion->getInsertId()];
        }
        return ['error' => 'No se pudo crear la categoría.'];
    }

    public function actualizarCategoria($categoriaId, $nombre, $color_hex)
    {
        $sql = "UPDATE categorias SET nombre = ?, color_hex = ? WHERE categoria_id = ?";
        $resultado = $this->conexion->preparedQuery($sql, 'ssi', [$nombre, $color_hex, $categoriaId]);

        if ($resultado === true) {
            return ['success' => true];
        }
        return ['error' => 'No se pudo actualizar la categoría.'];
    }

    public function eliminarCategoria($categoriaId)
    {
        $sql_check = "SELECT COUNT(*) as count FROM preguntas WHERE categoria_id = ?";

        $res_check = $this->conexion->preparedQuery($sql_check, 'i', [$categoriaId]);
        $count = $res_check[0]['count'] ?? 0;

        if ($count > 0) {
            return ['error' => "No se puede eliminar la categoría porque existen {$count} preguntas asociadas."];
        }

        $sql = "DELETE FROM categorias WHERE categoria_id = ?";
        $resultado = $this->conexion->preparedQuery($sql, 'i', [$categoriaId]);

        if ($resultado === true) {
            return ['success' => true];
        } else {
            return ['error' => 'Error inesperado al intentar eliminar la categoría.'];
        }
    }

}