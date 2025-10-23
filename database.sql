-- Base de datos
DROP DATABASE IF EXISTS preguntados;
CREATE DATABASE IF NOT EXISTS preguntados;
USE preguntados;

-- Limpiar tablas
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS ciudades;
DROP TABLE IF EXISTS provincias;
DROP TABLE IF EXISTS paises;

-- Tabla de países
CREATE TABLE paises (
                        pais_id INT NOT NULL AUTO_INCREMENT,
                        nombre VARCHAR(255) NOT NULL,
                        PRIMARY KEY (pais_id),
                        UNIQUE KEY uk_nombre_pais (nombre)
);

-- Tabla de provincias
CREATE TABLE provincias (
                            provincia_id INT NOT NULL AUTO_INCREMENT,
                            pais_id INT NOT NULL,
                            nombre VARCHAR(255) NOT NULL,
                            PRIMARY KEY (provincia_id),
                            UNIQUE KEY uk_nombre_provincia (nombre, pais_id),
                            FOREIGN KEY (pais_id)
                                REFERENCES paises(pais_id)
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE
);

-- Tabla de ciudades
CREATE TABLE ciudades (
                          ciudad_id INT NOT NULL AUTO_INCREMENT,
                          provincia_id INT NOT NULL,
                          nombre VARCHAR(255) NOT NULL,
                          PRIMARY KEY (ciudad_id),
                          UNIQUE KEY uk_nombre_ciudad (nombre, provincia_id),
                          FOREIGN KEY (provincia_id)
                              REFERENCES provincias(provincia_id)
                              ON DELETE RESTRICT
                              ON UPDATE CASCADE
);

-- Tabla de usuarios
CREATE TABLE usuarios (
                          usuario_id INT NOT NULL AUTO_INCREMENT,
                          nombre_completo VARCHAR(255) NOT NULL,
                          nombre_usuario VARCHAR(100) NOT NULL,
                          email VARCHAR(255) NOT NULL,
                          contrasena_hash VARCHAR(255) NOT NULL,
                          ano_nacimiento INT NOT NULL,
                          sexo VARCHAR(20),
                          ciudad_id INT NOT NULL,
                          url_foto_perfil VARCHAR(500) NULL,
                          rol VARCHAR(20) NOT NULL,
                          esta_verificado BOOLEAN NOT NULL DEFAULT FALSE,
                          fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                          token_verificacion VARCHAR(32) NULL,
                          PRIMARY KEY (usuario_id),
                          FOREIGN KEY (ciudad_id) REFERENCES ciudades(ciudad_id)
);

-- Inserts iniciales
INSERT INTO paises (nombre) VALUES ('Argentina');

SET @pais_id_arg = (SELECT pais_id FROM paises WHERE nombre='Argentina');

INSERT INTO provincias (pais_id, nombre) VALUES (@pais_id_arg, 'Buenos Aires');

SET @prov_ba = (SELECT provincia_id FROM provincias WHERE nombre='Buenos Aires');

INSERT INTO ciudades (provincia_id, nombre) VALUES (@prov_ba, 'Ciudad de Buenos Aires');