<?php

class PreguntadosController
{

    private $model;
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
            "usuario" => $_SESSION["usuario"] ?? 'Invitado',
            "rol" => $rol,
            "esEditorOAdmin" => ($rol === 'editor' || $rol === 'admin'),
            "esAdmin" => ($rol === 'admin')
        ]);
    }


}