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
        $rol = $_SESSION["rol"] ?? 'usuario';

        $this->renderer->render("home", [
            // Datos del usuario (defensivos)
            "usuario" => $_SESSION["usuario"] ?? 'Invitado',
            "rol" => $rol,

            // Flags calculadas para la vista (Visibilidad de botones)
            "esAdmin" => ($rol === 'admin'),
            "esEditorOAdmin" => ($rol === 'editor' || $rol === 'admin')

            // Aquí se agregará el ranking, partidas, etc., en pasos futuros.
        ]);
    }
}