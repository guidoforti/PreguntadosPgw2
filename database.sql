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
                           estado ENUM('pendiente', 'activa', 'rechazada', 'reportada') NOT NULL DEFAULT 'pendiente',
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


INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿Cuál es la montaña más alta del mundo?', 'activa', @admin_id, @admin_id);
SET @preg_geo6 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo6, 'Monte Everest', 1), (@preg_geo6, 'K2', 0), (@preg_geo6, 'Aconcagua', 0), (@preg_geo6, 'Kilimanjaro', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿Cuál es el océano más grande del mundo?', 'activa', @admin_id, @admin_id);
SET @preg_geo7 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo7, 'Pacífico', 1), (@preg_geo7, 'Atlántico', 0), (@preg_geo7, 'Índico', 0), (@preg_geo7, 'Ártico', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿Cuál es la capital de Australia?', 'activa', @admin_id, @admin_id);
SET @preg_geo8 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo8, 'Canberra', 1), (@preg_geo8, 'Sídney', 0), (@preg_geo8, 'Melbourne', 0), (@preg_geo8, 'Brisbane', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿En qué país se encuentra el desierto de Atacama?', 'activa', @admin_id, @admin_id);
SET @preg_geo9 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo9, 'Chile', 1), (@preg_geo9, 'Argentina', 0), (@preg_geo9, 'Perú', 0), (@preg_geo9, 'Bolivia', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿Qué estrecho separa Europa de África?', 'activa', @admin_id, @admin_id);
SET @preg_geo10 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo10, 'Estrecho de Gibraltar', 1), (@preg_geo10, 'Canal de Suez', 0), (@preg_geo10, 'Estrecho de Bering', 0), (@preg_geo10, 'Canal de la Mancha', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿Cuál es la capital de Japón?', 'activa', @admin_id, @admin_id);
SET @preg_geo11 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo11, 'Tokio', 1), (@preg_geo11, 'Kioto', 0), (@preg_geo11, 'Osaka', 0), (@preg_geo11, 'Seúl', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿En qué país se encuentra la Gran Muralla?', 'activa', @admin_id, @admin_id);
SET @preg_geo12 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo12, 'China', 1), (@preg_geo12, 'India', 0), (@preg_geo12, 'Mongolia', 0), (@preg_geo12, 'Japón', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿En qué país se encuentra el Gran Cañón?', 'activa', @admin_id, @admin_id);
SET @preg_geo13 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo13, 'Estados Unidos', 1), (@preg_geo13, 'Canadá', 0), (@preg_geo13, 'México', 0), (@preg_geo13, 'Brasil', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿Cuál es el lago más grande de África?', 'activa', @admin_id, @admin_id);
SET @preg_geo14 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo14, 'Lago Victoria', 1), (@preg_geo14, 'Lago Tanganica', 0), (@preg_geo14, 'Lago Malaui', 0), (@preg_geo14, 'Lago Chad', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_geo, '¿Cuál es el país más grande de Sudamérica?', 'activa', @admin_id, @admin_id);
SET @preg_geo15 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo15, 'Brasil', 1), (@preg_geo15, 'Argentina', 0), (@preg_geo15, 'Perú', 0), (@preg_geo15, 'Colombia', 0);
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
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué partícula subatómica tiene carga negativa?', 'activa', @admin_id, @admin_id);
SET @preg_cie6 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie6, 'Electrón', 1), (@preg_cie6, 'Protón', 0), (@preg_cie6, 'Neutrón', 0), (@preg_cie6, 'Positrón', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué gas necesitan las plantas para realizar la fotosíntesis?', 'activa', @admin_id, @admin_id);
SET @preg_cie7 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie7, 'Dióxido de carbono', 1), (@preg_cie7, 'Oxígeno', 0), (@preg_cie7, 'Nitrógeno', 0), (@preg_cie7, 'Hidrógeno', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué unidad se utiliza para medir la intensidad de la corriente eléctrica?', 'activa', @admin_id, @admin_id);
SET @preg_cie8 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie8, 'Amperio', 1), (@preg_cie8, 'Voltio', 0), (@preg_cie8, 'Ohmio', 0), (@preg_cie8, 'Watt', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué científico formuló las leyes del movimiento y la gravedad?', 'activa', @admin_id, @admin_id);
SET @preg_cie9 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie9, 'Isaac Newton', 1), (@preg_cie9, 'Galileo Galilei', 0), (@preg_cie9, 'Albert Einstein', 0), (@preg_cie9, 'Nicolás Copérnico', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué elemento químico tiene el símbolo “Fe”?', 'activa', @admin_id, @admin_id);
SET @preg_cie10 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie10, 'Hierro', 1), (@preg_cie10, 'Flúor', 0), (@preg_cie10, 'Francio', 0), (@preg_cie10, 'Fósforo', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué órgano del cuerpo humano bombea la sangre?', 'activa', @admin_id, @admin_id);
SET @preg_cie11 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie11, 'El corazón', 1), (@preg_cie11, 'El pulmón', 0), (@preg_cie11, 'El riñón', 0), (@preg_cie11, 'El hígado', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué instrumento mide la presión atmosférica?', 'activa', @admin_id, @admin_id);
SET @preg_cie12 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie12, 'Barómetro', 1), (@preg_cie12, 'Termómetro', 0), (@preg_cie12, 'Anemómetro', 0), (@preg_cie12, 'Higrómetro', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué tipo de célula no tiene núcleo definido?', 'activa', @admin_id, @admin_id);
SET @preg_cie13 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie13, 'Procariota', 1), (@preg_cie13, 'Eucariota', 0), (@preg_cie13, 'Somática', 0), (@preg_cie13, 'Neurona', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué órgano del sistema nervioso controla las funciones del cuerpo?', 'activa', @admin_id, @admin_id);
SET @preg_cie14 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie14, 'El cerebro', 1), (@preg_cie14, 'El corazón', 0), (@preg_cie14, 'El páncreas', 0), (@preg_cie14, 'El intestino', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Cuál es el metal más ligero?', 'activa', @admin_id, @admin_id);
SET @preg_cie15 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie15, 'Litio', 1), (@preg_cie15, 'Aluminio', 0), (@preg_cie15, 'Sodio', 0), (@preg_cie15, 'Magnesio', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_cie, '¿Qué científico descubrió la penicilina?', 'activa', @admin_id, @admin_id);
SET @preg_cie16 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie16, 'Alexander Fleming', 1), (@preg_cie16, 'Louis Pasteur', 0), (@preg_cie16, 'Marie Curie', 0), (@preg_cie16, 'Charles Darwin', 0);
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

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿Quién pintó la "Mona Lisa"?', 'activa', @admin_id, @admin_id);
SET @preg_his6 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his6, 'Leonardo da Vinci', 1), (@preg_his6, 'Michelangelo', 0), (@preg_his6, 'Raphael', 0), (@preg_his6, 'Donatello', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿Qué evento desencadenó la Primera Guerra Mundial?', 'activa', @admin_id, @admin_id);
SET @preg_his7 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his7, 'El asesinato del archiduque Francisco Fernando', 1), (@preg_his7, 'La invasión de Polonia', 0), (@preg_his7, 'El hundimiento del Lusitania', 0), (@preg_his7, 'La Revolución Francesa', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿En qué año llegó Cristóbal Colón a América por primera vez?', 'activa', @admin_id, @admin_id);
SET @preg_his8 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his8, '1492', 1), (@preg_his8, '1776', 0), (@preg_his8, '1588', 0), (@preg_his8, '1453', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿Quién fue la primera persona en caminar sobre la Luna?', 'activa', @admin_id, @admin_id);
SET @preg_his9 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his9, 'Neil Armstrong', 1), (@preg_his9, 'Buzz Aldrin', 0), (@preg_his9, 'Yuri Gagarin', 0), (@preg_his9, 'Michael Collins', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿Qué imperio antiguo era gobernado por Faraones?', 'activa', @admin_id, @admin_id);
SET @preg_his10 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his10, 'Egipto', 1), (@preg_his10, 'Roma', 0), (@preg_his10, 'Persia', 0), (@preg_his10, 'Grecia', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿Qué fue la "Carta Magna"?', 'activa', @admin_id, @admin_id);
SET @preg_his11 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his11, 'Una carta real de derechos en Inglaterra', 1), (@preg_his11, 'Una pintura famosa', 0), (@preg_his11, 'Una declaración de guerra', 0), (@preg_his11, 'Un poema épico', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿Quién lideró la Unión Soviética durante la Segunda Guerra Mundial?', 'activa', @admin_id, @admin_id);
SET @preg_his12 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his12, 'Joseph Stalin', 1), (@preg_his12, 'Vladimir Lenin', 0), (@preg_his12, 'Mikhail Gorbachev', 0), (@preg_his12, 'Nikita Khrushchev', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿Qué batalla marcó el fin del reinado de Napoleón Bonaparte?', 'activa', @admin_id, @admin_id);
SET @preg_his13 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his13, 'La Batalla de Waterloo', 1), (@preg_his13, 'La Batalla de Trafalgar', 0), (@preg_his13, 'La Batalla de Austerlitz', 0), (@preg_his13, 'La Batalla de Hastings', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿Quién escribió "El Manifiesto Comunista"?', 'activa', @admin_id, @admin_id);
SET @preg_his14 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his14, 'Karl Marx y Friedrich Engels', 1), (@preg_his14, 'Adam Smith', 0), (@preg_his14, 'Vladimir Lenin', 0), (@preg_his14, 'John Locke', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES (@cat_his, '¿Qué civilización construyó Machu Picchu?', 'activa', @admin_id, @admin_id);
SET @preg_his15 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his15, 'Los Incas', 1), (@preg_his15, 'Los Aztecas', 0), (@preg_his15, 'Los Mayas', 0), (@preg_his15, 'Los Egipcios', 0);
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

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué película ganó el Óscar a Mejor Película en 1997?', 'activa', @admin_id, @admin_id);
SET @preg_pop6 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop6, 'Titanic', 1), (@preg_pop6, 'Gladiador', 0), (@preg_pop6, 'Braveheart', 0), (@preg_pop6, 'Forrest Gump', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué cantante es conocido como "El Rey del Pop"?', 'activa', @admin_id, @admin_id);
SET @preg_pop7 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop7, 'Michael Jackson', 1), (@preg_pop7, 'Prince', 0), (@preg_pop7, 'Elvis Presley', 0), (@preg_pop7, 'Justin Timberlake', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿En qué año se estrenó la primera película de Star Wars?', 'activa', @admin_id, @admin_id);
SET @preg_pop8 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop8, '1977', 1), (@preg_pop8, '1980', 0), (@preg_pop8, '1975', 0), (@preg_pop8, '1983', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Cuál es el nombre del superhéroe alter ego de Bruce Wayne?', 'activa', @admin_id, @admin_id);
SET @preg_pop9 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop9, 'Batman', 1), (@preg_pop9, 'Superman', 0), (@preg_pop9, 'Iron Man', 0), (@preg_pop9, 'Spider-Man', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué serie de televisión presenta un trono hecho de espadas?', 'activa', @admin_id, @admin_id);
SET @preg_pop10 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop10, 'Game of Thrones', 1), (@preg_pop10, 'Vikings', 0), (@preg_pop10, 'The Witcher', 0), (@preg_pop10, 'The Crown', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué famoso videojuego incluye personajes como Mario, Luigi y Bowser?', 'activa', @admin_id, @admin_id);
SET @preg_pop11 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop11, 'Super Mario Bros', 1), (@preg_pop11, 'Donkey Kong', 0), (@preg_pop11, 'Sonic the Hedgehog', 0), (@preg_pop11, 'Zelda', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué artista lanzó el álbum "1989"?', 'activa', @admin_id, @admin_id);
SET @preg_pop12 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop12, 'Taylor Swift', 1), (@preg_pop12, 'Adele', 0), (@preg_pop12, 'Katy Perry', 0), (@preg_pop12, 'Billie Eilish', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿En qué ciudad vive la familia Simpson?', 'activa', @admin_id, @admin_id);
SET @preg_pop13 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop13, 'Springfield', 1), (@preg_pop13, 'Shelbyville', 0), (@preg_pop13, 'Quahog', 0), (@preg_pop13, 'South Park', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué película presenta al personaje Jack Sparrow?', 'activa', @admin_id, @admin_id);
SET @preg_pop14 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop14, 'Piratas del Caribe', 1), (@preg_pop14, 'El Señor de los Anillos', 0), (@preg_pop14, 'Avatar', 0), (@preg_pop14, 'Indiana Jones', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Qué banda compuso el álbum "Abbey Road"?', 'activa', @admin_id, @admin_id);
SET @preg_pop15 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop15, 'The Beatles', 1), (@preg_pop15, 'The Rolling Stones', 0), (@preg_pop15, 'Pink Floyd', 0), (@preg_pop15, 'Led Zeppelin', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id)
VALUES
    (@cat_pop, '¿Quién interpretó a "El Joker" en la película de 2019?', 'activa', @admin_id, @admin_id);
SET @preg_pop16 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop16, 'Joaquin Phoenix', 1), (@preg_pop16, 'Heath Ledger', 0), (@preg_pop16, 'Jared Leto', 0), (@preg_pop16, 'Jack Nicholson', 0);

