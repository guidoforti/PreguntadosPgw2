<?php

class PreguntadosController
{

    private $preguntasModel;
    private $usuarioModel;
    private $renderer;

    public function __construct($model, $usuarioModel, $renderer)
    {
        $this->preguntasModel = $model;
        $this->usuarioModel = $usuarioModel;
        $this->renderer = $renderer;
    }

    public function base()

    {
        $this->home();
    }

    public function home()
    {
        $rol = $_SESSION["rol"] ?? 'usuario';
        $usuario_id = $_SESSION["usuario_id"] ?? null;

        $data = [
            "usuario" => $_SESSION["usuario"] ?? 'Invitado',
            "rol" => $rol,
            "usuario_id" => $usuario_id ?? '??',
            "esAdmin" => ($rol === 'admin'),
            "esEditorOAdmin" => ($rol === 'editor' || $rol === 'admin')
        ];

        if ($usuario_id) {

            $usuario = $this->usuarioModel->getUsuarioById($usuario_id);

            if ($usuario) {
                $rango = $this->usuarioModel->obtenerRango($usuario['ranking']);

                $data['rango'] = $rango;
                $data['ranking_puntos'] = $usuario['ranking'];
            }
        }

        $this->renderer->render("home", $data);
    }

}