<?php

class JugarPartidaController
{

    private $model;
    private $modelUsuarios;

    private $modelPreguntas;
    private $renderer;

    public function __construct($model, $modelUsuarios, $modelPreguntas , $renderer)
    {
        $this->model = $model;
        $this->modelUsuarios = $modelUsuarios;
        $this->modelPreguntas = $modelPreguntas;
        $this->renderer = $renderer;
    }

    public function base(){
        SecurityHelper::checkRole(['usuario']);
        $this->iniciarPartida();
    }
    public function iniciarPartida(){
        $this->verificarYFinalizarPartidaActiva();
        $this->limpiarSesionDePartida();

        $usuario_id = $_SESSION['usuario_id'];

        $partida_id = $this->model->crearPartida($usuario_id);

        $usuario = $this->modelUsuarios->getUsuarioById($usuario_id);
        $this->model->verificarYResetearHistorialUsuario($usuario_id, $usuario['ranking']);

        $_SESSION['partida_id'] = $partida_id;
        $_SESSION['preguntas_partida'] = [];
        $_SESSION['pregunta_actual_index'] = 0;
        $_SESSION['puntaje_actual'] = 0;

        $_SESSION['ranking_inicio'] = $usuario['ranking'];

        header("Location: /jugarPartida/mostrarRuleta");
        exit;
    }

    public function mostrarPregunta(){

        SecurityHelper::checkRole(['usuario']);

        if(!isset($_SESSION['partida_id'])) {
            header("Location: /jugarPartida/iniciarPartida");
            exit;
        }



        $index_actual = $_SESSION['pregunta_actual_index'];
        $lista_preguntas = $_SESSION['preguntas_partida'];

        if($index_actual >= 10) {
            header("Location: /jugarPartida/finalizar");
            exit;
        }

        if(!isset($lista_preguntas[$index_actual])) {
            header("Location: /jugarPartida/mostrarRuleta");
            exit;
        }

        $id_pregunta_actual = $lista_preguntas[$index_actual];
        $data_pregunta = $this->model->getPreguntaCompleta($id_pregunta_actual);

        $tiempo_restante = 20;

        if( isset($_SESSION['pregunta_start_time']) ) {
            $start_time = $_SESSION['pregunta_start_time'];
            $tiempo_limite = 20;
            $tiempo_usado = time() - $start_time;
            $tiempo_restante = $tiempo_limite - $tiempo_usado;

            $es_timeout = ($tiempo_restante <= 0);

            if( $es_timeout ) {
                $this->renderer->render("trampaTimerPartida", $data_pregunta);
                exit;
            }

        } else {
            $_SESSION['pregunta_start_time'] = time();
        }

        $data_pregunta['timer'] = $tiempo_restante;

        $total_preguntas = 10;
        $data_pregunta['preguntas_respondidas'] = $index_actual;
        $data_pregunta['preguntas_mostradas']  = $index_actual + 1;
        $data_pregunta['total_preguntas']      = $total_preguntas;

        $progreso_fraction = ($index_actual + 1) / $total_preguntas;
        $data_pregunta['porcentaje_progreso'] = (int) round($progreso_fraction * 100, 0);

        $this->renderer->render("jugarPartida", $data_pregunta);

    }

    public function responder(){

        SecurityHelper::checkRole(['usuario']);
        if(!isset($_SESSION['partida_id'])) {
            header("Location: /jugarPartida/iniciarPartida");
            exit;
        }

        $partida_id = $_SESSION['partida_id'];
        $usuario_id = $_SESSION['usuario_id'];
        $start_time = $_SESSION['pregunta_start_time'];
        $lista_preguntas = $_SESSION['preguntas_partida'];
        $index_actual = $_SESSION['pregunta_actual_index'];

        $respuesta_id_seleccionada = $_POST['respuesta_id'] ?? null;
        $pregunta_id_respondida = $_POST['pregunta_id'] ?? null;

        $pregunta_id_esperada = $lista_preguntas[$index_actual];
        if($pregunta_id_respondida != $pregunta_id_esperada) {
            header("Location: /jugarPartida/mostrarPregunta");
            exit;
        }

        $fue_correcta = $this->model->procesarRespuesta(
            $partida_id,
            $usuario_id,
            $pregunta_id_respondida,
            $respuesta_id_seleccionada,
            $start_time
        );

        if($fue_correcta) {
            $_SESSION['puntaje_actual']++;
        }

        $_SESSION['pregunta_actual_index']++;
        unset($_SESSION['pregunta_start_time']);

        $index_nuevo = $_SESSION['pregunta_actual_index'];

        if($index_nuevo >= 10) {
            header("Location: /jugarPartida/finalizar");
        } else if ($index_nuevo % 2 == 0) {
            header("Location: /jugarPartida/mostrarRuleta");
        } else {
            header("Location: /jugarPartida/mostrarPregunta");
        }

        exit;
    }

    public function finalizar(){
        SecurityHelper::checkRole(['usuario']);
        if(!isset($_SESSION['partida_id'])) {
            header("Location: /");
            exit;
        }

        $listaIdPreguntas = $_SESSION['preguntas_partida'];
        $partida_id = $_SESSION['partida_id'];
        $puntaje_final = $_SESSION['puntaje_actual'];
        $usuario_id = $_SESSION['usuario_id'];
        $gano_la_partida = $puntaje_final > 5;
        $puntosDeRanking = $this->model->calcularPuntosPorPartida($puntaje_final);
        $resultadoRanking = $this->modelUsuarios->modificarRanking($usuario_id , $puntosDeRanking);

        $this->modelPreguntas->recalcularDificultadDePreguntasDePartida($listaIdPreguntas);

        $nuevoRanking = $resultadoRanking['rankingActualizado'];
        $rango = $this->modelUsuarios->obtenerRango($nuevoRanking);
        $this->model->cerrarPartida($partida_id, $gano_la_partida);

        $data_resultado = [
            'puntaje' => $puntaje_final,
            'gano' => $gano_la_partida,
            'puntosDeRanking' => $puntosDeRanking,
            'nuevoRanking' => $nuevoRanking,
            'rango' => $rango
        ];

        $_SESSION['preguntas_para_reportar'] = $listaIdPreguntas;

        $this->limpiarSesionDePartida();

        $this->renderer->render("resultadoPartida", $data_resultado);
    }

    private function limpiarSesionDePartida() {
        unset($_SESSION['partida_id']);
        unset($_SESSION['preguntas_partida']);
        unset($_SESSION['pregunta_actual_index']);
        unset($_SESSION['puntaje_actual']);
        unset($_SESSION['pregunta_start_time']);
    }

    public function mostrarRuleta() {
        SecurityHelper::checkRole(['usuario']);

        if(!isset($_SESSION['partida_id'])) {
            header("Location: /jugarPartida/iniciarPartida");
            exit;
        }

        $index_actual = $_SESSION['pregunta_actual_index'] ?? 0;
        $preguntas_en_lista = count($_SESSION['preguntas_partida'] ?? []);

        if ($preguntas_en_lista != $index_actual) {
            header("Location: /jugarPartida/mostrarPregunta");
        }

        $data = [];
        $data['categorias'] = $this->model->getCategorias();

        $data['categorias_json'] = json_encode($data['categorias']);

        $mensaje_penalizacion = $_SESSION['mensaje_penalizacion'] ?? null;
        if ($mensaje_penalizacion) {
            $data['mensaje_penalizacion'] = $mensaje_penalizacion;
            unset($_SESSION['mensaje_penalizacion']);
        }

        $this->renderer->render("ruleta", $data);
    }

    public function guardarCategoria(){
        SecurityHelper::checkRole(['usuario']);
        if(!isset($_SESSION['partida_id']) || !isset($_POST['categoria_elegida'])) {
            header("Location: /");
            exit;
        }

        $categoria_elegida = $_POST['categoria_elegida'];
        $usuario_id = $_SESSION['usuario_id'];
        $rankingUsuario = $_SESSION['ranking_usuario'];

        $ids_nuevas_preguntas = $this->model->buscarPreguntasParaPartida(
            $rankingUsuario,
            $usuario_id,
            $categoria_elegida,
            2
        );

        $_SESSION['preguntas_partida'] = array_merge($_SESSION['preguntas_partida'], $ids_nuevas_preguntas);

        header("Location: /jugarPartida/mostrarPregunta");
        exit;
    }

    public function verificarYFinalizarPartidaActiva()
    {
        $usuario_id = $_SESSION['usuario_id'] ?? null;
        $penalizacion = $this->model->finalizarPartidaAbandonada($usuario_id);

        if($penalizacion !== 0){
            $this->modelUsuarios->modificarRanking($usuario_id, $penalizacion);
            $_SESSION['mensaje_penalizacion'] = "¡Abandonaste la anterior partida! Se descontaran {$penalizacion} puntos de tu ranking";
        }
    }

    public function verificarRespuestaAjax() {

        SecurityHelper::checkRole(['usuario']);

        if (!isset($_POST['pregunta_id']) || !isset($_SESSION['partida_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Petición inválida']);
            exit;
        }

        $pregunta_id = $_POST['pregunta_id'];
        $id_correcta = $this->model->getIdCorrecta($pregunta_id);

        header('Content-type: application/json');
        echo json_encode(['id_correcta' => $id_correcta]);
        exit;
    }

    public function reportarPreguntaForm(){
        SecurityHelper::checkRole(['usuario']);

        if (!isset($_SESSION['preguntas_para_reportar']) || empty($_SESSION['preguntas_para_reportar'])) {
            header("Location: /");
            exit;
        }

        $ids_preguntas = $_SESSION['preguntas_para_reportar'];
        $preguntas = $this->model->getPreguntaPorId($ids_preguntas);
        $data['preguntas'] = $preguntas;
        $this->renderer->render("reportarPregunta", $data);

    }

    public function procesarReporte(){
        SecurityHelper::checkRole(['usuario']);

        $ids_a_reportar = $_POST['preguntas_reportadas'] ?? [];
        $motivos_enviados = $_POST['motivos'] ?? [];
        $usuario_id = $_SESSION['usuario_id'] ?? null;

        if(empty($ids_a_reportar) || empty($usuario_id)) {
            header("Location: /");
            exit;
        }

        if (count($ids_a_reportar) > 3) {
            header("Location: /");
        }

        $reportes = [];
        foreach ($ids_a_reportar as $id_reportado) {
            if (isset($motivos_enviados[$id_reportado]) && trim($motivos_enviados[$id_reportado]) !== '') {
                $reportes[] = [
                    'id' => $id_reportado,
                    'motivo' => trim($motivos_enviados[$id_reportado])
                ];
            }
        }

        if (empty($reportes)) {
            header("Location: /");
            exit;
        }

        $this->model->reportarPregunta($reportes, $usuario_id);

        unset($_SESSION['preguntas_para_reportar']);
        header("Location: /");
        exit;
    }

}