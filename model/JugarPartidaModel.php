<?php

class JugarPartidaModel
{

    private $conexion;
    const MAPA_PUNTUACION = [
        0 => -15,
        1 => -10,
        2 => -10,
        3 => -5,
        4 => -5,
        5 => -5,
        6 => 5,
        7 => 5,
        8 => 5,
        9 => 10,
        10 => 15
    ];

    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }

    public function crearPartida($usuario_id)
    {
        $sql = "INSERT INTO partidas_usuario (usuario_id, estado) VALUES (?, 'en_curso')";
        $this->conexion->preparedQuery($sql, 'i', [$usuario_id]);

        return $this->conexion->getInsertId();
    }

    public function finalizarPartidaAbandonada($usuario_id){
        $sql = "SELECT partida_id FROM partidas_usuario 
                WHERE usuario_id = ? AND estado = 'en_curso'";

        $partida_activa = $this->conexion->preparedQuery($sql, 'i', [$usuario_id]);

        if(empty($partida_activa)){
           return $penalizacion = 0;
        }

        $partida_id = $partida_activa[0]['partida_id'];
        $sql_finalizarPartida = "UPDATE partidas_usuario
        SET estado = 'abandonada', fecha_fin = NOW()
        WHERE partida_id = ?";

        $this->conexion->preparedQuery($sql_finalizarPartida, 'i', [$partida_id]);
        $penalizacion = self::MAPA_PUNTUACION[0] ?? -15;
        return $penalizacion;
    }

    public function buscarPreguntasParaPartida($rankingUsuario, $usuario_id, $categoria_nombre, $limite = 2)
    {
        $rangoDeDificultadDelUsuario = $this->devolverRangoDeDificultadSegunRanking($rankingUsuario);

        // con left join lo que hacemos es ver que sean preguntas no respuestas ya por ese usuario
        // calculamos el rango de dificultad para buscar segun elo del usuario

        $sql = "SELECT p.pregunta_id 
                FROM preguntas p
                JOIN categorias c ON p.categoria_id = c.categoria_id
                LEFT JOIN respuestas_usuario ru ON p.pregunta_id = ru.pregunta_id AND ru.usuario_id = ?
                WHERE p.estado = 'activa' 
                AND p.dificultad BETWEEN ? AND ?
                AND c.nombre = ?
                AND ru.pregunta_id IS NULL
                ORDER BY RAND()
                LIMIT ?";


        $preguntas_encontradas = $this->conexion->preparedQuery($sql, 'iddsi', [
            $usuario_id,
            $rangoDeDificultadDelUsuario['rangoMenor'],
            $rangoDeDificultadDelUsuario['rangoMayor'],
            $categoria_nombre,
            $limite
        ]);

        // Usamos count() sobre el array/null devuelto para ver que si existen menos de 10 preguntas para ese rango
        // si no existen, se dan  preguntas random sin importar rango
        $numeroDePreguntasEncontradas = count($preguntas_encontradas);

        if ($numeroDePreguntasEncontradas < $limite) {

            $sqlPorFaltaDePreguntas = "SELECT p.pregunta_id 
                FROM preguntas p
                JOIN categorias c ON p.categoria_id = c.categoria_id
                LEFT JOIN respuestas_usuario ru ON p.pregunta_id = ru.pregunta_id AND ru.usuario_id = ?
                WHERE p.estado = 'activa'
                AND c.nombre = ?
                AND ru.pregunta_id IS NULL 
                ORDER BY RAND()
                LIMIT ?";

            $preguntas_encontradas = $this->conexion->preparedQuery($sqlPorFaltaDePreguntas, 'isi', [$usuario_id, $categoria_nombre, $limite]);
        }

        // Extraemos los IDs del resultado final
        $ids = [];
        if (is_array($preguntas_encontradas)) {
            foreach ($preguntas_encontradas as $fila) {
                $ids[] = $fila['pregunta_id'];
            }
        }
        return $ids;
    }

    public function getPreguntaCompleta($pregunta_id) {
        $data = [];
        $sql_pregunta = "SELECT p.texto_pregunta, c.nombre AS categoria
                            FROM preguntas p
                            JOIN categorias c ON c.categoria_id = p.categoria_id
                            WHERE pregunta_id = ?";
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

    public function procesarRespuesta($partida_id, $usuario_id, $pregunta_id, $respuesta_id, $start_time)
    {

        $tiempo_limite = 20;
        $tiempo_usado = time() - $start_time;

        $es_timeout = ($tiempo_usado > $tiempo_limite) || ($respuesta_id == null);

        $fue_correcta = false;

        if (!$es_timeout) {
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

        if ($fue_correcta) {
            $sql_update = "UPDATE partidas_usuario SET puntaje = puntaje + 1 WHERE partida_id = ?";
            $this->conexion->preparedQuery($sql_update, 'i', [$partida_id]);
        }

        return $fue_correcta;
    }

    public function calcularPuntosPorPartida($preguntasAcertadas)
    {

        return self::MAPA_PUNTUACION[$preguntasAcertadas] ?? 0;
    }

    public function cerrarPartida($partida_id, $gano)
    {
        $estado_final = $gano ? 'finalizada' : 'perdida';

        $sql = "UPDATE partidas_usuario
                SET estado = ?, fecha_fin = NOW()
                WHERE partida_id = ?";

        $this->conexion->preparedQuery($sql, 'si', [$estado_final, $partida_id]);
    }

    public function devolverRangoDeDificultadSegunRanking($rankingUsuario)
    {

        $rangoDeDificultad = [
            "rangoMenor" => 0,
            "rangoMayor" => 0
        ];

        if ($rankingUsuario > 0 && $rankingUsuario <= 100) {
            $rangoDeDificultad['rangoMenor'] = 0;
            $rangoDeDificultad['rangoMayor'] = 0.3;
        } elseif ($rankingUsuario > 100 && $rankingUsuario <= 200) {
            $rangoDeDificultad['rangoMenor'] = 0.31;
            $rangoDeDificultad['rangoMayor'] = 0.5;
        } elseif ($rankingUsuario > 200 && $rankingUsuario <= 300) {
            $rangoDeDificultad['rangoMenor'] = 0.51;
            $rangoDeDificultad['rangoMayor'] = 0.8;
        } else {
            $rangoDeDificultad['rangoMenor'] = 0.81;
            $rangoDeDificultad['rangoMayor'] = 1;
        }

        return $rangoDeDificultad;
    }

    public function verificarYResetearHistorialUsuario($usuario_id, $rankingUsuario)
    {
        // obtengo el rango de dificultad del usuario
        $rango = $this->devolverRangoDeDificultadSegunRanking($rankingUsuario);
        $rangoMenor = $rango['rangoMenor'];
        $rangoMayor = $rango['rangoMayor'];

        // cuento total de preguntas activas EN ESE RANGO
        $sql_total = "SELECT COUNT(*) as total 
                      FROM preguntas 
                      WHERE estado = 'activa' 
                      AND dificultad BETWEEN ? AND ?";

        $res_total = $this->conexion->preparedQuery($sql_total, 'dd', [$rangoMenor, $rangoMayor]);
        $total_activas_en_rango = $res_total[0]['total'] ?? 0;

        // cuanto cuantas preguntas EN ESE RANGO ha respondido el usuario
        $sql_respondidas = "SELECT COUNT(DISTINCT p.pregunta_id) as total 
                            FROM preguntas p
                            JOIN respuestas_usuario ru ON p.pregunta_id = ru.pregunta_id
                            WHERE ru.usuario_id = ? 
                            AND p.dificultad BETWEEN ? AND ?";

        $res_respondidas = $this->conexion->preparedQuery($sql_respondidas, 'idd', [$usuario_id, $rangoMenor, $rangoMayor]);
        $total_respondidas_en_rango = $res_respondidas[0]['total'] ?? 0;

        //calculo las preguntas que le quedan en su rango
        $preguntas_sin_ver = $total_activas_en_rango - $total_respondidas_en_rango;

        // si le quedan 9 o menos, reseteamos su historial completo
        if ($preguntas_sin_ver < 10) {
            $sql_delete = "DELETE FROM respuestas_usuario WHERE usuario_id = ?";
            $this->conexion->preparedQuery($sql_delete, 'i', [$usuario_id]);
            return true; // Se reseteó
        }

        return false; // No se reseteó
    }

    public function getCategorias() {
        $sql = 'SELECT nombre, color_hex FROM categorias';

        $resultado = $this->conexion->query($sql);
        return $resultado;
    }

    public function getIdCorrecta($pregunta_id){
        $sql = "SELECT respuesta_id FROM respuestas WHERE pregunta_id = ? AND es_correcta = 1";
        $resultado = $this->conexion->preparedQuery($sql, 'i', [$pregunta_id]);
        return $resultado[0]['respuesta_id'] ?? null;
    }

    public function getPreguntaPorId($pregunta_id){
        $placeholders = implode(',', array_fill(0, count($pregunta_id), '?'));
        $types = str_repeat('i', count($pregunta_id));

        $sql = "SELECT pregunta_id, texto_pregunta 
                FROM preguntas 
                WHERE pregunta_id IN ($placeholders)";

        return $this->conexion->preparedQuery($sql, $types, $pregunta_id);
    }

    public function reportarPregunta($reportes, $usuario_id) {

        if (empty($reportes) || empty($usuario_id)) {
            return;
        }

        $pregunta_ids = [];
        foreach ($reportes as $reporte) {
            $pregunta_ids[] = $reporte['id'];
        }

        $placeholders = implode(',', array_fill(0, count($pregunta_ids), '?'));
        $types = str_repeat('i', count($pregunta_ids));

        $sql_update = "UPDATE preguntas 
                   SET estado = 'reportada' 
                   WHERE pregunta_id IN ($placeholders)";

        $this->conexion->preparedQuery($sql_update, $types, $pregunta_ids);

        $sql_insert = "INSERT INTO preguntas_reportadas
                   (pregunta_id, reportado_por_usuario_id, motivo, estado)
                   VALUES (?, ?, ?, 'reportado')";

        foreach ($reportes as $reporte) {
            $this->conexion->preparedQuery($sql_insert, 'iis', [
                $reporte['id'],
                $usuario_id,
                $reporte['motivo']
            ]);
        }
    }


}