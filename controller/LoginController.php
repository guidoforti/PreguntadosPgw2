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
        $this->renderer->render("login", ["notLoggedIn" => true]);
    }

    public function login()
    {
        $usuario = $_POST["usuario"] ?? '';
        $password = $_POST["password"] ?? '';

        if (empty($usuario) || empty($password)) {
            $this->renderer->render("login", ["error" => "Debe completar todos los campos", "notLoggedIn" => true]);
            return;
        }

        $resultado = $this->model->getUserWith($usuario, $password);

        if (isset($resultado['error'])) {
            $this->renderer->render("login", ["error" => $resultado['error'], "notLoggedIn" => true]);
            return;
        }

        if (isset($resultado['success'])) {
            $_SESSION["usuario"] = $resultado['usuario']['nombre_usuario'];
            $_SESSION["rol"] = $resultado['usuario']['rol'];
            $_SESSION["usuario_id"] = $resultado['usuario']['usuario_id'];
            $this->redirectToIndex();
            return;
        }
        $this->renderer->render("login", ["error" => "Error desconocido al iniciar sesión", "notLoggedIn" => true]);
    }


    public function logout()
    {
        session_destroy();
        if (ini_get("session.use_cookies")) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000,
                $params["path"], $params["domain"],
                $params["secure"], $params["httponly"]
            );
        }
        header("Location: /login/loginForm");
    }

    public function redirectToIndex()
    {
        $paramAjax = isset($_GET['ajax']) ? '?ajax=true' : '';
        header("Location: /" . $paramAjax);
        exit;
    }

}