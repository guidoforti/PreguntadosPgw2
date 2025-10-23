<?php

class LoginController
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
        $this->loginForm();
    }

    public function loginForm()
    {
        if (isset($_SESSION["usuario"])) {
            $this->redirectToIndex();
            return;
        }
        $this->renderer->render("login");
    }

    public function login()
    {
        // Tomar los datos del POST
        $usuario = $_POST["usuario"] ?? '';
        $password = $_POST["password"] ?? '';

        // Validar campos vacíos
        if (empty($usuario) || empty($password)) {
            $this->renderer->render("login", ["error" => "Debe completar todos los campos"]);
            return;
        }

        // Llamar al modelo
        $resultado = $this->model->getUserWith($usuario, $password);

        // Manejar errores del modelo
        if (isset($resultado['error'])) {
            $this->renderer->render("login", ["error" => $resultado['error']]);
            return;
        }

        // Login exitoso
        if (isset($resultado['success'])) {
            $_SESSION["usuario"] = $resultado['usuario']['nombre_usuario'];
            $this->redirectToIndex();
            return;
        }

        // Caso fallback (no debería ocurrir)
        $this->renderer->render("login", ["error" => "Error desconocido al iniciar sesión"]);
    }


    public function logout()
    {
        session_destroy();
        $this->redirectToIndex();
    }

    public function redirectToIndex()
    {
        header("Location: /");
        exit;
    }

}