<?php

class MyConexion
{

    private $conexion;

    public function __construct($server, $user, $pass, $database)
    {
        $this->conexion = new mysqli($server, $user, $pass, $database);
        mysqli_set_charset($this->conexion, 'utf8mb4');
        $this->conexion->query("SET time_zone = '-03:00'");
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

    public function preparedQuery(string $sql, string $tipos = '', array $parametros = [])
    {
        $stmt = $this->conexion->prepare($sql);
        if ($stmt === false) {
            error_log("Error al preparar la consulta: " . $this->conexion->error . " | SQL: " . $sql);
            return false;
        }
        if (!empty($parametros)) {
            $stmt->bind_param($tipos, ...$parametros);
        }
        $success = $stmt->execute();
        if ($success === false) {
            error_log("Error al ejecutar la consulta: " . $stmt->error);
            $stmt->close();
            return false;
        }
        $resultado = $stmt->get_result();
        if ($resultado) {
            $data = $resultado->fetch_all(MYSQLI_ASSOC);
        } else {
            $data = $success; // Devuelve true/false para INSERT/UPDATE/DELETE
        }
        $stmt->close();
        return $data;
    }


    public function getMysqli(): \mysqli
    {
        return $this->conexion;
    }


    public function getInsertId(): int
    {
        return $this->conexion->insert_id;
    }
}