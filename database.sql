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
DROP TABLE IF EXISTS partidas_usuario;
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
                          ranking INT DEFAULT 100,
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
-- 6. TABLAS DE HISTORIAL Y REPORTES
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
                                    FOREIGN KEY (partida_id) REFERENCES partidas_usuario(partida_id) ON DELETE CASCADE,
                                    FOREIGN KEY (pregunta_id) REFERENCES preguntas(pregunta_id) ON DELETE CASCADE,
                                    FOREIGN KEY (respuesta_id) REFERENCES respuestas(respuesta_id) ON DELETE CASCADE
);

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
-- 7. TABLAS DE ORGANIZACIONES (EXTERNAS)
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
-- Ubicación
INSERT INTO paises (nombre) VALUES ('Argentina');
SET @pais_id_arg = LAST_INSERT_ID();
INSERT INTO provincias (pais_id, nombre) VALUES (@pais_id_arg, 'Buenos Aires');
SET @prov_ba = LAST_INSERT_ID();
INSERT INTO ciudades (provincia_id, nombre) VALUES (@prov_ba, 'CABA');
SET @ciudad_caba = LAST_INSERT_ID();

-- Usuarios de prueba
SET @hash_test = '$2y$10$ldqCeVk5gCcDoUEIYtSEGu7QW9vLD4ymMCA/Gc9oAYz.6v.eXLD2i';
INSERT INTO usuarios (nombre_completo, nombre_usuario, email, contrasena_hash, ano_nacimiento, sexo, ciudad_id, rol, esta_verificado) VALUES
                                                                                                                                          ('Admin Global', 'admin_test', 'admin@preguntados.com', @hash_test, 1990, 'M', @ciudad_caba, 'admin', TRUE),
                                                                                                                                          ('Editor Global', 'editor_test', 'editor@preguntados.com', @hash_test, 1995, 'F', @ciudad_caba, 'editor', TRUE);

SET @admin_id = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'admin_test');

-- Categorías
INSERT INTO categorias (nombre, color_hex) VALUES
                                               ('Geografía', '#3498DB'),
                                               ('Ciencia', '#2ECC71'),
                                               ('Cultura Pop', '#E74C3C'),
                                               ('Historia', '#DC3545')
ON DUPLICATE KEY UPDATE nombre = nombre;

SELECT categoria_id INTO @cat_geo FROM categorias WHERE nombre = 'Geografía';
SELECT categoria_id INTO @cat_cie FROM categorias WHERE nombre = 'Ciencia';
SELECT categoria_id INTO @cat_pop FROM categorias WHERE nombre = 'Cultura Pop';
SELECT categoria_id INTO @cat_his FROM categorias WHERE nombre = 'Historia';

-- --------------------------------------------------------
-- 9. PREGUNTAS Y RESPUESTAS
-- --------------------------------------------------------

-- ==========================
-- 📚 PREGUNTAS Y RESPUESTAS (20 EN TOTAL)
-- ==========================

-- 🌍 GEOGRAFÍA
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_geo, '¿Cuál es la capital de Francia?', 'activa', @admin_id, @admin_id);
SET @preg_geo1 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo1, 'París', 1), (@preg_geo1, 'Roma', 0), (@preg_geo1, 'Londres', 0), (@preg_geo1, 'Madrid', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_geo, '¿En qué país se encuentra la Torre de Pisa?', 'activa', @admin_id, @admin_id);
SET @preg_geo2 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo2, 'Italia', 1), (@preg_geo2, 'Francia', 0), (@preg_geo2, 'España', 0), (@preg_geo2, 'Portugal', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_geo, '¿Cuál es el río más largo del mundo?', 'activa', @admin_id, @admin_id);
SET @preg_geo3 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo3, 'Amazonas', 1), (@preg_geo3, 'Nilo', 0), (@preg_geo3, 'Yangtsé', 0), (@preg_geo3, 'Misisipi', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_geo, '¿En qué continente se encuentra el desierto del Sahara?', 'activa', @admin_id, @admin_id);
SET @preg_geo4 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo4, 'África', 1), (@preg_geo4, 'Asia', 0), (@preg_geo4, 'Oceanía', 0), (@preg_geo4, 'América del Sur', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_geo, '¿Cuál es el país más grande del mundo por superficie?', 'activa', @admin_id, @admin_id);
SET @preg_geo5 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo5, 'Rusia', 1), (@preg_geo5, 'Canadá', 0), (@preg_geo5, 'China', 0), (@preg_geo5, 'Estados Unidos', 0);

-- ⚛️ CIENCIA
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Cuál es la fórmula química del agua?', 'activa', @admin_id, @admin_id);
SET @preg_cie1 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie1, 'H2O', 1), (@preg_cie1, 'CO2', 0), (@preg_cie1, 'O2', 0), (@preg_cie1, 'NaCl', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué planeta es conocido como el “planeta rojo”?', 'activa', @admin_id, @admin_id);
SET @preg_cie2 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie2, 'Marte', 1), (@preg_cie2, 'Venus', 0), (@preg_cie2, 'Mercurio', 0), (@preg_cie2, 'Júpiter', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Cuál es el órgano más grande del cuerpo humano?', 'activa', @admin_id, @admin_id);
SET @preg_cie3 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie3, 'La piel', 1), (@preg_cie3, 'El hígado', 0), (@preg_cie3, 'El cerebro', 0), (@preg_cie3, 'El corazón', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Cuál es el planeta más grande del Sistema Solar?', 'activa', @admin_id, @admin_id);
SET @preg_cie4 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie4, 'Júpiter', 1), (@preg_cie4, 'Saturno', 0), (@preg_cie4, 'Urano', 0), (@preg_cie4, 'Neptuno', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Quién propuso la teoría de la relatividad?', 'activa', @admin_id, @admin_id);
SET @preg_cie5 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie5, 'Albert Einstein', 1), (@preg_cie5, 'Isaac Newton', 0), (@preg_cie5, 'Stephen Hawking', 0), (@preg_cie5, 'Galileo Galilei', 0);

-- 🏰 HISTORIA
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_his, '¿En qué año cayó el Muro de Berlín?', 'activa', @admin_id, @admin_id);
SET @preg_his1 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his1, '1989', 1), (@preg_his1, '1979', 0), (@preg_his1, '1991', 0), (@preg_his1, '1993', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_his, '¿Quién fue el primer emperador del Imperio Romano?', 'activa', @admin_id, @admin_id);
SET @preg_his2 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his2, 'Augusto', 1), (@preg_his2, 'Julio César', 0), (@preg_his2, 'Nerón', 0), (@preg_his2, 'Tiberio', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_his, '¿Qué civilización construyó las pirámides de Egipto?', 'activa', @admin_id, @admin_id);
SET @preg_his3 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his3, 'Los egipcios', 1), (@preg_his3, 'Los mayas', 0), (@preg_his3, 'Los romanos', 0), (@preg_his3, 'Los griegos', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_his, '¿Quién fue Cristóbal Colón?', 'activa', @admin_id, @admin_id);
SET @preg_his4 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his4, 'El navegante que descubrió América', 1), (@preg_his4, 'Un emperador romano', 0), (@preg_his4, 'Un científico italiano', 0), (@preg_his4, 'Un rey español', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_his, '¿Qué país inició la Primera Guerra Mundial?', 'activa', @admin_id, @admin_id);
SET @preg_his5 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his5, 'Alemania', 1), (@preg_his5, 'Inglaterra', 0), (@preg_his5, 'Francia', 0), (@preg_his5, 'Italia', 0);

-- 🎬 CULTURA POP / ENTRETENIMIENTO
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué actor interpreta a Iron Man en el Universo Cinematográfico de Marvel?', 'activa', @admin_id, @admin_id);
SET @preg_pop1 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop1, 'Robert Downey Jr.', 1), (@preg_pop1, 'Chris Evans', 0), (@preg_pop1, 'Chris Hemsworth', 0), (@preg_pop1, 'Mark Ruffalo', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué serie popular de Netflix está ambientada en Hawkins?', 'activa', @admin_id, @admin_id);
SET @preg_pop2 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop2, 'Stranger Things', 1), (@preg_pop2, 'The Umbrella Academy', 0), (@preg_pop2, 'Dark', 0), (@preg_pop2, 'The OA', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Quién es el protagonista de "Harry Potter"?', 'activa', @admin_id, @admin_id);
SET @preg_pop3 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop3, 'Harry Potter', 1), (@preg_pop3, 'Ron Weasley', 0), (@preg_pop3, 'Voldemort', 0), (@preg_pop3, 'Dumbledore', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿De qué banda era Freddie Mercury el vocalista?', 'activa', @admin_id, @admin_id);
SET @preg_pop4 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop4, 'Queen', 1), (@preg_pop4, 'The Beatles', 0), (@preg_pop4, 'U2', 0), (@preg_pop4, 'Coldplay', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué empresa creó la consola PlayStation?', 'activa', @admin_id, @admin_id);
SET @preg_pop5 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop5, 'Sony', 1), (@preg_pop5, 'Microsoft', 0), (@preg_pop5, 'Nintendo', 0), (@preg_pop5, 'Sega', 0);


