<?php

class MyConexion
{

    private $conexion;

    public function __construct($server, $user, $pass, $database)
    {
        $this->conexion = new mysqli($server, $user, $pass, $database);
        if ($this->conexion->error) { die("Error en la conexión: " . $this->conexion->error); }
    }
    public function query($sql)
    {
        $result = $this->conexion->query($sql);

        if ($result === false) {
            // Error en la consulta
            return ['error' => $this->conexion->error];
        }

        // Si es un SELECT
        if ($result instanceof mysqli_result) {
            if ($result->num_rows > 0) {
                return $result->fetch_all(MYSQLI_ASSOC);
            }
            return null;
        }

        // Para INSERT, UPDATE, DELETE devuelve true si funcionó
        return ['success' => true, 'affected_rows' => $this->conexion->affected_rows, 'insert_id' => $this->conexion->insert_id];
    }
}