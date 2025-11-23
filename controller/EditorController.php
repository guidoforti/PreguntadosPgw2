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
            'rol' => $_SESSION['rol'],
            'count_pendientes' => count($pendientes),
            'count_reportes' => count($reportes)
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

    public function aprobarReporte()
    {
        SecurityHelper::checkRole(['admin', 'editor']);
        $reporteId = $_GET['reporte_id'] ?? null;
        $editorId = $_SESSION['usuario_id'] ?? null;

        if ($reporteId && $editorId) {
            $this->model->aprobarReporte($reporteId, $editorId);
        }
        header("Location: /editor/revisarPendientes?msg=aprobada");
        exit;
    }

    public function rechazarReporte()
    {
        SecurityHelper::checkRole(['admin', 'editor']);
        $reporteId = $_GET['reporte_id'] ?? null;
        $editorId = $_SESSION['usuario_id'] ?? null;
        if ($reporteId && $editorId) {
            $this->model->rechazarReporte($reporteId, $editorId);
        }
        header("Location: /editor/revisarPendientes?msg=rechazada");
        exit;
    }

    public function categoriasForm()
    {
        SecurityHelper::checkRole(['admin', 'editor']);
        $data = [];
        $data['categorias'] = $this->model->getCategoriasOrderById() ?? [];

        $data['flash_success'] = $_SESSION['flash_success'] ?? null;
        $data['flash_error'] = $_SESSION['flash_error'] ?? null;

        unset($_SESSION['flash_success']);
        unset($_SESSION['flash_error']);
        $this->renderer->render("categoriasForm", $data);
    }

    public function guardarCategoria()
    {
        SecurityHelper::checkRole(['admin', 'editor']);
        $id = $_POST['categoria_id'] ?? null;
        $nombre = trim($_POST['nombre'] ?? '');
        $color_hex = $_POST['color_hex'] ?? '';

        if (empty($nombre) || empty($color_hex)) {
            $_SESSION['flash_error'] = "El nombre y el color son obligatorios.";
            header("Location: /editor/categoriasForm");
            exit;
        }

        if ($id) {
            $resultado = $this->model->actualizarCategoria($id, $nombre, $color_hex);
            $msg_ok = "Categoría actualizada con éxito.";
        } else {
            $resultado = $this->model->crearCategoria($nombre, $color_hex);
            $msg_ok = "Categoría creada con éxito.";
        }
        if (isset($resultado['error'])) {
            $_SESSION['flash_error'] = $resultado['error'];
        } else {
            $_SESSION['flash_success'] = $msg_ok;
        }
        header("Location: /editor/categoriasForm");
        exit;
    }
    public function eliminarCategoria()
    {
        SecurityHelper::checkRole(['admin', 'editor']);
        $id = $_GET['id'] ?? null;

        if (!$id) {
            $_SESSION['flash_error'] = "ID de categoría no especificado.";
            header("Location: /editor/categoriasForm");
            exit;
        }
        $resultado = $this->model->eliminarCategoria($id);

        if (isset($resultado['error'])) {
            $_SESSION['flash_error'] = $resultado['error'];
        } else {
            $_SESSION['flash_success'] = "Categoría eliminada con éxito.";
        }
        header("Location: /editor/categoriasForm");
        exit;
    }


}