/* ================================================================
   app.js — Ultrasonic Level Transmitter HMI Dashboard
   B.Tech ICE Semester 3 — Numerical Methods Project
   ================================================================
   WebSocket → live data → Chart.js trend + tank visualiser
   Gauss Elimination calibration computed fully in browser JS
   ================================================================ */

'use strict';

// ---------------------------------------------------------------
// CONSTANTS
// ---------------------------------------------------------------
const TANK_H     = 30;    // cm — must match Arduino TANK_HEIGHT_CM
const LEVEL_HIGH = 22;    // cm
const LEVEL_LOW  = 8;     // cm
const MAX_PTS    = 120;   // trend chart history points

// ---------------------------------------------------------------
// STATE
// ---------------------------------------------------------------
let ws        = null;
let lastData  = { dist: 0, level: 0, pct: 0, relay: 0, ts: '--:--:--' };

// Calibration data table
let calDist  = [];
let calLevel = [];

// Fitted coefficients (updated after Gauss run)
let fitA0 = NaN;
let fitA1 = NaN;

// ---------------------------------------------------------------
// CHART: Trend
// ---------------------------------------------------------------
const trendCtx   = document.getElementById('trendChart').getContext('2d');
const trendLabels = Array(MAX_PTS).fill('');
const trendData   = Array(MAX_PTS).fill(null);

const trendChart = new Chart(trendCtx, {
  type: 'line',
  data: {
    labels: trendLabels,
    datasets: [
      {
        label: 'Water Level (cm)',
        data: trendData,
        borderColor: '#00d4ff',
        backgroundColor: 'rgba(0,212,255,0.08)',
        borderWidth: 2,
        pointRadius: 0,
        tension: 0.4,
        fill: true,
      },
      {
        label: 'HIGH Threshold',
        data: Array(MAX_PTS).fill(LEVEL_HIGH),
        borderColor: '#ff4757',
        borderDash: [6, 3],
        borderWidth: 1.5,
        pointRadius: 0,
        fill: false,
      },
      {
        label: 'LOW Threshold',
        data: Array(MAX_PTS).fill(LEVEL_LOW),
        borderColor: '#00e676',
        borderDash: [6, 3],
        borderWidth: 1.5,
        pointRadius: 0,
        fill: false,
      }
    ]
  },
  options: {
    animation: false,
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { labels: { color: '#9ab', font: { size: 11 } } }
    },
    scales: {
      x: { ticks: { display: false }, grid: { color: 'rgba(255,255,255,0.06)' } },
      y: {
        min: 0, max: TANK_H * 1.05,
        ticks: { color: '#7a8aa0', font: { size: 11 } },
        grid: { color: 'rgba(255,255,255,0.06)' }
      }
    }
  }
});

// ---------------------------------------------------------------
// CHART: Calibration Curve
// ---------------------------------------------------------------
const curveCtx = document.getElementById('curveChart').getContext('2d');
const curveChart = new Chart(curveCtx, {
  type: 'scatter',
  data: {
    datasets: [
      {
        label: 'Measured Points',
        data: [],
        backgroundColor: '#ffb300',
        pointRadius: 7,
        pointHoverRadius: 9,
      },
      {
        label: 'Gauss Elimination Fit',
        data: [],
        type: 'line',
        borderColor: '#00e676',
        backgroundColor: 'rgba(0,230,118,0.08)',
        borderWidth: 2.5,
        pointRadius: 0,
        fill: false,
        tension: 0,
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    animation: { duration: 400 },
    plugins: {
      legend: { labels: { color: '#9ab', font: { size: 11 } } }
    },
    scales: {
      x: {
        title: { display: true, text: 'Distance (cm)', color: '#7a8aa0', font: { size: 11 } },
        ticks: { color: '#7a8aa0' },
        grid: { color: 'rgba(255,255,255,0.06)' }
      },
      y: {
        title: { display: true, text: 'Level (cm)', color: '#7a8aa0', font: { size: 11 } },
        ticks: { color: '#7a8aa0' },
        grid: { color: 'rgba(255,255,255,0.06)' }
      }
    }
  }
});

// ---------------------------------------------------------------
// WEBSOCKET
// ---------------------------------------------------------------
function getWsPort() {
  return parseInt(document.getElementById('wsPort').value, 10) || 8765;
}

function connectWS() {
  const badge  = document.getElementById('connBadge');
  const txt    = document.getElementById('connText');
  badge.className = 'conn-badge';
  txt.textContent = 'Connecting…';

  try {
    ws = new WebSocket(`ws://localhost:${getWsPort()}`);
  } catch (e) {
    badge.classList.add('error');
    txt.textContent = 'WS Error';
    return;
  }

  ws.onopen = () => {
    badge.classList.add('connected');
    txt.textContent = 'Connected';
    appendLog('[WS] Connected to bridge.');
    document.getElementById('ledSerial').classList.add('on');
  };

  ws.onmessage = (evt) => {
    try {
      const d = JSON.parse(evt.data);
      lastData = d;
      updateUI(d);
    } catch (_) {}
  };

  ws.onerror = () => {
    badge.classList.remove('connected');
    badge.classList.add('error');
    txt.textContent = 'WS Error';
    document.getElementById('ledSerial').classList.remove('on');
    appendLog('[WS] Connection error.', true);
  };

  ws.onclose = () => {
    badge.classList.remove('connected');
    txt.textContent = 'Disconnected';
    document.getElementById('ledSerial').classList.remove('on');
    appendLog('[WS] Disconnected. Retrying in 4s…');
    setTimeout(connectWS, 4000);
  };
}

function reconnectWS() {
  if (ws) { ws.onclose = null; ws.close(); }
  connectWS();
}

// ---------------------------------------------------------------
// UI UPDATER
// ---------------------------------------------------------------
function updateUI(d) {
  // Metrics
  document.getElementById('metDist').textContent  = d.dist.toFixed(2);
  document.getElementById('metLevel').textContent = d.level.toFixed(2);
  document.getElementById('metPct').textContent   = d.pct.toFixed(1) + '%';

  const pumpTile = document.getElementById('tilePump');
  const pumpVal  = document.getElementById('metPump');
  if (d.relay === 1) {
    pumpVal.textContent = 'ON';
    pumpTile.classList.add('pump-on');
    document.getElementById('ledRed').classList.add('on');
    document.getElementById('ledGreen').classList.remove('on');
  } else {
    pumpVal.textContent = 'OFF';
    pumpTile.classList.remove('pump-on');
    document.getElementById('ledRed').classList.remove('on');
    document.getElementById('ledGreen').classList.add('on');
  }

  // Tank fill
  const fillPct = Math.min(100, Math.max(0, (d.level / TANK_H) * 100));
  document.getElementById('waterFill').style.height = fillPct + '%';
  document.getElementById('tankLevelLabel').textContent = d.pct.toFixed(1) + '%';

  // Tank card border glow
  const tc = document.getElementById('tankCard');
  if (d.level >= LEVEL_HIGH) {
    tc.style.borderColor = 'rgba(255,71,87,0.5)';
    tc.style.boxShadow   = '0 0 22px rgba(255,71,87,0.25)';
  } else if (d.level <= LEVEL_LOW) {
    tc.style.borderColor = 'rgba(255,179,0,0.4)';
    tc.style.boxShadow   = '0 0 22px rgba(255,179,0,0.2)';
  } else {
    tc.style.borderColor = 'rgba(0,212,255,0.12)';
    tc.style.boxShadow   = '';
  }

  // Trend chart ring buffer push
  trendData.push(d.level);
  trendData.shift();
  trendChart.update('none');

  // Log
  appendLog(`[${d.ts}] Dist=${d.dist.toFixed(2)}cm  Level=${d.level.toFixed(2)}cm  Fill=${d.pct.toFixed(1)}%  Pump=${d.relay ? 'ON' : 'OFF'}`);
}

// ---------------------------------------------------------------
// CLOCK
// ---------------------------------------------------------------
function updateClock() {
  const now = new Date();
  document.getElementById('headerTime').textContent =
    now.toLocaleTimeString('en-IN', { hour12: false });
}
setInterval(updateClock, 1000);
updateClock();

// ---------------------------------------------------------------
// LOG
// ---------------------------------------------------------------
function appendLog(msg, isErr = false) {
  const lb = document.getElementById('logBody');
  const p  = document.createElement('div');
  p.textContent = msg;
  if (isErr) p.className = 'log-err';
  lb.appendChild(p);
  // Keep only last 200 lines
  while (lb.children.length > 200) lb.removeChild(lb.firstChild);
  lb.scrollTop = lb.scrollHeight;
}

function clearLog() {
  document.getElementById('logBody').innerHTML = '';
}

// ---------------------------------------------------------------
// CALIBRATION DATA TABLE
// ---------------------------------------------------------------
function renderTable() {
  const tbody = document.getElementById('calTbody');
  tbody.innerHTML = '';
  calDist.forEach((d, i) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${i + 1}</td>
      <td>${d.toFixed(2)}</td>
      <td>${calLevel[i].toFixed(2)}</td>
      <td><button class="btn-del" onclick="deletePoint(${i})">✕</button></td>`;
    tbody.appendChild(tr);
  });

  // Update scatter chart points
  curveChart.data.datasets[0].data = calDist.map((d, i) => ({ x: d, y: calLevel[i] }));
  curveChart.update();
}

function addCalPoint() {
  const dv = parseFloat(document.getElementById('calDistInput').value);
  const lv = parseFloat(document.getElementById('calLevelInput').value);
  if (isNaN(dv) || isNaN(lv)) {
    alert('Enter valid Distance and Level values.');
    return;
  }
  calDist.push(dv);
  calLevel.push(lv);
  document.getElementById('calDistInput').value  = '';
  document.getElementById('calLevelInput').value = '';
  renderTable();
}

function addLivePoint() {
  calDist.push(lastData.dist);
  calLevel.push(lastData.level);
  renderTable();
  appendLog(`[CAL] Live point added: Dist=${lastData.dist.toFixed(2)} Level=${lastData.level.toFixed(2)}`);
}

function deletePoint(idx) {
  calDist.splice(idx, 1);
  calLevel.splice(idx, 1);
  renderTable();
}

// ---------------------------------------------------------------
// GAUSS ELIMINATION (pure JS — same algorithm as MATLAB/Arduino)
// ---------------------------------------------------------------
function gaussianElimination(A, b) {
  const n = b.length;
  // Build augmented matrix
  const M = A.map((row, i) => [...row, b[i]]);

  // Forward elimination with partial pivoting
  for (let k = 0; k < n - 1; k++) {
    // Find pivot
    let maxVal = Math.abs(M[k][k]);
    let maxRow = k;
    for (let i = k + 1; i < n; i++) {
      if (Math.abs(M[i][k]) > maxVal) { maxVal = Math.abs(M[i][k]); maxRow = i; }
    }
    // Swap
    if (maxRow !== k) [M[k], M[maxRow]] = [M[maxRow], M[k]];

    // Eliminate below
    for (let i = k + 1; i < n; i++) {
      const factor = M[i][k] / M[k][k];
      for (let j = k; j <= n; j++) {
        M[i][j] -= factor * M[k][j];
      }
    }
  }

  // Back substitution
  const x = new Array(n).fill(0);
  for (let i = n - 1; i >= 0; i--) {
    x[i] = M[i][n];
    for (let j = i + 1; j < n; j++) x[i] -= M[i][j] * x[j];
    x[i] /= M[i][i];
  }
  return x;
}

function runGaussElim() {
  const n = calDist.length;
  if (n < 3) {
    alert('Need at least 3 calibration data points.');
    return;
  }

  // Normal equations for: Level = a0 + a1 * Distance
  // [  N      sumX ] [a0]   [sumY ]
  // [ sumX   sumX2 ] [a1] = [sumXY]
  const sumX  = calDist.reduce((s, v) => s + v, 0);
  const sumX2 = calDist.reduce((s, v) => s + v * v, 0);
  const sumY  = calLevel.reduce((s, v) => s + v, 0);
  const sumXY = calDist.reduce((s, v, i) => s + v * calLevel[i], 0);

  const A = [[n, sumX], [sumX, sumX2]];
  const b = [sumY, sumXY];

  const coeffs = gaussianElimination(A, b);
  fitA0 = coeffs[0];
  fitA1 = coeffs[1];

  // Error metrics
  const levFit = calDist.map(d => fitA0 + fitA1 * d);
  const errors = calLevel.map((l, i) => l - levFit[i]);
  const rmse   = Math.sqrt(errors.reduce((s, e) => s + e * e, 0) / n);
  const ssTot  = calLevel.reduce((s, l) => s + (l - sumY / n) ** 2, 0);
  const ssRes  = errors.reduce((s, e) => s + e * e, 0);
  const R2     = 1 - ssRes / ssTot;

  // Display results
  document.getElementById('resA0').textContent     = fitA0.toFixed(6);
  document.getElementById('resA1').textContent     = fitA1.toFixed(6);
  document.getElementById('resFormula').textContent = `Level = ${fitA0.toFixed(4)} + (${fitA1.toFixed(4)}) × Dist`;
  document.getElementById('resRMSE').textContent   = rmse.toFixed(4) + ' cm';
  document.getElementById('resR2').textContent     = R2.toFixed(6);
  document.getElementById('calibResults').style.display = 'block';

  // Update calibration curve fit line
  const dMin = Math.min(...calDist);
  const dMax = Math.max(...calDist);
  const fitPoints = [];
  for (let i = 0; i <= 40; i++) {
    const d = dMin + (dMax - dMin) * i / 40;
    fitPoints.push({ x: d, y: fitA0 + fitA1 * d });
  }
  curveChart.data.datasets[1].data = fitPoints;
  curveChart.update();

  appendLog(`[GAUSS] a0=${fitA0.toFixed(6)} a1=${fitA1.toFixed(6)} RMSE=${rmse.toFixed(4)} R2=${R2.toFixed(6)}`);

  // Console output for copying to Arduino
  console.log('%c=== GAUSS ELIMINATION RESULT ===', 'color:#00d4ff;font-weight:bold');
  console.log(`const float COEFF_A0 = ${fitA0.toFixed(6)}f;`);
  console.log(`const float COEFF_A1 = ${fitA1.toFixed(6)}f;`);
  console.log(`// Level = a0 + a1 * Distance  |  RMSE = ${rmse.toFixed(4)} cm  |  R2 = ${R2.toFixed(6)}`);
}

// ---------------------------------------------------------------
// DEMO MODE (when WS not available — simulates data for offline preview)
// ---------------------------------------------------------------
function startDemoMode() {
  appendLog('[DEMO] No WebSocket. Running simulation mode.');
  document.getElementById('connBadge').style.opacity = '0.6';
  document.getElementById('connText').textContent = 'Demo Mode';

  let t = 0;
  setInterval(() => {
    const level = 10 + 10 * Math.sin(t * 0.08) + Math.random() * 0.5;
    const dist  = (TANK_H - level) + Math.random() * 0.3;
    const pct   = (level / TANK_H) * 100;
    const relay = level >= LEVEL_HIGH ? 1 : (level <= LEVEL_LOW ? 0 : (lastData.relay || 0));
    const now   = new Date().toLocaleTimeString('en-IN', { hour12: false });
    t++;
    lastData = { dist, level, pct, relay, ts: now };
    updateUI(lastData);
  }, 500);
}

// ---------------------------------------------------------------
// INIT
// ---------------------------------------------------------------
document.addEventListener('DOMContentLoaded', () => {
  connectWS();
  // Give WS 2 seconds to connect; if still not connected, show demo mode
  setTimeout(() => {
    if (!ws || ws.readyState !== WebSocket.OPEN) {
      startDemoMode();
    }
  }, 2500);
});
