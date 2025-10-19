CREATE DATABASE IF NOT EXISTS preguntados;
USE preguntados;

DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS ciudades;
DROP TABLE IF EXISTS paises;

CREATE TABLE paises (
                        pais_id INT NOT NULL AUTO_INCREMENT,
                        nombre VARCHAR(255) NOT NULL,

                        PRIMARY KEY (pais_id),
                        UNIQUE KEY uk_nombre_pais (nombre)

);


CREATE TABLE ciudades (
                          ciudad_id INT NOT NULL AUTO_INCREMENT,
                          pais_id INT NOT NULL,
                          nombre VARCHAR(255) NOT NULL,

                          PRIMARY KEY (ciudad_id),

                          FOREIGN KEY (pais_id)
                              REFERENCES paises(pais_id)
                              ON DELETE RESTRICT  -- Opcional: Evita borrar un país si tiene ciudades
                              ON UPDATE CASCADE   -- Opcional: Si el pais_id cambia, se actualiza aquí

);


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

                          rol VARCHAR (20) NOT NULL,

                          esta_verificado BOOLEAN NOT NULL DEFAULT FALSE,

                          fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,



    -- Definición de Claves Primarias y Únicas

                          PRIMARY KEY (usuario_id),

    -- Definición de Clave Foránea (FK)

    -- NOTA: Esto asume que ya existe una tabla 'ciudades' con una columna 'ciudad_id' que es PK.

                          FOREIGN KEY (ciudad_id) REFERENCES ciudades(ciudad_id)
);

    
-- INSERTS INICIALES
INSERT INTO paises (nombre) VALUES ('Argentina');

-- Obtener el ID de Argentina para la ciudad
SET @pais_id_arg = (SELECT pais_id FROM paises WHERE nombre='Argentina');

INSERT INTO ciudades (pais_id, nombre) VALUES (@pais_id_arg, 'Buenos Aires');