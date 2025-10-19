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
        $this->render->render("registrar");
    }

    public function registrar()
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->render->render("registrar", ["error" => "Método no permitido."]);
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
                $this->render->render("registrar", ["error" => "El campo '$clave' es obligatorio."]);
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

        // Mostrar el resultado en la vista correspondiente
        if (isset($resultado['error'])) {
            $this->render->render("registrar", ["error" => $resultado['error']]);
        } elseif (isset($resultado['success'])) {
            $this->render->render("login", ["exito" => $resultado['success']]);
        } else {
            $this->render->render("registrar", ["error" => "Error desconocido al registrar el usuario."]);
        }
    }


}