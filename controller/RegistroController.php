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

    }

}