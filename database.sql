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
                           fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
INSERT INTO paises (nombre) VALUES
('Argentina'),
('España'),
('México'),
('Colombia'),
('Estados Unidos'),
('Brasil'),
('Chile'),
('Perú');

SET @pais_id_arg = (SELECT pais_id FROM paises WHERE nombre = 'Argentina');
SET @pais_id_esp = (SELECT pais_id FROM paises WHERE nombre = 'España');
SET @pais_id_mex = (SELECT pais_id FROM paises WHERE nombre = 'México');
SET @pais_id_col = (SELECT pais_id FROM paises WHERE nombre = 'Colombia');
SET @pais_id_usa = (SELECT pais_id FROM paises WHERE nombre = 'Estados Unidos');
SET @pais_id_bra = (SELECT pais_id FROM paises WHERE nombre = 'Brasil');
SET @pais_id_chi = (SELECT pais_id FROM paises WHERE nombre = 'Chile');
SET @pais_id_per = (SELECT pais_id FROM paises WHERE nombre = 'Perú');

-- Argentina
INSERT INTO provincias (pais_id, nombre) VALUES
(@pais_id_arg, 'Buenos Aires'),
(@pais_id_arg, 'Córdoba'),
(@pais_id_arg, 'Mendoza');
SET @prov_ba = (SELECT provincia_id FROM provincias WHERE nombre = 'Buenos Aires' AND pais_id = @pais_id_arg);
SET @prov_cor = (SELECT provincia_id FROM provincias WHERE nombre = 'Córdoba' AND pais_id = @pais_id_arg);
SET @prov_men = (SELECT provincia_id FROM provincias WHERE nombre = 'Mendoza' AND pais_id = @pais_id_arg);

INSERT INTO ciudades (provincia_id, nombre) VALUES
(@prov_ba, 'CABA'), (@prov_ba, 'La Plata'),
(@prov_cor, 'Córdoba'), (@prov_cor, 'Río Cuarto'),
(@prov_men, 'Mendoza'), (@prov_men, 'San Rafael');
SET @ciudad_caba = (SELECT ciudad_id FROM ciudades WHERE nombre = 'CABA');
SET @ciudad_laplata = (SELECT ciudad_id FROM ciudades WHERE nombre = 'La Plata');
SET @ciudad_cordoba = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Córdoba');
SET @ciudad_riocuarto = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Río Cuarto');
SET @ciudad_mendoza = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Mendoza');
SET @ciudad_sanrafael = (SELECT ciudad_id FROM ciudades WHERE nombre = 'San Rafael');

-- España
INSERT INTO provincias (pais_id, nombre) VALUES
(@pais_id_esp, 'Madrid'),
(@pais_id_esp, 'Barcelona'),
(@pais_id_esp, 'Valencia');
SET @prov_mad = (SELECT provincia_id FROM provincias WHERE nombre = 'Madrid' AND pais_id = @pais_id_esp);
SET @prov_bar = (SELECT provincia_id FROM provincias WHERE nombre = 'Barcelona' AND pais_id = @pais_id_esp);
SET @prov_val = (SELECT provincia_id FROM provincias WHERE nombre = 'Valencia' AND pais_id = @pais_id_esp);

INSERT INTO ciudades (provincia_id, nombre) VALUES
(@prov_mad, 'Madrid'), (@prov_mad, 'Alcalá de Henares'),
(@prov_bar, 'Barcelona'), (@prov_bar, 'Sabadell'),
(@prov_val, 'Valencia'), (@prov_val, 'Alicante');
SET @ciudad_madrid = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Madrid');
SET @ciudad_alcala = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Alcalá de Henares');
SET @ciudad_barcelona = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Barcelona');
SET @ciudad_sabadell = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Sabadell');
SET @ciudad_valencia = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Valencia');
SET @ciudad_alicante = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Alicante');

-- México
INSERT INTO provincias (pais_id, nombre) VALUES
(@pais_id_mex, 'Ciudad de México'),
(@pais_id_mex, 'Jalisco'),
(@pais_id_mex, 'Nuevo León');
SET @prov_cdmx = (SELECT provincia_id FROM provincias WHERE nombre = 'Ciudad de México' AND pais_id = @pais_id_mex);
SET @prov_jal = (SELECT provincia_id FROM provincias WHERE nombre = 'Jalisco' AND pais_id = @pais_id_mex);
SET @prov_nl = (SELECT provincia_id FROM provincias WHERE nombre = 'Nuevo León' AND pais_id = @pais_id_mex);

INSERT INTO ciudades (provincia_id, nombre) VALUES
(@prov_cdmx, 'CDMX'), (@prov_cdmx, 'Toluca'),
(@prov_jal, 'Guadalajara'), (@prov_jal, 'Puerto Vallarta'),
(@prov_nl, 'Monterrey'), (@prov_nl, 'Guadalupe');
SET @ciudad_cdmx = (SELECT ciudad_id FROM ciudades WHERE nombre = 'CDMX');
SET @ciudad_toluca = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Toluca');
SET @ciudad_guadalajara = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Guadalajara');
SET @ciudad_pvallarta = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Puerto Vallarta');
SET @ciudad_monterrey = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Monterrey');
SET @ciudad_guadalupe = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Guadalupe');

-- Colombia
INSERT INTO provincias (pais_id, nombre) VALUES
(@pais_id_col, 'Bogotá'),
(@pais_id_col, 'Medellín'),
(@pais_id_col, 'Cali');
SET @prov_bog = (SELECT provincia_id FROM provincias WHERE nombre = 'Bogotá' AND pais_id = @pais_id_col);
SET @prov_med = (SELECT provincia_id FROM provincias WHERE nombre = 'Medellín' AND pais_id = @pais_id_col);
SET @prov_cal = (SELECT provincia_id FROM provincias WHERE nombre = 'Cali' AND pais_id = @pais_id_col);

INSERT INTO ciudades (provincia_id, nombre) VALUES
(@prov_bog, 'Bogotá'), (@prov_bog, 'Soacha'),
(@prov_med, 'Medellín'), (@prov_med, 'Envigado'),
(@prov_cal, 'Cali'), (@prov_cal, 'Palmira');
SET @ciudad_bogota = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Bogotá');
SET @ciudad_soacha = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Soacha');
SET @ciudad_medellin = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Medellín');
SET @ciudad_envigado = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Envigado');
SET @ciudad_cali = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Cali');
SET @ciudad_palmira = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Palmira');

-- USA
INSERT INTO provincias (pais_id, nombre) VALUES
(@pais_id_usa, 'California'),
(@pais_id_usa, 'Texas'),
(@pais_id_usa, 'Florida');
SET @prov_ca = (SELECT provincia_id FROM provincias WHERE nombre = 'California' AND pais_id = @pais_id_usa);
SET @prov_tx = (SELECT provincia_id FROM provincias WHERE nombre = 'Texas' AND pais_id = @pais_id_usa);
SET @prov_fl = (SELECT provincia_id FROM provincias WHERE nombre = 'Florida' AND pais_id = @pais_id_usa);

INSERT INTO ciudades (provincia_id, nombre) VALUES
(@prov_ca, 'Los Angeles'), (@prov_ca, 'San Francisco'),
(@prov_tx, 'Houston'), (@prov_tx, 'Dallas'),
(@prov_fl, 'Miami'), (@prov_fl, 'Orlando');
SET @ciudad_losangeles = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Los Angeles' AND provincia_id = @prov_ca);
SET @ciudad_sanfrancisco = (SELECT ciudad_id FROM ciudades WHERE nombre = 'San Francisco');
SET @ciudad_houston = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Houston');
SET @ciudad_dallas = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Dallas');
SET @ciudad_miami = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Miami');
SET @ciudad_orlando = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Orlando');

-- Brasil
INSERT INTO provincias (pais_id, nombre) VALUES
(@pais_id_bra, 'São Paulo'),
(@pais_id_bra, 'Rio de Janeiro'),
(@pais_id_bra, 'Minas Gerais');
SET @prov_sp = (SELECT provincia_id FROM provincias WHERE nombre = 'São Paulo' AND pais_id = @pais_id_bra);
SET @prov_rj = (SELECT provincia_id FROM provincias WHERE nombre = 'Rio de Janeiro' AND pais_id = @pais_id_bra);
SET @prov_mg = (SELECT provincia_id FROM provincias WHERE nombre = 'Minas Gerais' AND pais_id = @pais_id_bra);

INSERT INTO ciudades (provincia_id, nombre) VALUES
(@prov_sp, 'São Paulo'), (@prov_sp, 'Campinas'),
(@prov_rj, 'Rio de Janeiro'), (@prov_rj, 'Niterói'),
(@prov_mg, 'Belo Horizonte'), (@prov_mg, 'Ouro Preto');
SET @ciudad_saopaulo = (SELECT ciudad_id FROM ciudades WHERE nombre = 'São Paulo');
SET @ciudad_campinas = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Campinas');
SET @ciudad_rio = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Rio de Janeiro');
SET @ciudad_niteroi = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Niterói');
SET @ciudad_belohorizonte = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Belo Horizonte');
SET @ciudad_ouropreto = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Ouro Preto');

-- Chile
INSERT INTO provincias (pais_id, nombre) VALUES
(@pais_id_chi, 'Región Metropolitana'),
(@pais_id_chi, 'Valparaíso'),
(@pais_id_chi, 'Biobío');
SET @prov_rm = (SELECT provincia_id FROM provincias WHERE nombre = 'Región Metropolitana' AND pais_id = @pais_id_chi);
SET @prov_vp = (SELECT provincia_id FROM provincias WHERE nombre = 'Valparaíso' AND pais_id = @pais_id_chi);
SET @prov_bio = (SELECT provincia_id FROM provincias WHERE nombre = 'Biobío' AND pais_id = @pais_id_chi);

INSERT INTO ciudades (provincia_id, nombre) VALUES
(@prov_rm, 'Santiago'), (@prov_rm, 'Puente Alto'),
(@prov_vp, 'Valparaíso'), (@prov_vp, 'Viña del Mar'),
(@prov_bio, 'Concepción'), (@prov_bio, 'Los Ángeles');
SET @ciudad_santiago = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Santiago');
SET @ciudad_puentealto = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Puente Alto');
SET @ciudad_valparaiso = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Valparaíso');
SET @ciudad_vinadelmar = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Viña del Mar');
SET @ciudad_concepcion = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Concepción');
SET @ciudad_losangeles_chi = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Los Ángeles' AND provincia_id = @prov_bio);

-- Perú
INSERT INTO provincias (pais_id, nombre) VALUES
(@pais_id_per, 'Lima'),
(@pais_id_per, 'Arequipa'),
(@pais_id_per, 'Cusco');
SET @prov_lima_per = (SELECT provincia_id FROM provincias WHERE nombre = 'Lima' AND pais_id = @pais_id_per);
SET @prov_areq = (SELECT provincia_id FROM provincias WHERE nombre = 'Arequipa' AND pais_id = @pais_id_per);
SET @prov_cusco = (SELECT provincia_id FROM provincias WHERE nombre = 'Cusco' AND pais_id = @pais_id_per);

INSERT INTO ciudades (provincia_id, nombre) VALUES
(@prov_lima_per, 'Lima'), (@prov_lima_per, 'San Isidro'),
(@prov_areq, 'Arequipa'), (@prov_areq, 'Puno'),
(@prov_cusco, 'Cusco'), (@prov_cusco, 'Urubamba');
SET @ciudad_lima = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Lima');
SET @ciudad_sanisidro = (SELECT ciudad_id FROM ciudades WHERE nombre = 'San Isidro');
SET @ciudad_arequipa = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Arequipa');
SET @ciudad_puno = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Puno');
SET @ciudad_cusco = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Cusco');
SET @ciudad_urubamba = (SELECT ciudad_id FROM ciudades WHERE nombre = 'Urubamba');

-- Usuarios de prueba con diversos datos demográficos
SET @hash_test = '$2y$10$ldqCeVk5gCcDoUEIYtSEGu7QW9vLD4ymMCA/Gc9oAYz.6v.eXLD2i';
INSERT INTO usuarios (nombre_completo, nombre_usuario, email, contrasena_hash, ano_nacimiento, sexo, ciudad_id, rol, esta_verificado, fecha_creacion) VALUES
('Admin Global', 'admin_test', 'admin@preguntados.com', @hash_test, 1990, 'M', @ciudad_caba, 'admin', TRUE, NOW()),
('Editor Global', 'editor_test', 'editor@preguntados.com', @hash_test, 1995, 'F', @ciudad_caba, 'editor', TRUE, NOW()),
('Usuario Test', 'user_test', 'user@preguntados.com', @hash_test, 1995, 'F', @ciudad_caba, 'usuario', TRUE, NOW()),
-- Usuarios Menores (<18) - Nacidos en 2007-2024
('Juan García', 'juan_garcia', 'juan@preguntados.com', @hash_test, 2008, 'M', @ciudad_laplata, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 30 DAY)),
('María López', 'maria_lopez', 'maria@preguntados.com', @hash_test, 2010, 'F', @ciudad_cordoba, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 25 DAY)),
('Carlos Rodríguez', 'carlos_r', 'carlos@preguntados.com', @hash_test, 2009, 'M', @ciudad_mendoza, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 20 DAY)),
('Sofia Martinez', 'sofia_m', 'sofia@preguntados.com', @hash_test, 2011, 'F', @ciudad_madrid, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 18 DAY)),
-- Usuarios Adultos (18-64) - Nacidos en 1961-2006
('Diego Sanchez', 'diego_s', 'diego@preguntados.com', @hash_test, 1980, 'M', @ciudad_barcelona, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 15 DAY)),
('Elena García', 'elena_g', 'elena@preguntados.com', @hash_test, 1998, 'F', @ciudad_valencia, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 12 DAY)),
('Fernando López', 'fernando_l', 'fernando@preguntados.com', @hash_test, 1985, 'M', @ciudad_cdmx, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 10 DAY)),
('Patricia Ruiz', 'patricia_r', 'patricia@preguntados.com', @hash_test, 2003, 'F', @ciudad_guadalajara, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 8 DAY)),
('Lucia Fernandez', 'lucia_f', 'lucia@preguntados.com', @hash_test, 2002, 'F', @ciudad_bogota, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 6 DAY)),
('Andrés Moreno', 'andres_m', 'andres@preguntados.com', @hash_test, 1989, 'M', @ciudad_medellin, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 5 DAY)),
('Valentina Torres', 'valentina_t', 'valentina@preguntados.com', @hash_test, 2001, 'F', @ciudad_cali, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY)),
('Miguel Romero', 'miguel_r', 'miguel@preguntados.com', @hash_test, 1987, 'M', @ciudad_losangeles, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 3 DAY)),
('Alejandra Gómez', 'alejandra_g', 'alejandra@preguntados.com', @hash_test, 1999, 'F', @ciudad_sanfrancisco, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 2 DAY)),
('Ricardo Díaz', 'ricardo_d', 'ricardo@preguntados.com', @hash_test, 1982, 'M', @ciudad_houston, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
('Gabriela Costa', 'gabriela_c', 'gabriela@preguntados.com', @hash_test, 1996, 'F', @ciudad_rio, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 11 DAY)),
('Paulo Silva', 'paulo_s', 'paulo@preguntados.com', @hash_test, 1991, 'M', @ciudad_belohorizonte, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 9 DAY)),
('Javier Peña', 'javier_p', 'javier@preguntados.com', @hash_test, 1986, 'M', @ciudad_valparaiso, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 5 DAY)),
('Martina Flores', 'martina_f', 'martina@preguntados.com', @hash_test, 2000, 'F', @ciudad_lima, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 3 DAY)),
-- Usuarios Jubilados (65+) - Nacidos en 1960 o antes
('Isabel Vargas', 'isabel_v', 'isabel@preguntados.com', @hash_test, 1958, 'F', @ciudad_miami, 'usuario', TRUE, NOW()),
('Antonio Jiménez', 'antonio_j', 'antonio@preguntados.com', @hash_test, 1955, 'M', @ciudad_saopaulo, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 14 DAY)),
('Camila Martínez', 'camila_m', 'camila@preguntados.com', @hash_test, 1950, 'F', @ciudad_santiago, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 7 DAY)),
('Roberto Silva', 'roberto_s', 'roberto@preguntados.com', @hash_test, 1952, 'M', @ciudad_monterrey, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 7 DAY)),
('Ernesto García', 'ernesto_g', 'ernesto@preguntados.com', @hash_test, 1948, 'M', @ciudad_madrid, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 6 DAY)),
('Rosa Díaz', 'rosa_d', 'rosa@preguntados.com', @hash_test, 1945, 'F', @ciudad_barcelona, 'usuario', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY));

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
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_geo, '¿Cuál es la capital de Francia?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo1 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo1, 'París', 1), (@preg_geo1, 'Roma', 0), (@preg_geo1, 'Londres', 0), (@preg_geo1, 'Madrid', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_geo, '¿En qué país se encuentra la Torre de Pisa?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo2 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo2, 'Italia', 1), (@preg_geo2, 'Francia', 0), (@preg_geo2, 'España', 0), (@preg_geo2, 'Portugal', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_geo, '¿Cuál es el río más largo del mundo?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo3 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo3, 'Amazonas', 1), (@preg_geo3, 'Nilo', 0), (@preg_geo3, 'Yangtsé', 0), (@preg_geo3, 'Misisipi', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_geo, '¿En qué continente se encuentra el desierto del Sahara?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo4 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo4, 'África', 1), (@preg_geo4, 'Asia', 0), (@preg_geo4, 'Oceanía', 0), (@preg_geo4, 'América del Sur', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_geo, '¿Cuál es el país más grande del mundo por superficie?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo5 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo5, 'Rusia', 1), (@preg_geo5, 'Canadá', 0), (@preg_geo5, 'China', 0), (@preg_geo5, 'Estados Unidos', 0);


INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿Cuál es la montaña más alta del mundo?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo6 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo6, 'Monte Everest', 1), (@preg_geo6, 'K2', 0), (@preg_geo6, 'Aconcagua', 0), (@preg_geo6, 'Kilimanjaro', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿Cuál es el océano más grande del mundo?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo7 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo7, 'Pacífico', 1), (@preg_geo7, 'Atlántico', 0), (@preg_geo7, 'Índico', 0), (@preg_geo7, 'Ártico', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿Cuál es la capital de Australia?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo8 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo8, 'Canberra', 1), (@preg_geo8, 'Sídney', 0), (@preg_geo8, 'Melbourne', 0), (@preg_geo8, 'Brisbane', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿En qué país se encuentra el desierto de Atacama?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo9 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo9, 'Chile', 1), (@preg_geo9, 'Argentina', 0), (@preg_geo9, 'Perú', 0), (@preg_geo9, 'Bolivia', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿Qué estrecho separa Europa de África?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo10 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo10, 'Estrecho de Gibraltar', 1), (@preg_geo10, 'Canal de Suez', 0), (@preg_geo10, 'Estrecho de Bering', 0), (@preg_geo10, 'Canal de la Mancha', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿Cuál es la capital de Japón?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo11 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo11, 'Tokio', 1), (@preg_geo11, 'Kioto', 0), (@preg_geo11, 'Osaka', 0), (@preg_geo11, 'Seúl', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿En qué país se encuentra la Gran Muralla?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo12 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo12, 'China', 1), (@preg_geo12, 'India', 0), (@preg_geo12, 'Mongolia', 0), (@preg_geo12, 'Japón', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿En qué país se encuentra el Gran Cañón?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo13 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo13, 'Estados Unidos', 1), (@preg_geo13, 'Canadá', 0), (@preg_geo13, 'México', 0), (@preg_geo13, 'Brasil', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿Cuál es el lago más grande de África?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo14 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo14, 'Lago Victoria', 1), (@preg_geo14, 'Lago Tanganica', 0), (@preg_geo14, 'Lago Malaui', 0), (@preg_geo14, 'Lago Chad', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_geo, '¿Cuál es el país más grande de Sudamérica?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_geo15 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_geo15, 'Brasil', 1), (@preg_geo15, 'Argentina', 0), (@preg_geo15, 'Perú', 0), (@preg_geo15, 'Colombia', 0);
-- ⚛️ CIENCIA
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Cuál es la fórmula química del agua?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie1 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie1, 'H2O', 1), (@preg_cie1, 'CO2', 0), (@preg_cie1, 'O2', 0), (@preg_cie1, 'NaCl', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué planeta es conocido como el “planeta rojo”?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie2 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie2, 'Marte', 1), (@preg_cie2, 'Venus', 0), (@preg_cie2, 'Mercurio', 0), (@preg_cie2, 'Júpiter', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Cuál es el órgano más grande del cuerpo humano?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie3 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie3, 'La piel', 1), (@preg_cie3, 'El hígado', 0), (@preg_cie3, 'El cerebro', 0), (@preg_cie3, 'El corazón', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Cuál es el planeta más grande del Sistema Solar?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie4 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie4, 'Júpiter', 1), (@preg_cie4, 'Saturno', 0), (@preg_cie4, 'Urano', 0), (@preg_cie4, 'Neptuno', 0);
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Quién propuso la teoría de la relatividad?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie5 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie5, 'Albert Einstein', 1), (@preg_cie5, 'Isaac Newton', 0), (@preg_cie5, 'Stephen Hawking', 0), (@preg_cie5, 'Galileo Galilei', 0);
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué partícula subatómica tiene carga negativa?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie6 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie6, 'Electrón', 1), (@preg_cie6, 'Protón', 0), (@preg_cie6, 'Neutrón', 0), (@preg_cie6, 'Positrón', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué gas necesitan las plantas para realizar la fotosíntesis?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie7 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie7, 'Dióxido de carbono', 1), (@preg_cie7, 'Oxígeno', 0), (@preg_cie7, 'Nitrógeno', 0), (@preg_cie7, 'Hidrógeno', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué unidad se utiliza para medir la intensidad de la corriente eléctrica?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie8 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie8, 'Amperio', 1), (@preg_cie8, 'Voltio', 0), (@preg_cie8, 'Ohmio', 0), (@preg_cie8, 'Watt', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué científico formuló las leyes del movimiento y la gravedad?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie9 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie9, 'Isaac Newton', 1), (@preg_cie9, 'Galileo Galilei', 0), (@preg_cie9, 'Albert Einstein', 0), (@preg_cie9, 'Nicolás Copérnico', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué elemento químico tiene el símbolo “Fe”?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie10 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie10, 'Hierro', 1), (@preg_cie10, 'Flúor', 0), (@preg_cie10, 'Francio', 0), (@preg_cie10, 'Fósforo', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué órgano del cuerpo humano bombea la sangre?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie11 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie11, 'El corazón', 1), (@preg_cie11, 'El pulmón', 0), (@preg_cie11, 'El riñón', 0), (@preg_cie11, 'El hígado', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué instrumento mide la presión atmosférica?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie12 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie12, 'Barómetro', 1), (@preg_cie12, 'Termómetro', 0), (@preg_cie12, 'Anemómetro', 0), (@preg_cie12, 'Higrómetro', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué tipo de célula no tiene núcleo definido?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie13 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie13, 'Procariota', 1), (@preg_cie13, 'Eucariota', 0), (@preg_cie13, 'Somática', 0), (@preg_cie13, 'Neurona', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué órgano del sistema nervioso controla las funciones del cuerpo?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie14 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie14, 'El cerebro', 1), (@preg_cie14, 'El corazón', 0), (@preg_cie14, 'El páncreas', 0), (@preg_cie14, 'El intestino', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Cuál es el metal más ligero?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie15 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie15, 'Litio', 1), (@preg_cie15, 'Aluminio', 0), (@preg_cie15, 'Sodio', 0), (@preg_cie15, 'Magnesio', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_cie, '¿Qué científico descubrió la penicilina?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_cie16 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_cie16, 'Alexander Fleming', 1), (@preg_cie16, 'Louis Pasteur', 0), (@preg_cie16, 'Marie Curie', 0), (@preg_cie16, 'Charles Darwin', 0);
-- 🏰 HISTORIA
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_his, '¿En qué año cayó el Muro de Berlín?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his1 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his1, '1989', 1), (@preg_his1, '1979', 0), (@preg_his1, '1991', 0), (@preg_his1, '1993', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_his, '¿Quién fue el primer emperador del Imperio Romano?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his2 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his2, 'Augusto', 1), (@preg_his2, 'Julio César', 0), (@preg_his2, 'Nerón', 0), (@preg_his2, 'Tiberio', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_his, '¿Qué civilización construyó las pirámides de Egipto?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his3 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his3, 'Los egipcios', 1), (@preg_his3, 'Los mayas', 0), (@preg_his3, 'Los romanos', 0), (@preg_his3, 'Los griegos', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_his, '¿Quién fue Cristóbal Colón?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his4 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his4, 'El navegante que descubrió América', 1), (@preg_his4, 'Un emperador romano', 0), (@preg_his4, 'Un científico italiano', 0), (@preg_his4, 'Un rey español', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_his, '¿Qué país inició la Primera Guerra Mundial?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his5 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his5, 'Alemania', 1), (@preg_his5, 'Inglaterra', 0), (@preg_his5, 'Francia', 0), (@preg_his5, 'Italia', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿Quién pintó la "Mona Lisa"?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his6 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his6, 'Leonardo da Vinci', 1), (@preg_his6, 'Michelangelo', 0), (@preg_his6, 'Raphael', 0), (@preg_his6, 'Donatello', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿Qué evento desencadenó la Primera Guerra Mundial?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his7 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his7, 'El asesinato del archiduque Francisco Fernando', 1), (@preg_his7, 'La invasión de Polonia', 0), (@preg_his7, 'El hundimiento del Lusitania', 0), (@preg_his7, 'La Revolución Francesa', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿En qué año llegó Cristóbal Colón a América por primera vez?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his8 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his8, '1492', 1), (@preg_his8, '1776', 0), (@preg_his8, '1588', 0), (@preg_his8, '1453', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿Quién fue la primera persona en caminar sobre la Luna?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his9 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his9, 'Neil Armstrong', 1), (@preg_his9, 'Buzz Aldrin', 0), (@preg_his9, 'Yuri Gagarin', 0), (@preg_his9, 'Michael Collins', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿Qué imperio antiguo era gobernado por Faraones?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his10 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his10, 'Egipto', 1), (@preg_his10, 'Roma', 0), (@preg_his10, 'Persia', 0), (@preg_his10, 'Grecia', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿Qué fue la "Carta Magna"?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his11 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his11, 'Una carta real de derechos en Inglaterra', 1), (@preg_his11, 'Una pintura famosa', 0), (@preg_his11, 'Una declaración de guerra', 0), (@preg_his11, 'Un poema épico', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿Quién lideró la Unión Soviética durante la Segunda Guerra Mundial?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his12 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his12, 'Joseph Stalin', 1), (@preg_his12, 'Vladimir Lenin', 0), (@preg_his12, 'Mikhail Gorbachev', 0), (@preg_his12, 'Nikita Khrushchev', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿Qué batalla marcó el fin del reinado de Napoleón Bonaparte?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his13 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his13, 'La Batalla de Waterloo', 1), (@preg_his13, 'La Batalla de Trafalgar', 0), (@preg_his13, 'La Batalla de Austerlitz', 0), (@preg_his13, 'La Batalla de Hastings', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿Quién escribió "El Manifiesto Comunista"?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his14 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his14, 'Karl Marx y Friedrich Engels', 1), (@preg_his14, 'Adam Smith', 0), (@preg_his14, 'Vladimir Lenin', 0), (@preg_his14, 'John Locke', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES (@cat_his, '¿Qué civilización construyó Machu Picchu?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_his15 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_his15, 'Los Incas', 1), (@preg_his15, 'Los Aztecas', 0), (@preg_his15, 'Los Mayas', 0), (@preg_his15, 'Los Egipcios', 0);
-- 🎬 CULTURA POP / ENTRETENIMIENTO
INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué actor interpreta a Iron Man en el Universo Cinematográfico de Marvel?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop1 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop1, 'Robert Downey Jr.', 1), (@preg_pop1, 'Chris Evans', 0), (@preg_pop1, 'Chris Hemsworth', 0), (@preg_pop1, 'Mark Ruffalo', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué serie popular de Netflix está ambientada en Hawkins?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop2 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop2, 'Stranger Things', 1), (@preg_pop2, 'The Umbrella Academy', 0), (@preg_pop2, 'Dark', 0), (@preg_pop2, 'The OA', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Quién es el protagonista de "Harry Potter"?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop3 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop3, 'Harry Potter', 1), (@preg_pop3, 'Ron Weasley', 0), (@preg_pop3, 'Voldemort', 0), (@preg_pop3, 'Dumbledore', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿De qué banda era Freddie Mercury el vocalista?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop4 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop4, 'Queen', 1), (@preg_pop4, 'The Beatles', 0), (@preg_pop4, 'U2', 0), (@preg_pop4, 'Coldplay', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué empresa creó la consola PlayStation?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop5 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop5, 'Sony', 1), (@preg_pop5, 'Microsoft', 0), (@preg_pop5, 'Nintendo', 0), (@preg_pop5, 'Sega', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué película ganó el Óscar a Mejor Película en 1997?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop6 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop6, 'Titanic', 1), (@preg_pop6, 'Gladiador', 0), (@preg_pop6, 'Braveheart', 0), (@preg_pop6, 'Forrest Gump', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué cantante es conocido como "El Rey del Pop"?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop7 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop7, 'Michael Jackson', 1), (@preg_pop7, 'Prince', 0), (@preg_pop7, 'Elvis Presley', 0), (@preg_pop7, 'Justin Timberlake', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿En qué año se estrenó la primera película de Star Wars?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop8 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop8, '1977', 1), (@preg_pop8, '1980', 0), (@preg_pop8, '1975', 0), (@preg_pop8, '1983', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Cuál es el nombre del superhéroe alter ego de Bruce Wayne?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop9 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop9, 'Batman', 1), (@preg_pop9, 'Superman', 0), (@preg_pop9, 'Iron Man', 0), (@preg_pop9, 'Spider-Man', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué serie de televisión presenta un trono hecho de espadas?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop10 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop10, 'Game of Thrones', 1), (@preg_pop10, 'Vikings', 0), (@preg_pop10, 'The Witcher', 0), (@preg_pop10, 'The Crown', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué famoso videojuego incluye personajes como Mario, Luigi y Bowser?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop11 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop11, 'Super Mario Bros', 1), (@preg_pop11, 'Donkey Kong', 0), (@preg_pop11, 'Sonic the Hedgehog', 0), (@preg_pop11, 'Zelda', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué artista lanzó el álbum "1989"?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop12 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop12, 'Taylor Swift', 1), (@preg_pop12, 'Adele', 0), (@preg_pop12, 'Katy Perry', 0), (@preg_pop12, 'Billie Eilish', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿En qué ciudad vive la familia Simpson?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop13 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop13, 'Springfield', 1), (@preg_pop13, 'Shelbyville', 0), (@preg_pop13, 'Quahog', 0), (@preg_pop13, 'South Park', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué película presenta al personaje Jack Sparrow?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop14 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop14, 'Piratas del Caribe', 1), (@preg_pop14, 'El Señor de los Anillos', 0), (@preg_pop14, 'Avatar', 0), (@preg_pop14, 'Indiana Jones', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Qué banda compuso el álbum "Abbey Road"?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop15 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop15, 'The Beatles', 1), (@preg_pop15, 'The Rolling Stones', 0), (@preg_pop15, 'Pink Floyd', 0), (@preg_pop15, 'Led Zeppelin', 0);

INSERT INTO preguntas (categoria_id, texto_pregunta, estado, creada_por_usuario_id, aprobado_por_usuario_id, fecha_creacion)
VALUES
    (@cat_pop, '¿Quién interpretó a "El Joker" en la película de 2019?', 'activa', @admin_id, @admin_id, NOW());
SET @preg_pop16 = LAST_INSERT_ID();
INSERT INTO respuestas (pregunta_id, texto_respuesta, es_correcta) VALUES
                                                                       (@preg_pop16, 'Joaquin Phoenix', 1), (@preg_pop16, 'Heath Ledger', 0), (@preg_pop16, 'Jared Leto', 0), (@preg_pop16, 'Jack Nicholson', 0);

-- ========================================
-- 10. PARTIDAS Y RESPUESTAS DE USUARIOS (DATOS PARA GRÁFICOS)
-- ========================================

-- Usuarios para las partidas
SET @usuario1 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'juan_garcia');
SET @usuario2 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'maria_lopez');
SET @usuario3 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'carlos_r');
SET @usuario4 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'sofia_m');
SET @usuario5 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'diego_s');
SET @usuario6 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'elena_g');
SET @usuario7 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'fernando_l');
SET @usuario8 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'patricia_r');
SET @usuario9 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'roberto_s');
SET @usuario10 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'lucia_f');
SET @usuario11 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'andres_m');
SET @usuario12 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'valentina_t');
SET @usuario13 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'miguel_r');
SET @usuario14 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'alejandra_g');
SET @usuario15 = (SELECT usuario_id FROM usuarios WHERE nombre_usuario = 'ricardo_d');

-- Partidas de hoy
INSERT INTO partidas_usuario (usuario_id, puntaje, estado, fecha_inicio, fecha_fin) VALUES
(@usuario1, 8, 'finalizada', NOW(), DATE_ADD(NOW(), INTERVAL 5 MINUTE)),
(@usuario2, 6, 'finalizada', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 115 MINUTE)),
(@usuario3, 9, 'finalizada', DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 235 MINUTE)),
(@usuario4, 7, 'finalizada', DATE_SUB(NOW(), INTERVAL 6 HOUR), DATE_SUB(NOW(), INTERVAL 355 MINUTE)),
(@usuario5, 5, 'finalizada', DATE_SUB(NOW(), INTERVAL 8 HOUR), DATE_SUB(NOW(), INTERVAL 475 MINUTE));

SET @partida1 = CAST(LAST_INSERT_ID() AS SIGNED) - 4;
SET @partida2 = CAST(LAST_INSERT_ID() AS SIGNED) - 3;
SET @partida3 = CAST(LAST_INSERT_ID() AS SIGNED) - 2;
SET @partida4 = CAST(LAST_INSERT_ID() AS SIGNED) - 1;
SET @partida5 = CAST(LAST_INSERT_ID() AS SIGNED);

-- Partidas de ayer
INSERT INTO partidas_usuario (usuario_id, puntaje, estado, fecha_inicio, fecha_fin) VALUES
(@usuario6, 8, 'finalizada', DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1435 MINUTE)),
(@usuario7, 9, 'finalizada', DATE_SUB(NOW(), INTERVAL 1415 MINUTE), DATE_SUB(NOW(), INTERVAL 1295 MINUTE)),
(@usuario8, 7, 'finalizada', DATE_SUB(NOW(), INTERVAL 1255 MINUTE), DATE_SUB(NOW(), INTERVAL 1135 MINUTE)),
(@usuario9, 6, 'finalizada', DATE_SUB(NOW(), INTERVAL 1095 MINUTE), DATE_SUB(NOW(), INTERVAL 975 MINUTE)),
(@usuario10, 8, 'finalizada', DATE_SUB(NOW(), INTERVAL 935 MINUTE), DATE_SUB(NOW(), INTERVAL 815 MINUTE));

SET @partida6 = CAST(LAST_INSERT_ID() AS SIGNED) - 4;
SET @partida7 = CAST(LAST_INSERT_ID() AS SIGNED) - 3;
SET @partida8 = CAST(LAST_INSERT_ID() AS SIGNED) - 2;
SET @partida9 = CAST(LAST_INSERT_ID() AS SIGNED) - 1;
SET @partida10 = CAST(LAST_INSERT_ID() AS SIGNED);

-- Partidas hace 3 días
INSERT INTO partidas_usuario (usuario_id, puntaje, estado, fecha_inicio, fecha_fin) VALUES
(@usuario11, 5, 'finalizada', DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 4315 MINUTE)),
(@usuario12, 9, 'finalizada', DATE_SUB(NOW(), INTERVAL 4295 MINUTE), DATE_SUB(NOW(), INTERVAL 4175 MINUTE)),
(@usuario13, 7, 'finalizada', DATE_SUB(NOW(), INTERVAL 4135 MINUTE), DATE_SUB(NOW(), INTERVAL 4015 MINUTE)),
(@usuario14, 8, 'finalizada', DATE_SUB(NOW(), INTERVAL 3975 MINUTE), DATE_SUB(NOW(), INTERVAL 3855 MINUTE)),
(@usuario15, 6, 'finalizada', DATE_SUB(NOW(), INTERVAL 3815 MINUTE), DATE_SUB(NOW(), INTERVAL 3695 MINUTE));

SET @partida11 = CAST(LAST_INSERT_ID() AS SIGNED) - 4;
SET @partida12 = CAST(LAST_INSERT_ID() AS SIGNED) - 3;
SET @partida13 = CAST(LAST_INSERT_ID() AS SIGNED) - 2;
SET @partida14 = CAST(LAST_INSERT_ID() AS SIGNED) - 1;
SET @partida15 = CAST(LAST_INSERT_ID() AS SIGNED);

-- Partidas hace 7 días (última semana)
INSERT INTO partidas_usuario (usuario_id, puntaje, estado, fecha_inicio, fecha_fin) VALUES
(@usuario1, 9, 'finalizada', DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 10075 MINUTE)),
(@usuario2, 7, 'finalizada', DATE_SUB(NOW(), INTERVAL 10055 MINUTE), DATE_SUB(NOW(), INTERVAL 9935 MINUTE)),
(@usuario3, 10, 'finalizada', DATE_SUB(NOW(), INTERVAL 9935 MINUTE), DATE_SUB(NOW(), INTERVAL 9815 MINUTE)),
(@usuario4, 6, 'finalizada', DATE_SUB(NOW(), INTERVAL 9815 MINUTE), DATE_SUB(NOW(), INTERVAL 9695 MINUTE)),
(@usuario5, 8, 'finalizada', DATE_SUB(NOW(), INTERVAL 9695 MINUTE), DATE_SUB(NOW(), INTERVAL 9575 MINUTE));

SET @partida16 = CAST(LAST_INSERT_ID() AS SIGNED) - 4;
SET @partida17 = CAST(LAST_INSERT_ID() AS SIGNED) - 3;
SET @partida18 = CAST(LAST_INSERT_ID() AS SIGNED) - 2;
SET @partida19 = CAST(LAST_INSERT_ID() AS SIGNED) - 1;
SET @partida20 = CAST(LAST_INSERT_ID() AS SIGNED);

-- Partidas hace 14 días (2 semanas)
INSERT INTO partidas_usuario (usuario_id, puntaje, estado, fecha_inicio, fecha_fin) VALUES
(@usuario6, 8, 'finalizada', DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 20155 MINUTE)),
(@usuario7, 9, 'finalizada', DATE_SUB(NOW(), INTERVAL 20135 MINUTE), DATE_SUB(NOW(), INTERVAL 20015 MINUTE)),
(@usuario8, 6, 'finalizada', DATE_SUB(NOW(), INTERVAL 20015 MINUTE), DATE_SUB(NOW(), INTERVAL 19895 MINUTE)),
(@usuario9, 7, 'finalizada', DATE_SUB(NOW(), INTERVAL 19895 MINUTE), DATE_SUB(NOW(), INTERVAL 19775 MINUTE)),
(@usuario10, 9, 'finalizada', DATE_SUB(NOW(), INTERVAL 19775 MINUTE), DATE_SUB(NOW(), INTERVAL 19655 MINUTE));

SET @partida21 = CAST(LAST_INSERT_ID() AS SIGNED) - 4;
SET @partida22 = CAST(LAST_INSERT_ID() AS SIGNED) - 3;
SET @partida23 = CAST(LAST_INSERT_ID() AS SIGNED) - 2;
SET @partida24 = CAST(LAST_INSERT_ID() AS SIGNED) - 1;
SET @partida25 = CAST(LAST_INSERT_ID() AS SIGNED);

-- Partidas hace 21 días
INSERT INTO partidas_usuario (usuario_id, puntaje, estado, fecha_inicio, fecha_fin) VALUES
(@usuario11, 7, 'finalizada', DATE_SUB(NOW(), INTERVAL 21 DAY), DATE_SUB(NOW(), INTERVAL 30235 MINUTE)),
(@usuario12, 9, 'finalizada', DATE_SUB(NOW(), INTERVAL 30215 MINUTE), DATE_SUB(NOW(), INTERVAL 30095 MINUTE)),
(@usuario13, 7, 'finalizada', DATE_SUB(NOW(), INTERVAL 30095 MINUTE), DATE_SUB(NOW(), INTERVAL 29975 MINUTE)),
(@usuario14, 8, 'finalizada', DATE_SUB(NOW(), INTERVAL 29975 MINUTE), DATE_SUB(NOW(), INTERVAL 29855 MINUTE)),
(@usuario15, 6, 'finalizada', DATE_SUB(NOW(), INTERVAL 29855 MINUTE), DATE_SUB(NOW(), INTERVAL 29735 MINUTE));

SET @partida26 = CAST(LAST_INSERT_ID() AS SIGNED) - 4;
SET @partida27 = CAST(LAST_INSERT_ID() AS SIGNED) - 3;
SET @partida28 = CAST(LAST_INSERT_ID() AS SIGNED) - 2;
SET @partida29 = CAST(LAST_INSERT_ID() AS SIGNED) - 1;
SET @partida30 = CAST(LAST_INSERT_ID() AS SIGNED);

-- Partidas hace 30 días (hace un mes)
INSERT INTO partidas_usuario (usuario_id, puntaje, estado, fecha_inicio, fecha_fin) VALUES
(@usuario1, 7, 'finalizada', DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 43315 MINUTE)),
(@usuario2, 8, 'finalizada', DATE_SUB(NOW(), INTERVAL 43295 MINUTE), DATE_SUB(NOW(), INTERVAL 43175 MINUTE)),
(@usuario3, 7, 'finalizada', DATE_SUB(NOW(), INTERVAL 43175 MINUTE), DATE_SUB(NOW(), INTERVAL 43055 MINUTE));

SET @partida31 = CAST(LAST_INSERT_ID() AS SIGNED) - 2;
SET @partida32 = CAST(LAST_INSERT_ID() AS SIGNED) - 1;
SET @partida33 = CAST(LAST_INSERT_ID() AS SIGNED);

-- ========================================
-- 10B. RESPUESTAS DE USUARIOS (Inserts sistemáticos)
-- ========================================

-- Obtener IDs reales de partidas por rango
SET @min_partida_hoy = (SELECT MIN(partida_id) FROM partidas_usuario WHERE usuario_id = @usuario1 AND estado = 'finalizada' LIMIT 1);
SET @max_partida_mes = (SELECT MAX(partida_id) FROM partidas_usuario);

-- Obtener respuestas para las preguntas
SET @resp_geo1_correct = (SELECT respuesta_id FROM respuestas WHERE pregunta_id = (SELECT pregunta_id FROM preguntas WHERE texto_pregunta LIKE '%capital de Francia%') AND es_correcta = 1);
SET @resp_cie1_correct = (SELECT respuesta_id FROM respuestas WHERE pregunta_id = (SELECT pregunta_id FROM preguntas WHERE texto_pregunta LIKE '%fórmula química del agua%') AND es_correcta = 1);
SET @resp_his1_correct = (SELECT respuesta_id FROM respuestas WHERE pregunta_id = (SELECT pregunta_id FROM preguntas WHERE texto_pregunta LIKE '%archiduque Francisco%') AND es_correcta = 1);
SET @resp_pop1_correct = (SELECT respuesta_id FROM respuestas WHERE pregunta_id = (SELECT pregunta_id FROM preguntas WHERE texto_pregunta LIKE '%Iron Man%') AND es_correcta = 1);
SET @resp_geo2_correct = (SELECT respuesta_id FROM respuestas WHERE pregunta_id = (SELECT pregunta_id FROM preguntas WHERE texto_pregunta LIKE '%Torre de Pisa%') AND es_correcta = 1);

-- Insertar respuestas de usuarios usando SELECT directo para obtener IDs correctos
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, NOW(), DATE_SUB(NOW(), INTERVAL 1 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 8
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_ADD(NOW(), INTERVAL 1 MINUTE), DATE_SUB(NOW(), INTERVAL 2 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 8
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_ADD(NOW(), INTERVAL 2 MINUTE), DATE_SUB(NOW(), INTERVAL 3 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 8
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_ADD(NOW(), INTERVAL 3 MINUTE), DATE_SUB(NOW(), INTERVAL 4 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 8
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_ADD(NOW(), INTERVAL 4 MINUTE), DATE_SUB(NOW(), INTERVAL 5 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 8
LIMIT 1;

-- Respuestas para usuario2 (60% accuracy)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 120 MINUTE), DATE_SUB(NOW(), INTERVAL 119 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 6
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 119 MINUTE), DATE_SUB(NOW(), INTERVAL 118 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 6
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 118 MINUTE), DATE_SUB(NOW(), INTERVAL 117 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 6
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 117 MINUTE), DATE_SUB(NOW(), INTERVAL 116 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 6
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 116 MINUTE), DATE_SUB(NOW(), INTERVAL 115 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 6
LIMIT 1;

-- Respuestas para usuario3 (90% accuracy)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 240 MINUTE), DATE_SUB(NOW(), INTERVAL 239 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 239 MINUTE), DATE_SUB(NOW(), INTERVAL 238 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 238 MINUTE), DATE_SUB(NOW(), INTERVAL 237 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 237 MINUTE), DATE_SUB(NOW(), INTERVAL 236 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 236 MINUTE), DATE_SUB(NOW(), INTERVAL 235 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

-- Respuestas para usuario4 (70% accuracy)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 360 MINUTE), DATE_SUB(NOW(), INTERVAL 359 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 359 MINUTE), DATE_SUB(NOW(), INTERVAL 358 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 358 MINUTE), DATE_SUB(NOW(), INTERVAL 357 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 357 MINUTE), DATE_SUB(NOW(), INTERVAL 356 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 356 MINUTE), DATE_SUB(NOW(), INTERVAL 355 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

-- Respuestas para usuario5 (50% accuracy)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario5, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 480 MINUTE), DATE_SUB(NOW(), INTERVAL 479 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario5 AND pu.puntaje = 5
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario5, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 479 MINUTE), DATE_SUB(NOW(), INTERVAL 478 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario5 AND pu.puntaje = 5
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario5, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 478 MINUTE), DATE_SUB(NOW(), INTERVAL 477 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario5 AND pu.puntaje = 5
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario5, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 477 MINUTE), DATE_SUB(NOW(), INTERVAL 476 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario5 AND pu.puntaje = 5
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario5, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 476 MINUTE), DATE_SUB(NOW(), INTERVAL 475 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario5 AND pu.puntaje = 5
LIMIT 1;

-- Respuestas adicionales para demostrar cambios con el filtro de período
-- Usuario 1 de 7 días: 100% accuracy (all correct)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10080 MINUTE), DATE_SUB(NOW(), INTERVAL 10079 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10078 MINUTE), DATE_SUB(NOW(), INTERVAL 10077 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10076 MINUTE), DATE_SUB(NOW(), INTERVAL 10075 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10074 MINUTE), DATE_SUB(NOW(), INTERVAL 10073 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario1, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10072 MINUTE), DATE_SUB(NOW(), INTERVAL 10071 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario1 AND pu.puntaje = 9
LIMIT 1;

-- Usuario 2 de 7 días: 40% accuracy (2 correct, 3 incorrect)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 10070 MINUTE), DATE_SUB(NOW(), INTERVAL 10069 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10068 MINUTE), DATE_SUB(NOW(), INTERVAL 10067 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 10066 MINUTE), DATE_SUB(NOW(), INTERVAL 10065 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10064 MINUTE), DATE_SUB(NOW(), INTERVAL 10063 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario2, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 10062 MINUTE), DATE_SUB(NOW(), INTERVAL 10061 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario2 AND pu.puntaje = 7
LIMIT 1;

-- Agregar más respuestas para variar más los resultados según el filtro
-- Usuario 3: Hoy 100%, 7 días: 20% (GRAN DIFERENCIA)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, NOW(), DATE_SUB(NOW(), INTERVAL 1 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, NOW(), DATE_SUB(NOW(), INTERVAL 2 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, NOW(), DATE_SUB(NOW(), INTERVAL 3 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, NOW(), DATE_SUB(NOW(), INTERVAL 4 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, NOW(), DATE_SUB(NOW(), INTERVAL 5 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 9
LIMIT 1;

-- Usuario 3 hace 7 días: Solo 1 correcto de 5 (20%)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 10060 MINUTE), DATE_SUB(NOW(), INTERVAL 10059 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 10
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 10058 MINUTE), DATE_SUB(NOW(), INTERVAL 10057 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 10
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10056 MINUTE), DATE_SUB(NOW(), INTERVAL 10055 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 10
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 10054 MINUTE), DATE_SUB(NOW(), INTERVAL 10053 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 10
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario3, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, DATE_SUB(NOW(), INTERVAL 10052 MINUTE), DATE_SUB(NOW(), INTERVAL 10051 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario3 AND pu.puntaje = 10
LIMIT 1;

-- Usuario 4: Hoy 40%, 7 días: 100% (INVERSO TOTAL)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, NOW(), DATE_SUB(NOW(), INTERVAL 10 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, NOW(), DATE_SUB(NOW(), INTERVAL 11 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, NOW(), DATE_SUB(NOW(), INTERVAL 12 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, NOW(), DATE_SUB(NOW(), INTERVAL 13 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 0, NOW(), DATE_SUB(NOW(), INTERVAL 14 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 0
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 7
LIMIT 1;

-- Usuario 4 hace 7 días: Todos correctos (100%)
INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10050 MINUTE), DATE_SUB(NOW(), INTERVAL 10049 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%capital de Francia%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 6
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10048 MINUTE), DATE_SUB(NOW(), INTERVAL 10047 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%fórmula química del agua%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 6
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10046 MINUTE), DATE_SUB(NOW(), INTERVAL 10045 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%archiduque Francisco%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 6
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10044 MINUTE), DATE_SUB(NOW(), INTERVAL 10043 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Iron Man%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 6
LIMIT 1;

INSERT INTO respuestas_usuario (usuario_id, partida_id, pregunta_id, respuesta_id, fue_correcta, fecha_respuesta, tiempo_inicio_pregunta)
SELECT @usuario4, pu.partida_id, p.pregunta_id, r.respuesta_id, 1, DATE_SUB(NOW(), INTERVAL 10042 MINUTE), DATE_SUB(NOW(), INTERVAL 10041 MINUTE)
FROM partidas_usuario pu
JOIN preguntas p ON p.texto_pregunta LIKE '%Torre de Pisa%'
JOIN respuestas r ON r.pregunta_id = p.pregunta_id AND r.es_correcta = 1
WHERE pu.usuario_id = @usuario4 AND pu.puntaje = 6
LIMIT 1;

-- ========================================
-- 11. ACTUALIZAR RANKINGS DE USUARIOS
-- ========================================
-- Basado en MAPA_PUNTUACION:
-- 0-5 correct = puntos negativos, 6-10 correct = puntos positivos
-- puntaje está en escala 0-10 (número de respuestas correctas)

UPDATE usuarios u SET ranking = 100 + (
    SELECT COALESCE(SUM(
        CASE
            WHEN pu.puntaje = 0 THEN -15
            WHEN pu.puntaje = 1 THEN -10
            WHEN pu.puntaje = 2 THEN -10
            WHEN pu.puntaje = 3 THEN -5
            WHEN pu.puntaje = 4 THEN -5
            WHEN pu.puntaje = 5 THEN -5
            WHEN pu.puntaje = 6 THEN 5
            WHEN pu.puntaje = 7 THEN 5
            WHEN pu.puntaje = 8 THEN 5
            WHEN pu.puntaje = 9 THEN 10
            WHEN pu.puntaje = 10 THEN 15
            ELSE 0
        END
    ), 0)
    FROM partidas_usuario pu
    WHERE pu.usuario_id = u.usuario_id AND pu.estado IN ('finalizada', 'perdida')
)
WHERE u.usuario_id IN (SELECT DISTINCT usuario_id FROM partidas_usuario);

