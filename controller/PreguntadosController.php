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
        if (!isset($_SESSION["usuario"])) {
            $this->redirectToLogin();
            return;
        }

        $this->renderer->render("home", [
            "usuario" => $_SESSION["usuario"]
        ]);
    }

    public function redirectToLogin() {
        header("Location: /ProyectoGrupo2/login/loginForm");
        exit;
    }

}