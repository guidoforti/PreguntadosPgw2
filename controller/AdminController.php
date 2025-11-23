<?php

use Dompdf\Dompdf;
use Dompdf\Options;

class AdminController
{
    private $model;
    private $renderer;

    public function __construct($model, $renderer)
    {
        $this->model = $model;
        $this->renderer = $renderer;
    }

    /**
     * Página principal del dashboard de administración
     */
    public function base()
    {
        // Verificar que el usuario es administrador
        SecurityHelper::checkRole(['admin']);

        $this->renderer->render("adminDashboard");
    }

    /**
     * API endpoint para obtener datos de métricas via AJAX
     * Espera parámetros GET: metrica, filtro
     */
    public function obtenerDatosMetricas()
    {
        // Verificar que el usuario es administrador
        SecurityHelper::checkRole(['admin']);

        // Obtener los parámetros de la solicitud
        $metrica = $_GET['metrica'] ?? '';
        $filtro = $_GET['filtro'] ?? null; // dia, semana, mes, año

        // Validar que la métrica sea solicitada
        if (empty($metrica)) {
            header('Content-Type: application/json');
            echo json_encode(['error' => 'Métrica no especificada']);
            return;
        }

        // Obtener los datos según la métrica solicitada
        $datos = [];
        try {
            switch ($metrica) {
                case 'estadisticasGenerales':
                    $datos = $this->model->obtenerEstadisticasGenerales($filtro);
                    break;
                case 'porcentajeRespuestas':
                    $datos = $this->model->obtenerPorcentajeRespuestasCorrectasPorUsuario($filtro);
                    break;
                case 'usuariosPorPais':
                    $datos = $this->model->obtenerUsuariosPorPais($filtro);
                    break;
                case 'usuariosPorSexo':
                    $datos = $this->model->obtenerUsuariosPorSexo($filtro);
                    break;
                case 'usuariosPorGrupoEdad':
                    $datos = $this->model->obtenerUsuariosPorGrupoEdad($filtro);
                    break;
                default:
                    $datos = ['error' => 'Métrica desconocida'];
            }

            // Retornar JSON
            header('Content-Type: application/json');
            echo json_encode($datos);
        } catch (Exception $e) {
            header('Content-Type: application/json');
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Genera un PDF con los reportes del dashboard
     */
    public function generarPDF()
    {
        // Verificar que el usuario es administrador
        SecurityHelper::checkRole(['admin']);

        // Obtener el tipo de filtro del formulario
        $filtro = $_POST['filtro'] ?? 'mes';

        // Obtener todos los datos
        $estadisticasGenerales = $this->model->obtenerEstadisticasGenerales($filtro);
        $porcentajeRespuestas = $this->model->obtenerPorcentajeRespuestasCorrectasPorUsuario($filtro);
        $usuariosPorPais = $this->model->obtenerUsuariosPorPais($filtro);
        $usuariosPorSexo = $this->model->obtenerUsuariosPorSexo($filtro);
        $usuariosPorGrupoEdad = $this->model->obtenerUsuariosPorGrupoEdad($filtro);

        // Generar HTML del PDF
        $html = $this->generarHtmlPDF(
            $estadisticasGenerales,
            $porcentajeRespuestas,
            $usuariosPorPais,
            $usuariosPorSexo,
            $usuariosPorGrupoEdad,
            $filtro
        );

        // Configurar DomPDF
        $options = new Options();
        $options->set('defaultFont', 'Courier');
        $options->set('isRemoteEnabled', true);

        $dompdf = new Dompdf($options);
        $dompdf->loadHtml($html);
        $dompdf->setPaper('A4', 'portrait');
        $dompdf->render();

        // Descargar PDF
        $nombreArchivo = 'reporte_admin_' . date('Y-m-d_H-i-s') . '.pdf';
        $dompdf->stream($nombreArchivo, array("Attachment" => true));
    }

    /**
     * Genera el HTML para el PDF con formato personalizado
     */
    private function generarHtmlPDF($estadisticas, $porcentajeRespuestas, $usuariosPorPais, $usuariosPorSexo, $usuariosPorGrupoEdad, $filtro)
    {
        $fechaGeneracion = date('d/m/Y H:i:s');
        $nombreFiltro = $this->obtenerNombreFiltro($filtro);

        $html = <<<HTML
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Administración - Preguntados</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            font-size: 10pt;
            color: #333;
            line-height: 1.6;
        }

        header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 3px solid #0056b3;
            padding-bottom: 15px;
        }

        header h1 {
            color: #0056b3;
            font-size: 24pt;
            margin-bottom: 5px;
        }

        header p {
            color: #666;
            font-size: 11pt;
        }

        .metadata {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
            font-size: 9pt;
            color: #666;
        }

        .section {
            margin-bottom: 30px;
            page-break-inside: avoid;
        }

        .section h2 {
            background-color: #0056b3;
            color: white;
            padding: 10px 15px;
            font-size: 14pt;
            margin-bottom: 15px;
            border-radius: 3px;
        }

        .estadisticas-grid {
            display: table;
            width: 100%;
            margin-bottom: 20px;
        }

        .estadistica-item {
            display: table-cell;
            width: 20%;
            padding: 15px;
            text-align: center;
            border: 1px solid #ddd;
            background-color: #f9f9f9;
        }

        .estadistica-valor {
            font-size: 18pt;
            font-weight: bold;
            color: #0056b3;
        }

        .estadistica-label {
            font-size: 9pt;
            color: #666;
            margin-top: 5px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }

        table thead {
            background-color: #f0f0f0;
        }

        table th {
            padding: 10px;
            text-align: left;
            font-weight: bold;
            border-bottom: 2px solid #0056b3;
            font-size: 10pt;
        }

        table td {
            padding: 8px 10px;
            border-bottom: 1px solid #ddd;
            font-size: 9pt;
        }

        table tr:nth-child(even) {
            background-color: #f9f9f9;
        }

        .footer {
            margin-top: 40px;
            text-align: right;
            font-size: 8pt;
            color: #999;
            border-top: 1px solid #ddd;
            padding-top: 10px;
        }

        .no-data {
            padding: 20px;
            text-align: center;
            color: #999;
            background-color: #f9f9f9;
            border: 1px solid #ddd;
        }
    </style>
</head>
<body>
    <header>
        <h1>Preguntados</h1>
        <p>Reporte de Administración</p>
    </header>

    <div class="metadata">
        <span><strong>Período:</strong> {$nombreFiltro}</span>
        <span><strong>Generado:</strong> {$fechaGeneracion}</span>
    </div>

    <!-- Sección de Estadísticas Generales -->
    <div class="section">
        <h2>Estadísticas Generales</h2>
        <div class="estadisticas-grid">
            <div class="estadistica-item">
                <div class="estadistica-valor">{$estadisticas['totalJugadores']}</div>
                <div class="estadistica-label">Total de Jugadores</div>
            </div>
            <div class="estadistica-item">
                <div class="estadistica-valor">{$estadisticas['totalPartidasJugadas']}</div>
                <div class="estadistica-label">Partidas Jugadas</div>
            </div>
            <div class="estadistica-item">
                <div class="estadistica-valor">{$estadisticas['totalPreguntasEnJuego']}</div>
                <div class="estadistica-label">Preguntas Activas</div>
            </div>
            <div class="estadistica-item">
                <div class="estadistica-valor">{$estadisticas['totalPreguntasCreadas']}</div>
                <div class="estadistica-label">Preguntas Creadas</div>
            </div>
            <div class="estadistica-item">
                <div class="estadistica-valor">{$estadisticas['usuariosNuevos']}</div>
                <div class="estadistica-label">Usuarios Nuevos</div>
            </div>
        </div>
    </div>

    <!-- Sección de Usuarios por País -->
    <div class="section">
        <h2>Usuarios por País</h2>
HTML;

        if (count($usuariosPorPais) > 0) {
            $html .= '<table>
                        <thead>
                            <tr>
                                <th>País</th>
                                <th>Cantidad de Usuarios</th>
                            </tr>
                        </thead>
                        <tbody>';
            foreach ($usuariosPorPais as $pais) {
                $html .= '<tr>
                            <td>' . htmlspecialchars($pais['pais']) . '</td>
                            <td>' . htmlspecialchars($pais['cantidad_usuarios']) . '</td>
                          </tr>';
            }
            $html .= '</tbody></table>';
        } else {
            $html .= '<div class="no-data">No hay datos disponibles</div>';
        }

        $html .= '</div>';

        // Sección de Usuarios por Sexo
        $html .= '<div class="section">
                    <h2>Usuarios por Sexo</h2>';

        if (count($usuariosPorSexo) > 0) {
            $html .= '<table>
                        <thead>
                            <tr>
                                <th>Sexo</th>
                                <th>Cantidad de Usuarios</th>
                            </tr>
                        </thead>
                        <tbody>';
            foreach ($usuariosPorSexo as $sexo) {
                $html .= '<tr>
                            <td>' . htmlspecialchars($sexo['sexo']) . '</td>
                            <td>' . htmlspecialchars($sexo['cantidad_usuarios']) . '</td>
                          </tr>';
            }
            $html .= '</tbody></table>';
        } else {
            $html .= '<div class="no-data">No hay datos disponibles</div>';
        }

        $html .= '</div>';

        // Sección de Usuarios por Grupo de Edad
        $html .= '<div class="section">
                    <h2>Usuarios por Grupo de Edad</h2>';

        if (count($usuariosPorGrupoEdad) > 0) {
            $html .= '<table>
                        <thead>
                            <tr>
                                <th>Grupo de Edad</th>
                                <th>Cantidad de Usuarios</th>
                            </tr>
                        </thead>
                        <tbody>';
            foreach ($usuariosPorGrupoEdad as $grupo) {
                $html .= '<tr>
                            <td>' . htmlspecialchars($grupo['grupo_edad']) . '</td>
                            <td>' . htmlspecialchars($grupo['cantidad_usuarios']) . '</td>
                          </tr>';
            }
            $html .= '</tbody></table>';
        } else {
            $html .= '<div class="no-data">No hay datos disponibles</div>';
        }

        $html .= '</div>';

        // Sección de Porcentaje de Respuestas Correctas
        $html .= '<div class="section">
                    <h2>Porcentaje de Respuestas Correctas por Usuario</h2>';

        if (count($porcentajeRespuestas) > 0) {
            $html .= '<table>
                        <thead>
                            <tr>
                                <th>Usuario</th>
                                <th>Total Respuestas</th>
                                <th>Respuestas Correctas</th>
                                <th>Porcentaje de Acierto</th>
                            </tr>
                        </thead>
                        <tbody>';
            foreach ($porcentajeRespuestas as $usuario) {
                $html .= '<tr>
                            <td>' . htmlspecialchars($usuario['nombre_usuario']) . '</td>
                            <td>' . htmlspecialchars($usuario['total_respuestas']) . '</td>
                            <td>' . htmlspecialchars($usuario['respuestas_correctas']) . '</td>
                            <td>' . htmlspecialchars($usuario['porcentaje_acierto']) . '%</td>
                          </tr>';
            }
            $html .= '</tbody></table>';
        } else {
            $html .= '<div class="no-data">No hay datos disponibles</div>';
        }

        $html .= '</div>';

        $html .= '
    <div class="footer">
        <p>Documento generado automáticamente por el sistema de administración</p>
    </div>
</body>
</html>
';

        return $html;
    }

    /**
     * Obtiene el nombre descriptivo del filtro
     */
    private function obtenerNombreFiltro($filtro)
    {
        switch ($filtro) {
            case 'dia':
                return 'Hoy (' . date('d/m/Y') . ')';
            case 'semana':
                return 'Esta semana';
            case 'mes':
                return 'Este mes';
            case 'año':
                return 'Este año';
            default:
                return 'Sin especificar';
        }
    }
}
