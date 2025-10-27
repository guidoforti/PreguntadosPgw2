-- --------------------------------------------------------
-- 1. CONFIGURACIÓN INICIAL Y BORRADO DE BASE DE DATOS
-- --------------------------------------------------------
DROP DATABASE IF EXISTS preguntados;
CREATE DATABASE IF NOT EXISTS preguntados CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE preguntados;

-- --------------------------------------------------------
-- 2. LIMPIEZA DE TABLAS (ORDEN INVERSO POR CLAVES FORÁNEAS)
-- --------------------------------------------------------
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

-- --------------------------------------------------------
-- 3. TABLAS DE UBICACIÓN
-- --------------------------------------------------------

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

-- --------------------------------------------------------
-- 4. TABLAS DE USUARIOS Y ROLES
-- --------------------------------------------------------

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
                          ranking INT DEFAULT 0,

                          PRIMARY KEY (usuario_id),
                          FOREIGN KEY (ciudad_id) REFERENCES ciudades(ciudad_id)
);

-- --------------------------------------------------------
-- 5. TABLAS DE CONTENIDO Y JUEGO CORE
-- --------------------------------------------------------

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
                            FOREIGN KEY (pregunta_id) REFERENCES preguntas(pregunta_id) ON DELETE CASCADE
);

-- --------------------------------------------------------
-- 6. TABLAS DE HISTORIAL Y GESTIÓN (REPORTE) + TABLA DE PARTIDA
-- --------------------------------------------------------

CREATE TABLE partidas_usuario (
                                    partida_id INT AUTO_INCREMENT PRIMARY KEY,
                                    usuario_id INT NOT NULL,
                                    puntaje INT DEFAULT 0,
                                    estado ENUM('en_curso', 'finalizada', 'perdida', 'interrumpida') DEFAULT 'en_curso',
                                    fecha_inicio DATETIME DEFAULT CURRENT_TIMESTAMP,
                                    fecha_fin DATETIME NULL,
                                    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
    );

CREATE TABLE respuestas_usuario (
                                    respuesta_usuario_id INT NOT NULL AUTO_INCREMENT,
                                    usuario_id INT NOT NULL,
                                    partida_id INT NOT NULL,
                                    pregunta_id INT NOT NULL,
                                    respuesta_id INT NULL,
                                    fue_correcta BOOLEAN NOT NULL,
                                    fecha_respuesta DATETIME NOT NULL,
                                    tiempo_inicio_pregunta DATETIME NOT NULL,

                                    PRIMARY KEY (respuesta_usuario_id),
                                    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
                                    FOREIGN KEY (partida_id) REFERENCES partidas_usuario(partida_id) ON DELETE CASCADE, -- FK agregada
                                    FOREIGN KEY (pregunta_id) REFERENCES preguntas(pregunta_id) ON DELETE CASCADE,
                                    FOREIGN KEY (respuesta_id) REFERENCES respuestas(respuesta_id) ON DELETE CASCADE
);

-- 📌 TABLA AGREGADA: Para la revisión de Editores
CREATE TABLE preguntas_reportadas (
                                      reporte_id INT NOT NULL AUTO_INCREMENT,
                                      pregunta_id INT NOT NULL,
                                      reportado_por_usuario_id INT NOT NULL,
                                      motivo TEXT NOT NULL,
                                      estado ENUM('reportado', 'aprobado', 'rechazado') NOT NULL DEFAULT 'reportado',
                                      fecha_reporte DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                      revisado_por_usuario_id INT NULL,

                                      PRIMARY KEY (reporte_id),
                                      FOREIGN KEY (pregunta_id) REFERENCES preguntas(pregunta_id) ON DELETE CASCADE,
                                      FOREIGN KEY (reportado_por_usuario_id) REFERENCES usuarios(usuario_id) ON DELETE RESTRICT,
                                      FOREIGN KEY (revisado_por_usuario_id) REFERENCES usuarios(usuario_id) ON DELETE SET NULL
);

-- --------------------------------------------------------
-- 7. TABLAS DE TERCEROS (MERMAID COMPLETO)
-- --------------------------------------------------------

CREATE TABLE organizaciones (
                                organizacion_id INT NOT NULL AUTO_INCREMENT,
                                nombre VARCHAR(255) UNIQUE NOT NULL,
                                identificador_qr VARCHAR(50) UNIQUE NOT NULL,
                                PRIMARY KEY (organizacion_id)
);

CREATE TABLE usuarios_organizaciones (
                                         usuario_organizacion_id INT NOT NULL AUTO_INCREMENT,
                                         usuario_id INT NOT NULL,
                                         organizacion_id INT NOT NULL,
                                         fecha_activacion DATETIME NOT NULL,

                                         PRIMARY KEY (usuario_organizacion_id),
                                         FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
                                         FOREIGN KEY (organizacion_id) REFERENCES organizaciones(organizacion_id) ON DELETE CASCADE
);


-- --------------------------------------------------------
-- 8. INSERTS DE DATOS DE PRUEBA
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
                                                                                                                                          ('Admin Global', 'admin_test', 'admin@preguntados.com', @hash_test, 1990, 'M', @ciudad_caba, 'admin', TRUE),
                                                                                                                                          ('Editor Global', 'editor_test', 'editor@preguntados.com', @hash_test, 1995, 'F', @ciudad_caba, 'editor', TRUE),
                                                                                                                                          ('Usuario No Verificado', 'unverified', 'no_verificado@mail.com', @hash_test, 2000, 'X', @ciudad_caba, 'usuario', FALSE);

-- Datos de Contenido (Categorías y Preguntas)
INSERT INTO categorias (nombre, color_hex) VALUES ('Tecnología', '#007bff'), ('Historia', '#dc3545');
SET @cat_tech = LAST_INSERT_ID();

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, dificultad) VALUES
    (@cat_tech, '¿Qué lenguaje de programación es el backend de este proyecto?', 'activa', 1, 0.20);
SET @preg1 = LAST_INSERT_ID();

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, dificultad) VALUES
    (@cat_tech, '¿Cuál es el acrónimo para la arquitectura Modelo-Vista-Controlador?', 'activa', 1, 0.10);
SET @preg2 = LAST_INSERT_ID();

-- Respuestas para Pregunta 1
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg1, 'Python', FALSE), (@preg1, 'Java', FALSE), (@preg1, 'PHP', TRUE), (@preg1, 'C#', FALSE);

-- Respuestas para Pregunta 2
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg2, 'MVVM', FALSE), (@preg2, 'MVC', TRUE), (@preg2, 'REST', FALSE), (@preg2, 'HTTP', FALSE);
INSERT INTO categorias (nombre, color_hex) VALUES
                                               ('Geografía', '#3498DB'),
                                               ('Ciencia', '#2ECC71'),
                                               ('Cultura Pop', '#E74C3C')
ON DUPLICATE KEY UPDATE nombre=nombre;

SELECT categoria_id INTO @cat_geo FROM categorias WHERE nombre = 'Geografía';
SELECT categoria_id INTO @cat_cie FROM categorias WHERE nombre = 'Ciencia';
SELECT categoria_id INTO @cat_pop FROM categorias WHERE nombre = 'Cultura Pop';

-- Pregunta 1 (Geografía)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿Cuál es la capital de Francia?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'París', 1),
                                                                       (LAST_INSERT_ID(), 'Londres', 0),
                                                                       (LAST_INSERT_ID(), 'Madrid', 0),
                                                                       (LAST_INSERT_ID(), 'Berlín', 0);

-- Pregunta 2 (Geografía)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿En qué país se encuentran las pirámides de Giza?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'Egipto', 1),
                                                                       (LAST_INSERT_ID(), 'México', 0),
                                                                       (LAST_INSERT_ID(), 'Grecia', 0),
                                                                       (LAST_INSERT_ID(), 'Perú', 0);

-- Pregunta 3 (Geografía)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿Cuál es el río más largo del mundo?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'Amazonas', 1),
                                                                       (LAST_INSERT_ID(), 'Nilo', 0),
                                                                       (LAST_INSERT_ID(), 'Misisipi', 0),
                                                                       (LAST_INSERT_ID(), 'Danubio', 0);

-- Pregunta 4 (Ciencia)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_cie, '¿Cuál es la fórmula química del agua?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'H2O', 1),
                                                                       (LAST_INSERT_ID(), 'CO2', 0),
                                                                       (LAST_INSERT_ID(), 'O2', 0),
                                                                       (LAST_INSERT_ID(), 'NaCl', 0);

-- Pregunta 5 (Ciencia)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_cie, '¿Cuál es el planeta más cercano al Sol?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'Mercurio', 1),
                                                                       (LAST_INSERT_ID(), 'Venus', 0),
                                                                       (LAST_INSERT_ID(), 'Marte', 0),
                                                                       (LAST_INSERT_ID(), 'Tierra', 0);

-- Pregunta 6 (Ciencia)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_cie, '¿Cómo se llama el proceso de las plantas para crear su alimento?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'Fotosíntesis', 1),
                                                                       (LAST_INSERT_ID(), 'Respiración', 0),
                                                                       (LAST_INSERT_ID(), 'Digestión', 0),
                                                                       (LAST_INSERT_ID(), 'Mitosis', 0);

-- Pregunta 7 (Cultura Pop)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_pop, '¿Quién pintó la "Mona Lisa"?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'Leonardo da Vinci', 1),
                                                                       (LAST_INSERT_ID(), 'Miguel Ángel', 0),
                                                                       (LAST_INSERT_ID(), 'Picasso', 0),
                                                                       (LAST_INSERT_ID(), 'Van Gogh', 0);

-- Pregunta 8 (Cultura Pop)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_pop, '¿Cómo se llama el fontanero de Nintendo?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'Mario', 1),
                                                                       (LAST_INSERT_ID(), 'Luigi', 0),
                                                                       (LAST_INSERT_ID(), 'Wario', 0),
                                                                       (LAST_INSERT_ID(), 'Sonic', 0);

-- Pregunta 9 (Cultura Pop)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_pop, '¿De qué banda era vocalista Freddie Mercury?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'Queen', 1),
                                                                       (LAST_INSERT_ID(), 'The Beatles', 0),
                                                                       (LAST_INSERT_ID(), 'U2', 0),
                                                                       (LAST_INSERT_ID(), 'Nirvana', 0);

-- Pregunta 10 (Cultura Pop)
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_pop, '¿Quién es el protagonista principal de "Harry Potter"?', 'activa', @admin_id, @admin_id);
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (LAST_INSERT_ID(), 'Harry Potter', 1),
                                                                       (LAST_INSERT_ID(), 'Ron Weasley', 0),
                                                                       (LAST_INSERT_ID(), 'Lord Voldemort', 0),
                                                                       (LAST_INSERT_ID(), 'Dumbledore', 0);