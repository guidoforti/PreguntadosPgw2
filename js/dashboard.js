
let filtroActual = "mes";

document.addEventListener("DOMContentLoaded", function () {
s
  google.charts.load("current", { packages: ["corechart", "bar"] });
  google.charts.setOnLoadCallback(inicializarDashboard);


  document.querySelectorAll(".filtro-btn").forEach((btn) => {
    btn.addEventListener("click", function () {
      cambiarFiltro(this.getAttribute("data-filtro"));
    });
  });


  document
    .getElementById("btnDescargarPDF")
    .addEventListener("click", descargarPDF);

  document.getElementById("btnImprimir").addEventListener("click", function () {
    window.print();
  });
});


function inicializarDashboard() {
  cargarDatos(filtroActual);
}

function cambiarFiltro(nuevoFiltro) {
  filtroActual = nuevoFiltro;

  document.querySelectorAll(".filtro-btn").forEach((btn) => {
    btn.classList.remove("active");
  });
  document
    .querySelector(`[data-filtro="${nuevoFiltro}"]`)
    .classList.add("active");

  cargarDatos(nuevoFiltro);
}

function cargarDatos(filtro) {
  cargarEstadisticasGenerales(filtro);

  cargarDatosGrafico("usuariosPorPais", filtro, dibujarChartUsuariosPorPais);
  cargarDatosGrafico("usuariosPorSexo", filtro, dibujarChartUsuariosPorSexo);
  cargarDatosGrafico(
    "usuariosPorGrupoEdad",
    filtro,
    dibujarChartUsuariosPorGrupoEdad
  );
  cargarDatosGrafico("porcentajeRespuestas", filtro, dibujarTablaRespuestas);
}

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
        if (typeof soundManager !== 'undefined') {soundManager.play('alert')};
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
      if (typeof soundManager !== 'undefined') {soundManager.play('alert')};
      Swal.fire(
        "Error",
        "No se pudieron cargar las estadísticas: " + error.message,
        "error"
      );
    });
}

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


function dibujarChartUsuariosPorPais(datos) {
  if (!datos || datos.length === 0) {
    document.getElementById("chartUsuariosPorPais").innerHTML =
      '<p class="text-center text-muted">No hay datos disponibles</p>';
    return;
  }

  let chartData = [["País", "Cantidad de Usuarios"]];
  datos.forEach((item) => {
    chartData.push([item.pais, parseInt(item.cantidad_usuarios)]);
  });

  let dataTable = google.visualization.arrayToDataTable(chartData);

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

  let chart = new google.visualization.ColumnChart(
    document.getElementById("chartUsuariosPorPais")
  );
  chart.draw(dataTable, options);

  actualizarTabla("tbody-paises", datos, ["pais", "cantidad_usuarios"]);

  document.getElementById("tablaPaisCargando").style.display = "none";
}

function dibujarChartUsuariosPorSexo(datos) {
  if (!datos || datos.length === 0) {
    document.getElementById("chartUsuariosPorSexo").innerHTML =
      '<p class="text-center text-muted">No hay datos disponibles</p>';
    return;
  }

  let chartData = [["Sexo", "Cantidad"]];
  datos.forEach((item) => {
    chartData.push([item.sexo, parseInt(item.cantidad_usuarios)]);
  });

  let dataTable = google.visualization.arrayToDataTable(chartData);

  let options = {
    title: "Distribución por Sexo",
    legend: { position: "bottom" },
    pieHole: 0.4,
    colors: ["#0056b3", "#ff6b6b", "#4ecdc4"],
  };

  let chart = new google.visualization.PieChart(
    document.getElementById("chartUsuariosPorSexo")
  );
  chart.draw(dataTable, options);


  actualizarTabla("tbody-sexo", datos, ["sexo", "cantidad_usuarios"]);

  document.getElementById("tablaSexoCargando").style.display = "none";
}


function dibujarChartUsuariosPorGrupoEdad(datos) {
  if (!datos || datos.length === 0) {
    document.getElementById("chartUsuariosPorGrupoEdad").innerHTML =
      '<p class="text-center text-muted">No hay datos disponibles</p>';
    return;
  }

  let chartData = [["Grupo de Edad", "Cantidad"]];
  datos.forEach((item) => {
    chartData.push([item.grupo_edad, parseInt(item.cantidad_usuarios)]);
  });

  let dataTable = google.visualization.arrayToDataTable(chartData);

  let options = {
    title: "Distribución por Grupo de Edad",
    legend: { position: "bottom" },
    colors: ["#0056b3", "#28a745", "#ffc107"],
    bar: { groupWidth: "75%" },
  };

  let chart = new google.visualization.BarChart(
    document.getElementById("chartUsuariosPorGrupoEdad")
  );
  chart.draw(dataTable, options);

  actualizarTabla("tbody-edad", datos, ["grupo_edad", "cantidad_usuarios"]);

  document.getElementById("tablaEdadCargando").style.display = "none";
}

function dibujarTablaRespuestas(datos) {
  let tbody = document.getElementById("tbody-porcentaje");
  tbody.innerHTML = "";

  if (!datos || datos.length === 0) {
    tbody.innerHTML =
      '<tr><td colspan="2" class="text-center text-muted">No hay datos disponibles</td></tr>';
    return;
  }

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

function descargarPDF() {
  // Actualizar campo oculto con el filtro actual
  document.getElementById("filtroPDF").value = filtroActual;

  if (typeof soundManager !== 'undefined'){
      soundManager.play('alert');
  }

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
      if (typeof soundManager !== 'undefined') {soundManager.play('alert')};
      Swal.fire("Éxito", "El PDF se está descargando...", "success");
    }
  });
}
