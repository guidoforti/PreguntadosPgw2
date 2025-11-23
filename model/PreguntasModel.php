<?php

class PreguntasModel
{
    private $conexion;
    private $archivoLogCron = __DIR__ . '/../scripts/ultima_ejecucion.txt';

    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }


    /**
     * Inserta la pregunta y sus 4 opciones de respuesta.
     */
    public function sugerirPregunta($textoPregunta, $categoriaId, $opciones, $respuestaCorrectaIndex, $usuarioId)
    {

        // 1. Insertar la pregunta (estado = 'pendiente')
        $sqlPregunta = "INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, fecha_creacion) VALUES (?, ?, 'pendiente', ?, NOW())";
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


    /* funcion destinada a ejecutar un scripts
   que corre una tarea como si fuese un job
   */
    /*    public function debeEjecutarseElCronManual($segundosDeExpiracion = 3600)
        {

            if (!file_exists($this->archivoLogCron)) {
                // si nunca corrio, lo corremos.
                return true;
            }
            // si ya se ejecuto, del txt obtengo hace cuantos tiempo
            $ultimaEjecucion = (int)file_get_contents($this->archivoLogCron);
            //obtengo el tiempo actual
            $ahora = time();
            //retorno true o false si pasaron mas de 3600 segundos ( 1 hora )
            return ($ahora - $ultimaEjecucion) > $segundosDeExpiracion;
        }*/
    /*  public function marcarRecalculoComoEjecutado()
      {
          //escribimos el time en donde se ejecuto por ultima vez el archivo
          //el lock ex nos bloquea el archivo para que no se ejecute
          $directorio = dirname($this->archivoLogCron);
          if (!is_dir($directorio)) {
              mkdir($directorio, 0777, true);
          }
          file_put_contents($this->archivoLogCron, time(), LOCK_EX);
      }*/

    public function recalcularDificultadDePreguntasDePartida($listaDeIds)
    {
        //  $this->marcarRecalculoComoEjecutado();

        /*constantes para falsear preguntas nunca respuestas (evita que una pregunta que nunca se contesto)
        al ser contestada mal o bien por primera vez , tenga una dificultad del 100 o  0 %
        */
        $TOTAL_PARA_PONDERAR = 10;
        $TOTAL_CORRECTA_PARA_PONDERAR = 5;

        // Normalizar: quitar no numéricos, únicos y forzar enteros
        $listaDeIds = array_values(array_unique(array_filter($listaDeIds, 'is_numeric')));
        $listaDeIds = array_map('intval', $listaDeIds);
        // Construir IN (...) seguro porque todos los items ya son enteros
        $in = implode(',', $listaDeIds);

        // Obtener totales solo para los ids solicitados
        $sqlTotales = "SELECT pregunta_id, SUM(fue_correcta) AS respuestas_correctas, COUNT(*) AS respuestas_totales
                   FROM respuestas_usuario
                   WHERE pregunta_id IN ($in)
                   GROUP BY pregunta_id";

        $totales = $this->conexion->query($sqlTotales);
        /* ejemplo de respuesta , basicamente agrupámos las preguntas por su id, vemos la cantidad total de respuestas y cantidad de aciertos
        [ 'pregunta_id' => 1, 'respuestas_correctas' => 90, 'respuestas_totales' => 150 ],
        [ 'pregunta_id' => 2, 'respuestas_correctas' => 30, 'respuestas_totales' => 40 ],
        [ 'pregunta_id' => 3, 'respuestas_correctas' => 5,  'respuestas_totales' => 110 ]
         * */

        $sqlUpdate = "UPDATE preguntas SET dificultad = ? WHERE pregunta_id = ?";
        $contador = 0;
        // Validar que $totales no sea null antes de hacer foreach
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