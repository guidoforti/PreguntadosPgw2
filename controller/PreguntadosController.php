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
        $this->renderer->render("home", [
            "usuario" => $_SESSION["usuario"] ?? 'invitado',
            "rol" => $_SESSION["rol"] ?? 'usuario'//Esto en el futuro hay que eliminarlo, ahora nos sirve de guia
        ]);
    }


}