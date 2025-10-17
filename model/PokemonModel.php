<?php

class PokemonModel
{

    private $conexion;

    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }

    public function delete($id)
    {
        $this->conexion->query("DELETE FROM pokemon WHERE id=$id");
    }

    public function get($id)
    {
        $sql = "SELECT * FROM pokemon WHERE id=$id";
        $resultado = $this->conexion->query($sql);
        return $resultado[0];

    }

    public function buscar($busqueda)
    {
        if ($busqueda == "") {
            $sql = "SELECT * FROM pokemon";
            $resultado = $this->conexion->query($sql);
        } else {
            $sql = "SELECT * FROM pokemon WHERE nombre LIKE '%$busqueda%' OR numero LIKE '%$busqueda%' OR tipo LIKE '%$busqueda%'";
            $resultado = $this->conexion->query($sql);
            if (sizeof($resultado) == 0) {
                $sql = "SELECT * FROM pokemon";
                $resultado = $this->conexion->query($sql);
            }
        }
        return $resultado;
    }

    public function nuevo($nombre, $tipo, $descripcion, $ruta, $numero){
        $sql = "INSERT INTO pokemon (numero, nombre, tipo, descripcion, imagen) VALUES ('$numero', '$nombre', '$tipo', '$descripcion', '$ruta')";
        $this->conexion->query($sql);
    }

    public function editar($id, $numero, $nombre, $tipo, $descripcion ){
        $sql = "UPDATE pokemon SET numero='$numero', nombre='$nombre', tipo='$tipo', descripcion='$descripcion' WHERE id=$id";
        $this->conexion->query($sql);
    }
}