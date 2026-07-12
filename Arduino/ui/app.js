var socket = io();

var statusEl    = document.getElementById('status');
var tempEl      = document.getElementById('temperature');
var tempUnitEl  = document.querySelector('.temp-unit');
var humidityEl  = document.getElementById('humidity');
var updatedEl   = document.getElementById('updated');
var unitToggleBtn = document.getElementById('unit-toggle');
var rfidBadgeEl = document.getElementById('rfid-badge');

var useFahrenheit = false;
var lastTempC = null;

// ── Connection status ──────────────────────────────────────
socket.on('connect', function () {
  statusEl.className = 'status connected';
  statusEl.textContent = '● Connected';
  socket.emit('request_temperature', {});
});

socket.on('disconnect', function () {
  statusEl.className = 'status disconnected';
  statusEl.textContent = '● Disconnected';
});

socket.on('connect_error', function () {
  statusEl.className = 'status connecting';
  statusEl.textContent = 'Connecting…';
});

// ── Live readings ───────────────────────────────────────────
socket.on('temperature_update', function (data) {
  if (!data || typeof data.temperature_c !== 'number') return;

  lastTempC = data.temperature_c;
  renderTemperature();

  if (typeof data.humidity === 'number') {
    humidityEl.textContent = data.humidity.toFixed(1) + ' %';
  }

  var rfidPresent = data.rfid_present === true;
  rfidBadgeEl.textContent   = rfidPresent ? 'PRESENT' : 'ABSENT';
  rfidBadgeEl.className     = 'rfid-badge ' + (rfidPresent ? 'present' : 'absent');

  updatedEl.textContent = new Date().toLocaleTimeString();

  tempEl.classList.remove('pulse');
  void tempEl.offsetWidth;
  tempEl.classList.add('pulse');
});

socket.on('temperature_error', function (data) {
  tempEl.textContent    = '--';
  updatedEl.textContent = (data && data.message) ? data.message : 'Sensor error';
});

// ── Rendering ───────────────────────────────────────────────
function renderTemperature() {
  if (lastTempC === null) return;
  if (useFahrenheit) {
    var f = (lastTempC * 9) / 5 + 32;
    tempEl.textContent    = f.toFixed(1);
    tempUnitEl.textContent = '°F';
  } else {
    tempEl.textContent    = lastTempC.toFixed(1);
    tempUnitEl.textContent = '°C';
  }
}

// ── Unit toggle ─────────────────────────────────────────────
unitToggleBtn.addEventListener('click', function () {
  useFahrenheit = !useFahrenheit;
  unitToggleBtn.textContent = useFahrenheit ? 'Show °C' : 'Show °F';
  renderTemperature();
});
