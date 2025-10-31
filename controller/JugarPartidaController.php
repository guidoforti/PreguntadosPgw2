<?php

class JugarPartidaController
{

    private $model;
    private $modelUsuarios;
    private $renderer;

    public function __construct($model, $modelUsuarios , $renderer)
    {
        $this->model = $model;
        $this->modelUsuarios = $modelUsuarios;
        $this->renderer = $renderer;
    }

    public function base(){
        SecurityHelper::checkRole(['usuario', 'editor', 'admin']);
        $this->iniciarPartida();
    }
    public function iniciarPartida(){

        $this->limpiarSesionDePartida();

        $usuario_id = $_SESSION['usuario_id'];

        $partida_id = $this->model->crearPartida($usuario_id);

        $lista_de_ids_preguntas = $this->model->buscarPreguntasParaPartida();

        $_SESSION['partida_id'] = $partida_id;
        $_SESSION['preguntas_partida'] = $lista_de_ids_preguntas;
        $_SESSION['pregunta_actual_index'] = 0;
        $_SESSION['puntaje_actual'] = 0;

        header("Location: /jugarPartida/mostrarPregunta");
        exit;
    }

    public function mostrarPregunta(){

        SecurityHelper::checkRole(['usuario', 'editor', 'admin']);

        if(!isset($_SESSION['partida_id'])) {
            header("Location: /jugarPartida/iniciarPartida");
            exit;
        }

        $index_actual = $_SESSION['pregunta_actual_index'];
        $lista_preguntas = $_SESSION['preguntas_partida'];

        if($index_actual >= count($lista_preguntas)) {
            header("Location: /jugarPartida/finalizar");
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


        $this->renderer->render("jugarPartida", $data_pregunta);

    }

    public function responder(){
        SecurityHelper::checkRole(['usuario', 'editor', 'admin']);
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

        if ($_SESSION['pregunta_actual_index'] >= count($lista_preguntas)) {
            header("Location: /jugarPartida/finalizar");
        } else {
            header("Location: /jugarPartida/mostrarPregunta");
        }
        unset($_SESSION['pregunta_start_time']);
        exit;
    }

    public function finalizar(){
        SecurityHelper::checkRole(['usuario', 'editor', 'admin']);
        if(!isset($_SESSION['partida_id'])) {
            header("Location: /");
            exit;
        }

        $partida_id = $_SESSION['partida_id'];
        $puntaje_final = $_SESSION['puntaje_actual'];
        $usuario_id = $_SESSION['usuario_id'];
        $gano_la_partida = $puntaje_final > 5;
        $puntosDeRanking = $this->model->calcularPuntosPorPartida($puntaje_final);
        $resultadoRanking = $this->modelUsuarios->modificarRanking($usuario_id , $puntosDeRanking);


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

}