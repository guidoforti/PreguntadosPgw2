<?php

class RegistroController
{
    private $model;
    private $render;


    public function __construct($model, $render)
    {
        $this->model = $model;
        $this->render = $render;
    }


    public function base()
    {
      $this->registrarForm();
    }


    public function registrarForm()
    {
        if (isset($_SESSION["usuario"])) {
            $this->redirectToIndex();
            return;
        }

        $data = [
            'exito' => null,
            'error' => null,
            'anioActual' => date('Y')
        ];

        $this->render->render("registrar", $data);
    }

    public function registrar()
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $data = [
                "error" => "Método no permitido.",
                "exito" => null,
                "anioActual" => date('Y')
            ];
            $this->render->render("registrar", $data);
            return;
        }

        // Capturar todos los datos del formulario
        $nombreCompleto   = $_POST['nombreCompleto'] ?? null;
        $anioNacimiento   = $_POST['anioNacimiento'] ?? null;
        $sexo             = $_POST['sexo'] ?? null;
        $email            = $_POST['email'] ?? null;
        $nombreUsuario    = $_POST['nombreUsuario'] ?? null;
        $contraseniaUno   = $_POST['password'] ?? null;
        $contraseniaDos   = $_POST['confirmPassword'] ?? null;
        $imagen           = $_FILES['fotoPerfil'] ?? null;
        $paisNombre       = $_POST['paisNombre'] ?? null;
        $provinciaNombre  = $_POST['provinciaNombre'] ?? null;
        $ciudadNombre     = $_POST['ciudadNombre'] ?? null;

        // Validar campos vacíos antes de pasar al modelo
        $campos = compact('nombreCompleto', 'anioNacimiento', 'sexo', 'email', 'nombreUsuario', 'contraseniaUno', 'contraseniaDos');
        foreach ($campos as $clave => $valor) {
            if (empty($valor)) {
                $data = [
                    "error" => "El campo '$clave' es obligatorio.",
                    "exito" => null,
                    "anioActual" => date('Y')
                ];
                $this->render->render("registrar", $data);
                return;
            }
        }

        // Llamar al modelo para registrar
        $resultado = $this->model->registrar(
            $nombreCompleto,
            $anioNacimiento,
            $sexo,
            $email,
            $nombreUsuario,
            $contraseniaUno,
            $contraseniaDos,
            $imagen,
            $paisNombre,
            $provinciaNombre,
            $ciudadNombre
        );


        if (isset($resultado['error'])) {

            $data = [
                "error" => $resultado['error'],
                "exito" => null,
                "anioActual" => date('Y')
            ];
            $this->render->render("registrar", $data);

        } elseif (isset($resultado['token'])) {

            // 3. ÉXITO: Envío del Email
            $token = $resultado['token'];
            $emailDestino = $email;

            $protocolo = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $urlBase = $protocolo . "://" . $_SERVER['HTTP_HOST'] . "/";
            $linkActivacion = $urlBase . "registro/validar?token=" . $token;

            $asunto = "Activa tu cuenta de Preguntados PGW2";
            $cuerpoHTML = "Para activar tu cuenta, copia y pegá este link en tu navegador: $linkActivacion";

            if (Mailer::enviar($emailDestino, $asunto, $cuerpoHTML)) {
                $this->render->render("login", ["exito" => "Registro exitoso. Revisa tu email para activar tu cuenta."]);
            } else {
                $this->render->render("login", ["error" => "Registro exitoso, pero falló el envío del email de verificación."]);
            }

        }
        else {

            $data = [
                "error" => "Error desconocido al registrar el usuario.",
                "exito" => null,
                "anioActual" => date('Y')
            ];
            $this->render->render("registrar", $data);
        }
    }

    public function redirectToIndex()
    {
        header("Location: /");
        exit;
    }

    public function validar()
    {
        $token = $_GET['token'] ?? null;

        if (!$token) {
            header("Location: /login/loginForm?error=token_invalido");
            exit;
        }

        // El modelo busca el token y actualiza 'esta_verificado = 1'
        if ($this->model->validarCuenta($token)) {
            header("Location: /login/loginForm?exito=cuenta_activada");
        } else {
            // Token no encontrado o ya utilizado
            header("Location: /login/loginForm?error=token_expirado_o_invalido");
        }
        exit;
    }

}