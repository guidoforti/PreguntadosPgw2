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

    public function render($contentFile, $data = []) {
        echo $this->generateHtml(
            $this->viewsFolder . '/' . $contentFile . 'Vista.mustache',
            $data
        );
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