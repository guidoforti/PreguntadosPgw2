<?php

class RegistroController
{
    private $model;
    private $render;


    public function __construct($model, $render)
    {
        $this->model = $model;
        $this->render = $render;
    }


    public function base()
    {
      $this->registrarForm();
    }


    public function registrarForm()
    {
        if (isset($_SESSION["usuario"])) {
            $this->redirectToIndex();
            return;
        }

        $data = [
            'exito' => null,
            'error' => null,
            'anioActual' => date('Y')
        ];

        $this->render->render("registrar", $data);
    }

    public function registrar()
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $data = [
                "error" => "Método no permitido.",
                "exito" => null,
                "anioActual" => date('Y')
            ];
            $this->render->render("registrar", $data);
            return;
        }

        // Capturar todos los datos del formulario
        $nombreCompleto   = $_POST['nombreCompleto'] ?? null;
        $anioNacimiento   = $_POST['anioNacimiento'] ?? null;
        $sexo             = $_POST['sexo'] ?? null;
        $email            = $_POST['email'] ?? null;
        $nombreUsuario    = $_POST['nombreUsuario'] ?? null;
        $contraseniaUno   = $_POST['password'] ?? null;
        $contraseniaDos   = $_POST['confirmPassword'] ?? null;
        $imagen           = $_FILES['fotoPerfil'] ?? null;

        // Validar campos vacíos antes de pasar al modelo
        $campos = compact('nombreCompleto', 'anioNacimiento', 'sexo', 'email', 'nombreUsuario', 'contraseniaUno', 'contraseniaDos');
        foreach ($campos as $clave => $valor) {
            if (empty($valor)) {
                $data = [
                    "error" => "El campo '$clave' es obligatorio.",
                    "exito" => null,
                    "anioActual" => date('Y')
                ];
                $this->render->render("registrar", $data);
                return;
            }
        }

        // Llamar al modelo para registrar
        $resultado = $this->model->registrar(
            $nombreCompleto,
            $anioNacimiento,
            $sexo,
            $email,
            $nombreUsuario,
            $contraseniaUno,
            $contraseniaDos,
            $imagen
        );


        if (isset($resultado['error'])) {

            $data = [
                "error" => $resultado['error'],
                "exito" => null,
                "anioActual" => date('Y')
            ];
            $this->render->render("registrar", $data);

        } elseif (isset($resultado['success'])) {

            $this->render->render("login", ["exito" => $resultado['success']]);
        } else {

            $data = [
                "error" => "Error desconocido al registrar el usuario.",
                "exito" => null,
                "anioActual" => date('Y')
            ];
            $this->render->render("registrar", $data);
        }
    }

    public function redirectToIndex()
    {
        header("Location: /ProyectoGrupo2/");
        exit;
    }

}