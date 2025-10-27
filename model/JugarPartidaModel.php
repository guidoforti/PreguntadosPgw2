<?php

class JugarPartidaModel
{

    private $conexion;

    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }

    public function crearPartida($usuario_id){
        $sql = "INSERT INTO partidas_usuario (usuario_id, estado) VALUES (?, 'en_curso')";
        $this->conexion->preparedQuery($sql, 'i', [$usuario_id]);

        return $this->conexion->getInsertId();
    }

    public function buscarPreguntasParaPartida(){
        $sql = "SELECT pregunta_id FROM preguntas
                WHERE estado = 'activa'
                ORDER BY RAND()
                LIMIT 10";

        $resultado_query = $this->conexion->query($sql);

        $ids = [];
        foreach ($resultado_query as $fila) {
            $ids[] = $fila['pregunta_id'];
        }
        return $ids;
    }

    public function getPreguntaCompleta($pregunta_id){
        $data = [];
        $sql_pregunta = "SELECT texto_pregunta FROM preguntas WHERE pregunta_id = ?";
        $resultado_pregunta = $this->conexion->preparedQuery($sql_pregunta, 'i', [$pregunta_id]);
        $data['pregunta'] = $resultado_pregunta[0] ?? null;
        $data['pregunta_id'] = $pregunta_id;

        $sql_respuestas = "SELECT respuesta_id, texto_respuesta
                            FROM respuestas
                            WHERE pregunta_id = ?
                            ORDER BY RAND()";
        $data['respuestas'] = $this->conexion->preparedQuery($sql_respuestas, 'i', [$pregunta_id]);

        return $data;
    }

    public function procesarRespuesta($partida_id, $usuario_id, $pregunta_id, $respuesta_id, $start_time) {

        $tiempo_limite = 20;
        $tiempo_usado = time() - $start_time;

        $es_timeout = ($tiempo_usado > $tiempo_limite) || ($respuesta_id == null);

        $fue_correcta = false;

        if(!$es_timeout){
            $sql_check = "SELECT es_correcta FROM respuestas WHERE respuesta_id = ?";
            $resultado = $this->conexion->preparedQuery($sql_check, 'i', [$respuesta_id]);

            if ($resultado && $resultado[0]['es_correcta'] == 1) {
                $fue_correcta = true;
            }
        }

        $sql_insert = "INSERT INTO respuestas_usuario 
                            (usuario_id, partida_id, pregunta_id, respuesta_id, 
                             fue_correcta, fecha_respuesta, tiempo_inicio_pregunta) 
                       VALUES 
                            (?, ?, ?, ?, ?, NOW(), FROM_UNIXTIME(?))";

        $this->conexion->preparedQuery($sql_insert, 'iiiiii', [
            $usuario_id,
            $partida_id,
            $pregunta_id,
            $respuesta_id,
            $fue_correcta,
            $start_time
        ]);

        if($fue_correcta){
            $sql_update = "UPDATE partidas_usuario SET puntaje = puntaje + 1 WHERE partida_id = ?";
            $this->conexion->preparedQuery($sql_update, 'i', [$partida_id]);
        }

        return $fue_correcta;
    }

    public function cerrarPartida($partida_id, $gano){
        $estado_final = $gano ? 'finalizada' : 'perdida';

        $sql = "UPDATE partidas_usuario
                SET estado = ?, fecha_fin = NOW()
                WHERE partida_id = ?";

        $this->conexion->preparedQuery($sql, 'si', [$estado_final, $partida_id]);
    }
}