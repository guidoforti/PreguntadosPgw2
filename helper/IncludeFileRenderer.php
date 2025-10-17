<?php

class IncludeFileRenderer
{
    public function __construct()
    {
    }

    public function render($template, $data = null)
    {
        include_once("vista/partial/header.mustache");
        include_once("vista/" . $template . "Vista.php");
        include_once("vista/partial/footer.mustache");
    }
}