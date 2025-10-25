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
            $_SESSION["rol"] = $resultado['usuario']['rol'];
            $this->redirectToIndex();
            return;
        }
        // Caso fallback (no debería ocurrir)
        $this->renderer->render("login", ["error" => "Error desconocido al iniciar sesión"]);
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
        header("Location: /");
        exit;
    }

}