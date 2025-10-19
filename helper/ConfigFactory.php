<?php
include_once("helper/MyConexion.php");
include_once("helper/IncludeFileRenderer.php");
include_once("helper/NewRouter.php");
include_once("controller/LoginController.php");
include_once ("controller/RegistroController.php");
include_once ("controller/PreguntadosController.php");
include_once("model/LoginModel.php");
include_once("model/UsuarioModel.php");
include_once('vendor/autoload.php');
include_once ("helper/MustacheRenderer.php");

class ConfigFactory
{
    private $config;
    private $objetos;

    private $conexion;
    private $renderer;

    public function __construct()
    {
        $this->config = parse_ini_file("config/config.ini");

        $this->conexion= new MyConexion(
            $this->config["server"],
            $this->config["user"],
            $this->config["pass"],
            $this->config["database"]
        );

        $this->renderer = new MustacheRenderer("vista");

        $this->objetos["router"] = new NewRouter($this, "PreguntadosController", "base");

        $this->objetos["LoginController"] = new LoginController(new LoginModel($this->conexion), $this->renderer);

        $this->objetos["RegistroController"] = new RegistroController(new UsuarioModel($this->conexion), $this->renderer);

        $this->objetos["PreguntadosController"] = new PreguntadosController(null, $this->renderer);

       }

    public function get($objectName)
    {
        return $this->objetos[$objectName];
    }
}