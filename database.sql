DROP DATABASE IF EXISTS preguntados;
CREATE DATABASE IF NOT EXISTS preguntados CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE preguntados;
DROP TABLE IF EXISTS usuarios_organizaciones;
DROP TABLE IF EXISTS organizaciones;
DROP TABLE IF EXISTS preguntas_reportadas;
DROP TABLE IF EXISTS respuestas_usuario;
DROP TABLE IF EXISTS respuestas;
DROP TABLE IF EXISTS preguntas;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS ciudades;
DROP TABLE IF EXISTS provincias;
DROP TABLE IF EXISTS paises;


CREATE TABLE paises (
                        pais_id INT NOT NULL AUTO_INCREMENT,
                        nombre VARCHAR(255) NOT NULL,
                        PRIMARY KEY (pais_id),
                        UNIQUE KEY uk_nombre_pais (nombre)
);

CREATE TABLE provincias (
                            provincia_id INT NOT NULL AUTO_INCREMENT,
                            pais_id INT NOT NULL,
                            nombre VARCHAR(255) NOT NULL,
                            PRIMARY KEY (provincia_id),
                            UNIQUE KEY uk_nombre_provincia (nombre, pais_id),
                            FOREIGN KEY (pais_id) REFERENCES paises(pais_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE ciudades (
                          ciudad_id INT NOT NULL AUTO_INCREMENT,
                          provincia_id INT NOT NULL,
                          nombre VARCHAR(255) NOT NULL,
                          PRIMARY KEY (ciudad_id),
                          UNIQUE KEY uk_nombre_ciudad (nombre, provincia_id),
                          FOREIGN KEY (provincia_id) REFERENCES provincias(provincia_id) ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE TABLE usuarios (
                          usuario_id INT NOT NULL AUTO_INCREMENT,
                          nombre_completo VARCHAR(255) NOT NULL,
                          nombre_usuario VARCHAR(100) UNIQUE NOT NULL,
                          email VARCHAR(255) UNIQUE NOT NULL,
                          contrasena_hash VARCHAR(255) NOT NULL,
                          ano_nacimiento INT NOT NULL,
                          sexo VARCHAR(20),
                          ciudad_id INT NOT NULL,
                          url_foto_perfil VARCHAR(500) NULL,
                          rol ENUM('usuario', 'editor', 'admin') NOT NULL DEFAULT 'usuario',
                          esta_verificado BOOLEAN NOT NULL DEFAULT FALSE,
                          fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                          token_verificacion VARCHAR(32) NULL,
                          ranking INT DEFAULT 0, -- Columna para puntaje total en el ranking

                          PRIMARY KEY (usuario_id),
                          FOREIGN KEY (ciudad_id) REFERENCES ciudades(ciudad_id)
);


CREATE TABLE categorias (
                            categoria_id INT NOT NULL AUTO_INCREMENT,
                            nombre VARCHAR(100) UNIQUE NOT NULL,
                            color_hex VARCHAR(7) NOT NULL,
                            PRIMARY KEY (categoria_id)
);

CREATE TABLE preguntas (
                           pregunta_id INT NOT NULL AUTO_INCREMENT,
                           categoria_id INT NOT NULL,
                           texto_pregunta TEXT NOT NULL,
                           estado ENUM('pendiente', 'activa', 'rechazada') NOT NULL DEFAULT 'pendiente',
                           dificultad DECIMAL(3,2) DEFAULT 0.50,

                           creada_por_usuario_id INT NULL,
                           aprobado_por_usuario_id INT NULL,

                           PRIMARY KEY (pregunta_id),
                           FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id),
                           FOREIGN KEY (creada_por_usuario_id) REFERENCES usuarios(usuario_id)
);

CREATE TABLE respuestas (
                            respuesta_id INT NOT NULL AUTO_INCREMENT,
                            pregunta_id INT NOT NULL,
                            texto_respuesta TEXT NOT NULL,
                            es_correcta BOOLEAN NOT NULL,
                            PRIMARY KEY (respuesta_id),
                            FOREIGN KEY (pregunta_id) REFERENCES preguntas(pregunta_id)
);

-- --------------------------------------------------------
-- 6. TABLA DE HISTORIAL DE RESPUESTAS Y CONTROL DE TIEMPO
-- --------------------------------------------------------

CREATE TABLE respuestas_usuario (
                                    respuesta_usuario_id INT NOT NULL AUTO_INCREMENT,
                                    usuario_id INT NOT NULL,
                                    pregunta_id INT NOT NULL,
                                    respuesta_id INT NOT NULL, -- La opción que seleccionó
                                    fue_correcta BOOLEAN NOT NULL,
                                    fecha_respuesta DATETIME NOT NULL,
                                    tiempo_inicio_pregunta DATETIME NOT NULL, -- 📌 MOVIMIENTO: Control de tiempo para los 40s

                                    PRIMARY KEY (respuesta_usuario_id),
                                    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
                                    FOREIGN KEY (pregunta_id) REFERENCES preguntas(pregunta_id),
                                    FOREIGN KEY (respuesta_id) REFERENCES respuestas(respuesta_id)
);

-- --------------------------------------------------------
-- 7. INSERTS DE DATOS DE PRUEBA
-- --------------------------------------------------------

-- Datos de Ubicación
INSERT INTO paises (nombre) VALUES ('Argentina');
SET @pais_id_arg = LAST_INSERT_ID();
INSERT INTO provincias (pais_id, nombre) VALUES (@pais_id_arg, 'Buenos Aires'), (@pais_id_arg, 'Córdoba');
SET @prov_ba = (SELECT provincia_id FROM provincias WHERE nombre='Buenos Aires');
INSERT INTO ciudades (provincia_id, nombre) VALUES (@prov_ba, 'La Matanza'), (@prov_ba, 'CABA');
SET @ciudad_caba = (SELECT ciudad_id FROM ciudades WHERE nombre='CABA');

-- Usuarios de Prueba (Contraseña: '12345678')
SET @hash_test = '$2y$10$oE509h7o02/6h0u6j5g.X.fL9g/S3lWjT3t.M1v2oK9Q2eK4G9g/';

INSERT INTO usuarios (nombre_completo, nombre_usuario, email, contrasena_hash, ano_nacimiento, sexo, ciudad_id, rol, esta_verificado) VALUES
                                                                                                                                          ('Admin', 'admin_test', 'admin@preguntados.com', @hash_test, 1990, 'M', @ciudad_caba, 'admin', TRUE),
                                                                                                                                          ('Editor Test', 'editor_test', 'editor@preguntados.com', @hash_test, 1995, 'F', @ciudad_caba, 'editor', TRUE),
                                                                                                                                          ('Usuario No Verificado', 'unverified', 'no_verificado@mail.com', @hash_test, 2000, 'X', @ciudad_caba, 'usuario', FALSE);

-- Datos de Contenido (Tecnología)
INSERT INTO categorias (nombre, color_hex) VALUES ('Tecnología', '#007bff'), ('Historia', '#dc3545');
SET @cat_tech = LAST_INSERT_ID();

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, dificultad) VALUES
    (@cat_tech, '¿Qué lenguaje de programación es el backend de este proyecto?', 'activa', 1, 0.20);
SET @preg1 = LAST_INSERT_ID(); -- @preg1 tiene el ID correcto

-- Pregunta 2: MVC
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, dificultad) VALUES
    (@cat_tech, '¿Cuál es el acrónimo para la arquitectura Modelo-Vista-Controlador?', 'activa', 1, 0.10);
SET @preg2 = LAST_INSERT_ID(); -- @preg2 tiene el ID correcto

-- --------------------------------------------------------
-- 2. INSERTS DE RESPUESTAS (Ahora son seguros)
-- --------------------------------------------------------

-- Respuestas para Pregunta 1
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg1, 'Python', FALSE),
                                                                       (@preg1, 'Java', FALSE),
                                                                       (@preg1, 'PHP', TRUE), -- Correcta
                                                                       (@preg1, 'C#', FALSE);

-- Respuestas para Pregunta 2 (Tu código con error original)
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg2, 'MVVM', FALSE),
                                                                       (@preg2, 'MVC', TRUE), -- Correcta
                                                                       (@preg2, 'REST', FALSE),
                                                                       (@preg2, 'HTTP', FALSE);