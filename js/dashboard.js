// Variable global para guardar el filtro actual
let filtroActual = "mes";

// Inicializar cuando el documento esté listo
document.addEventListener("DOMContentLoaded", function () {
  // Cargar la librería de Google Charts
  google.charts.load("current", { packages: ["corechart", "bar"] });
  google.charts.setOnLoadCallback(inicializarDashboard);

  // Event listeners para los botones de filtro
  document.querySelectorAll(".filtro-btn").forEach((btn) => {
    btn.addEventListener("click", function () {
      cambiarFiltro(this.getAttribute("data-filtro"));
    });
  });

  // Event listener para descargar PDF
  document
    .getElementById("btnDescargarPDF")
    .addEventListener("click", descargarPDF);

  // Event listener para imprimir
  document.getElementById("btnImprimir").addEventListener("click", function () {
    window.print();
  });
});

/**
 * Inicializa el dashboard cargando todos los datos
 */
function inicializarDashboard() {
  cargarDatos(filtroActual);
}

/**
 * Cambia el filtro actual y recarga los datos
 */
function cambiarFiltro(nuevoFiltro) {
  filtroActual = nuevoFiltro;

  // Actualizar UI: marcar botón activo
  document.querySelectorAll(".filtro-btn").forEach((btn) => {
    btn.classList.remove("active");
  });
  document
    .querySelector(`[data-filtro="${nuevoFiltro}"]`)
    .classList.add("active");

  // Recargar datos
  cargarDatos(nuevoFiltro);
}

/**
 * Carga todos los datos del dashboard
 */
function cargarDatos(filtro) {
  // Cargar estadísticas generales
  cargarEstadisticasGenerales(filtro);

  // Cargar datos para gráficos
  cargarDatosGrafico("usuariosPorPais", filtro, dibujarChartUsuariosPorPais);
  cargarDatosGrafico("usuariosPorSexo", filtro, dibujarChartUsuariosPorSexo);
  cargarDatosGrafico(
    "usuariosPorGrupoEdad",
    filtro,
    dibujarChartUsuariosPorGrupoEdad
  );
  cargarDatosGrafico("porcentajeRespuestas", filtro, dibujarTablaRespuestas);
}

/**
 * Carga las estadísticas generales
 */
function cargarEstadisticasGenerales(filtro) {
  fetch(
    `/admin/obtenerDatosMetricas?metrica=estadisticasGenerales&filtro=${filtro}`
  )
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then((datos) => {
      if (datos.error) {
        console.error("Error en API:", datos.error);
        Swal.fire("Error", "Error en la API: " + datos.error, "error");
        return;
      }
      document.getElementById("totalJugadores").textContent =
        datos.totalJugadores || 0;
      document.getElementById("totalPartidas").textContent =
        datos.totalPartidasJugadas || 0;
      document.getElementById("totalPreguntasActivas").textContent =
        datos.totalPreguntasEnJuego || 0;
      document.getElementById("totalPreguntasCreadas").textContent =
        datos.totalPreguntasCreadas || 0;
      document.getElementById("usuariosNuevos").textContent =
        datos.usuariosNuevos || 0;
    })
    .catch((error) => {
      console.error("Error al cargar estadísticas:", error);
      Swal.fire(
        "Error",
        "No se pudieron cargar las estadísticas: " + error.message,
        "error"
      );
    });
}

/**
 * Función genérica para cargar datos de gráficos
 */
function cargarDatosGrafico(metrica, filtro, callback) {
  fetch(`/admin/obtenerDatosMetricas?metrica=${metrica}&filtro=${filtro}`)
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then((datos) => {
      if (datos.error) {
        console.error(`Error al cargar ${metrica}:`, datos.error);
        return;
      }
      callback(datos);
    })
    .catch((error) => {
      console.error(`Error al cargar datos de ${metrica}:`, error);
    });
}

/**
 * Dibuja el gráfico de Usuarios por País
 */
function dibujarChartUsuariosPorPais(datos) {
  if (!datos || datos.length === 0) {
    document.getElementById("chartUsuariosPorPais").innerHTML =
      '<p class="text-center text-muted">No hay datos disponibles</p>';
    return;
  }

  // Preparar datos para Google Charts
  let chartData = [["País", "Cantidad de Usuarios"]];
  datos.forEach((item) => {
    chartData.push([item.pais, parseInt(item.cantidad_usuarios)]);
  });

  // Crear DataTable
  let dataTable = google.visualization.arrayToDataTable(chartData);

  // Opciones del gráfico
  let options = {
    title: "Usuarios por País",
    legend: { position: "bottom" },
    hAxis: {
      title: "País",
      slantedText: true,
    },
    vAxis: {
      title: "Cantidad de Usuarios",
    },
    colors: ["#0056b3"],
  };

  // Dibujar gráfico
  let chart = new google.visualization.ColumnChart(
    document.getElementById("chartUsuariosPorPais")
  );
  chart.draw(dataTable, options);

  // Actualizar tabla para impresión
  actualizarTabla("tbody-paises", datos, ["pais", "cantidad_usuarios"]);

  // Ocultar spinner
  document.getElementById("tablaPaisCargando").style.display = "none";
}

/**
 * Dibuja el gráfico de Usuarios por Sexo
 */
function dibujarChartUsuariosPorSexo(datos) {
  if (!datos || datos.length === 0) {
    document.getElementById("chartUsuariosPorSexo").innerHTML =
      '<p class="text-center text-muted">No hay datos disponibles</p>';
    return;
  }

  // Preparar datos para Google Charts
  let chartData = [["Sexo", "Cantidad"]];
  datos.forEach((item) => {
    chartData.push([item.sexo, parseInt(item.cantidad_usuarios)]);
  });

  // Crear DataTable
  let dataTable = google.visualization.arrayToDataTable(chartData);

  // Opciones del gráfico
  let options = {
    title: "Distribución por Sexo",
    legend: { position: "bottom" },
    pieHole: 0.4,
    colors: ["#0056b3", "#ff6b6b", "#4ecdc4"],
  };

  // Dibujar gráfico
  let chart = new google.visualization.PieChart(
    document.getElementById("chartUsuariosPorSexo")
  );
  chart.draw(dataTable, options);

  // Actualizar tabla para impresión
  actualizarTabla("tbody-sexo", datos, ["sexo", "cantidad_usuarios"]);

  // Ocultar spinner
  document.getElementById("tablaSexoCargando").style.display = "none";
}

/**
 * Dibuja el gráfico de Usuarios por Grupo de Edad
 */
function dibujarChartUsuariosPorGrupoEdad(datos) {
  if (!datos || datos.length === 0) {
    document.getElementById("chartUsuariosPorGrupoEdad").innerHTML =
      '<p class="text-center text-muted">No hay datos disponibles</p>';
    return;
  }

  // Preparar datos para Google Charts
  let chartData = [["Grupo de Edad", "Cantidad"]];
  datos.forEach((item) => {
    chartData.push([item.grupo_edad, parseInt(item.cantidad_usuarios)]);
  });

  // Crear DataTable
  let dataTable = google.visualization.arrayToDataTable(chartData);

  // Opciones del gráfico
  let options = {
    title: "Distribución por Grupo de Edad",
    legend: { position: "bottom" },
    colors: ["#0056b3", "#28a745", "#ffc107"],
    bar: { groupWidth: "75%" },
  };

  // Dibujar gráfico
  let chart = new google.visualization.BarChart(
    document.getElementById("chartUsuariosPorGrupoEdad")
  );
  chart.draw(dataTable, options);

  // Actualizar tabla para impresión
  actualizarTabla("tbody-edad", datos, ["grupo_edad", "cantidad_usuarios"]);

  // Ocultar spinner
  document.getElementById("tablaEdadCargando").style.display = "none";
}

/**
 * Dibuja la tabla de Porcentaje de Respuestas Correctas
 */
function dibujarTablaRespuestas(datos) {
  let tbody = document.getElementById("tbody-porcentaje");
  tbody.innerHTML = "";

  if (!datos || datos.length === 0) {
    tbody.innerHTML =
      '<tr><td colspan="2" class="text-center text-muted">No hay datos disponibles</td></tr>';
    return;
  }

  // Limitar a los primeros 10 usuarios
  datos.slice(0, 10).forEach((usuario) => {
    let fila = document.createElement("tr");
    let barraAncho = usuario.porcentaje_acierto || 0;
    fila.innerHTML = `
            <td>${usuario.nombre_usuario}</td>
            <td>
                <div class="progress" style="height: 20px;">
                    <div class="progress-bar bg-success" style="width: ${barraAncho}%">
                        ${usuario.porcentaje_acierto || 0}%
                    </div>
                </div>
            </td>
        `;
    tbody.appendChild(fila);
  });
}

/**
 * Actualiza una tabla con datos
 */
function actualizarTabla(tbodyId, datos, campos) {
  let tbody = document.getElementById(tbodyId);
  tbody.innerHTML = "";

  if (!datos || datos.length === 0) {
    let fila = document.createElement("tr");
    fila.innerHTML =
      '<td colspan="2" class="text-center text-muted">No hay datos disponibles</td>';
    tbody.appendChild(fila);
    return;
  }

  datos.forEach((item) => {
    let fila = document.createElement("tr");
    let celdas = "";
    campos.forEach((campo) => {
      celdas += `<td>${item[campo]}</td>`;
    });
    fila.innerHTML = celdas;
    tbody.appendChild(fila);
  });
}

/**
 * Descarga el reporte en PDF
 */
function descargarPDF() {
  // Actualizar campo oculto con el filtro actual
  document.getElementById("filtroPDF").value = filtroActual;

  // Mostrar mensaje de confirmación
  Swal.fire({
    title: "Descargar PDF",
    text: "Se generará un PDF con todos los reportes del período seleccionado",
    icon: "info",
    showCancelButton: true,
    confirmButtonText: "Descargar",
    cancelButtonText: "Cancelar",
  }).then((result) => {
    if (result.isConfirmed) {
      document.getElementById("formPDF").submit();
      Swal.fire("Éxito", "El PDF se está descargando...", "success");
    }
  });
}
