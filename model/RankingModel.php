<?php

class RankingModel
{
    private $conexion;

    public function __construct($conexion)
    {
        $this->conexion = $conexion;
    }

    public function getRankingGlobal($limite = 50)
    {
        $sql = "SELECT usuario_id, nombre_usuario, ranking, url_foto_perfil
                FROM usuarios
                WHERE esta_verificado = TRUE
                ORDER BY ranking DESC
                LIMIT ?";

        return $this->conexion->preparedQuery($sql, 'i', [$limite]);
    }
}