<?php
require 'vendor/autoload.php';
// Carga de Clases Propias
// Modelos
include_once("model/LoginModel.php");
include_once("model/UsuarioModel.php");
include_once("model/PreguntasModel.php");
include_once("model/JugarPartidaModel.php");
include_once("model/RankingModel.php");
include_once("model/AdminModel.php");
// Helpers y Renderizadores
include_once("helper/MyConexion.php");
include_once("helper/NewRouter.php");
include_once("helper/MustacheRenderer.php");
include_once("helper/Mailer.php");
include_once("helper/SecurityHelper.php");
// Controladores
include_once("controller/LoginController.php");
include_once ("controller/RegistroController.php");
include_once ("controller/PreguntadosController.php");
include_once ("controller/EditorController.php");
include_once ("controller/JugarPartidaController.php");
include_once ("controller/RankingController.php");
include_once ("controller/PerfilController.php");
include_once ("controller/AdminController.php");

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

        $this->objetos["PreguntadosController"] = new PreguntadosController(new PreguntasModel($this->conexion), new UsuarioModel($this->conexion), $this->renderer);

        $this->objetos["EditorController"] = new  EditorController(new PreguntasModel($this->conexion), $this->renderer);

        $this->objetos["JugarPartidaController"] = new JugarPartidaController(new JugarPartidaModel($this->conexion), new UsuarioModel($this->conexion), new PreguntasModel($this->conexion), $this->renderer);

        $this->objetos["RankingController"] = new RankingController(new RankingModel($this->conexion), new UsuarioModel($this->conexion), $this->renderer);

        $this->objetos["PerfilController"] = new PerfilController(new UsuarioModel($this->conexion), new RankingModel($this->conexion), $this->renderer);

        $this->objetos["AdminController"] = new AdminController(new AdminModel($this->conexion), $this->renderer);
       }

    public function get($objectName)
    {
        return $this->objetos[$objectName];
    }
}

