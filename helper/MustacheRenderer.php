<?php
require_once __DIR__ . '/../vendor/autoload.php';

use Mustache\Engine;
use Mustache\Loader\FilesystemLoader;

class MustacheRenderer {
    private $mustache;
    private $viewsFolder;

    public function __construct($partialsPathLoader) {
        $this->mustache = new Engine([
            'partials_loader' => new FilesystemLoader($partialsPathLoader)
        ]);
        $this->viewsFolder = $partialsPathLoader;
    }

    /*
    public function render($contentFile, $data = []) {
        echo $this->generateHtml(
            $this->viewsFolder . '/' . $contentFile . 'Vista.mustache',
            $data
        );
    }

    */

    public function render($contentFile, $data = []) {
        $is_ajax = isset($_GET['ajax']) && $_GET['ajax'] === 'true';
        $contentPath = $this->viewsFolder . '/' . $contentFile . 'Vista.mustache';

        if ($is_ajax) {
            echo $this->renderPartial($contentPath, $data);
        } else {
            echo $this->renderLayout($contentPath, $data);
        }
    }

    private function renderLayout($contentPath, $data = []) {
        // Renderizamos la vista
        $contenidoRenderizado = file_exists($contentPath)
            ? $this->mustache->render(file_get_contents($contentPath), $data)
            : 'Template not found: ' . basename($contentPath);

        // Cargamos layout completo
        $layoutPath = $this->viewsFolder . '/layout.mustache';
        if (!file_exists($layoutPath)) return 'Layout not found';

        $layout = file_get_contents($layoutPath);

        // Inyectamos la vista renderizada en {{{contenido}}}
        return $this->mustache->render($layout, ['contenido' => $contenidoRenderizado] + $data);
    }


    private function renderPartial($contentPath, $data = []) {
        $body = file_exists($contentPath)
            ? file_get_contents($contentPath)
            : '<p>Template not found: ' . basename($contentPath) . '</p>';

        return $this->mustache->render($body, $data);
    }

    private function renderFullPage($contentPath, $data = []) {
        error_log("[Renderer] renderFullPage: " . $contentPath);

        $header = file_exists($this->viewsFolder . '/header.mustache')
            ? file_get_contents($this->viewsFolder . '/header.mustache')
            : '';
        $body = file_exists($contentPath)
            ? file_get_contents($contentPath)
            : '<p>Template not found: ' . basename($contentPath) . '</p>';
        $footer = file_exists($this->viewsFolder . '/footer.mustache')
            ? file_get_contents($this->viewsFolder . '/footer.mustache')
            : '';

        $contentAsString = $header . $body . $footer;

        return $this->mustache->render($contentAsString, $data);
    }

    public function generateHtml($contentFile, $data = []) {
        $header = file_exists($this->viewsFolder . '/header.mustache')
            ? file_get_contents($this->viewsFolder . '/header.mustache')
            : '';
        $body = file_exists($contentFile)
            ? file_get_contents($contentFile)
            : '<p>Template not found: ' . basename($contentFile) . '</p>';
        $footer = file_exists($this->viewsFolder . '/footer.mustache')
            ? file_get_contents($this->viewsFolder . '/footer.mustache')
            : '';

        $contentAsString = $header . $body . $footer;

        return $this->mustache->render($contentAsString, $data);
    }
}