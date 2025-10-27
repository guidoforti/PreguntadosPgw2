<?php

class EditorController
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
        // Redirección por defecto: Si tiene permisos, va al panel de revisión.
        $rol = $_SESSION['rol'] ?? 'usuario';
        if ($rol === 'admin' || $rol === 'editor') {
            $this->revisarPendientes();
        } else {
            $this->sugerirPreguntaForm();
        }
    }



    public function sugerirPreguntaForm($data = [])
    {
        // La seguridad de login la garantiza el index.php
        $data['categorias'] = $this->model->getCategorias() ?? [];
        $this->renderer->render("sugerirPregunta", $data);
    }

    public function procesarSugerencia()
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            header("Location: /preguntados/home");
            exit;
        }

        $usuarioId = $_SESSION['usuario_id'] ?? null;

        // 1. Recibir y validar datos
        $textoPregunta = $_POST['pregunta'] ?? '';
        $categoriaId = $_POST['categoriaId'] ?? 0;
        $opciones = $_POST['respuestas'] ?? [];
        $respuestaCorrectaIndex = $_POST['respuestaCorrecta'] ?? -1;

        // 2. Delegar en el Modelo
        $resultado = $this->model->sugerirPregunta(
            $textoPregunta, $categoriaId, $opciones, $respuestaCorrectaIndex, $usuarioId
        );

        if (isset($resultado['error'])) {
            $this->sugerirPreguntaForm(['error' => $resultado['error']]);
        } else {
            header("Location: /preguntados/home?msg=sugerencia_enviada");
            exit;
        }
    }


    public function revisarPendientes()
    {

        SecurityHelper::checkRole(['admin', 'editor']);

        $pendientes = $this->model->getPreguntasPendientes() ?? [];
        $reportes = $this->model->getReportesPendientes() ?? [];

        $this->renderer->render("revisionPanel", [
            'pendientes' => $pendientes,
            'reportes' => $reportes,
            'rol' => $_SESSION['rol']
        ]);
    }

    public function aprobar()
    {
        SecurityHelper::checkRole(['admin', 'editor']);

        $preguntaId = $_GET['id'] ?? null;
        $editorId = $_SESSION['usuario_id'];

        $this->model->aprobarPregunta($preguntaId, $editorId);

        header("Location: /editor/revisarPendientes?msg=aprobada");
        exit;
    }

    public function denegar()
    {
        SecurityHelper::checkRole(['admin', 'editor']);

        $preguntaId = $_GET['id'] ?? null;

        $this->model->denegarPregunta($preguntaId);

        header("Location: /editor/revisarPendientes?msg=denegada");
        exit;
    }

}