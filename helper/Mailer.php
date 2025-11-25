<?php

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

class Mailer {

    private static $smtp_host = 'smtp.gmail.com';
    private static $smtp_user = 'marcofolco@gmail.com';
    private static $smtp_pass = 'qyqn pbgx vbob bqct';
    private static $from_name = 'Preguntados PGW2'; 

    public static function enviar(string $destino, string $asunto, string $cuerpoHTML): bool {

        $mail = new PHPMailer(true);

        try {
            $mail->isSMTP();
            $mail->Host       = self::$smtp_host;
            $mail->SMTPAuth   = true;
            $mail->Username   = self::$smtp_user;
            $mail->Password   = self::$smtp_pass;
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
            $mail->Port       = 465;
            $mail->CharSet    = 'UTF-8';

            $mail->setFrom(self::$smtp_user, self::$from_name);
            $mail->addAddress($destino);

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