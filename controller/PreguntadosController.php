<?php

class PreguntadosController
{

    private $preguntasModel;// PreguntasModel
    private $usuarioModel;
    private $renderer;

    public function __construct($model, $usuarioModel, $renderer)
    {
        $this->preguntasModel = $model;
        $this->usuarioModel = $usuarioModel;
        $this->renderer = $renderer;
    }

    public function base()

    {
        $this->home();
    }

    public function home()
    {
        //logica del cron manual
        if ($this->preguntasModel->debeEjecutarseElCronManual()) {
            session_write_close();
            //con esto nos aseguramos de que toda la tarea se corra por mas que el usuario cierre sesion o la pagina
            ignore_user_abort(true);
            // EJECUTAR LA TAREA PESADA
            $this->preguntasModel->recalcularDificultadDePreguntasGlobal();
        }


        $rol = $_SESSION["rol"] ?? 'usuario';
        $usuario_id = $_SESSION["usuario_id"] ?? null;

        // Preparamos un array $data para enviar a la vista
        $data = [
            "usuario" => $_SESSION["usuario"] ?? 'Invitado',
            "rol" => $rol,
            "usuario_id" => $usuario_id ?? '??',
            "esAdmin" => ($rol === 'admin'),
            "esEditorOAdmin" => ($rol === 'editor' || $rol === 'admin')
        ];

        // Si el usuario está logueado, buscamos sus datos de rango
        if ($usuario_id) {

            //Buscamos los datos del usuario (que incluyen el ranking)
            $usuario = $this->usuarioModel->getUsuarioById($usuario_id);

            if ($usuario) {
                $rango = $this->usuarioModel->obtenerRango($usuario['ranking']);

                $data['rango'] = $rango;
                $data['ranking_puntos'] = $usuario['ranking'];
            }
        }

        $this->renderer->render("home", $data);
    }

}