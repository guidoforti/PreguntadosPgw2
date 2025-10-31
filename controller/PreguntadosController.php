<?php

class PreguntadosController
{

    private $model; // PreguntasModel
    private $renderer;

    public function __construct($model, $renderer)
    {
        $this->model = $model;
        $this->renderer = $renderer;
    }

    public function base()
    {
        $this->home();
    }

    public function home()
    {
        // LOGICA DEL CRON SIMULADO
        if ($this->model->debeEjecutarseElCronManual()) {

            session_write_close();
            //con esto nos aseguramos de que toda la tarea se corra por mas que el usuario cierre sesion o la pagina
            ignore_user_abort(true);
            // EJECUTAR LA TAREA PESADA
            $this->model->recalcularDificultadDePreguntasGlobal();
        }

        $rol = $_SESSION["rol"] ?? 'usuario';

        $this->renderer->render("home", [
            // Datos del usuario (defensivos)
            "usuario" => $_SESSION["usuario"] ?? 'Invitado',
            "rol" => $rol,
            "usuario_id" => $_SESSION["usuario_id"] ?? '??',

            // Flags calculadas para la vista (Visibilidad de botones)
            "esAdmin" => ($rol === 'admin'),
            "esEditorOAdmin" => ($rol === 'editor' || $rol === 'admin')

            // Aquí se agregará el ranking, partidas, etc., en pasos futuros.
        ]);
    }
}