<?php

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

class Mailer {

    // Configuración del Servidor SMTP
    private static $smtp_host = 'smtp.gmail.com';
    private static $smtp_user = 'marcofolco28@gmail.com';
    private static $smtp_pass = 'ripo fsml wrfp mysd';
    private static $from_name = 'Preguntados PGW2'; 

    public static function enviar(string $destino, string $asunto, string $cuerpoHTML): bool {

        $mail = new PHPMailer(true);

        try {
            // Configuración del Servidor
            $mail->isSMTP();
            $mail->Host       = self::$smtp_host;
            $mail->SMTPAuth   = true;
            $mail->Username   = self::$smtp_user;
            $mail->Password   = self::$smtp_pass;
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
            $mail->Port       = 465;
            $mail->CharSet    = 'UTF-8';

            // Remitente y Destinatario
            $mail->setFrom(self::$smtp_user, self::$from_name);
            $mail->addAddress($destino); // El email del nuevo usuario

            // Contenido del Email
            $mail->isHTML(true);
            $mail->Subject = $asunto;
            $mail->Body    = $cuerpoHTML;

            $mail->send();
            return true;

        } catch (Exception $e) {
            error_log("Fallo el envio del mail a {$destino}. Error: {$mail->ErrorInfo}");
            return false;
        }
    }
}