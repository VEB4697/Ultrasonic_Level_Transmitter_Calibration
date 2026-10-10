% ============================================================
%  Ultrasonic Level Transmitter — MATLAB HMI Dashboard
% ============================================================
%  Project : Calibration of Ultrasonic Level Transmitter
%            using Arduino UNO and Gauss Elimination Method
%  Course  : B.Tech ICE -- Numerical Methods (Semester 3)
%
%  HOW TO USE:
%    1. Upload Level_Calibration.ino to Arduino UNO.
%    2. Change COM_PORT below to your Arduino COM port.
%    3. Run this script in MATLAB (R2019a+).
%    4. The GUI shows live level, pump status, calibration
%       curve, and computes Gauss Elimination on collected data.
%
%  Hardware: Arduino UNO + HC-SR04 + Relay + GREEN/RED LED
% ============================================================

clear; clc; close all;

%% ---- User Configuration ----------------------------------------
COM_PORT     = 'COM3';          % <-- Change to your Arduino port
BAUD_RATE    = 115200;
TANK_HEIGHT  = 30.0;            % cm (match Arduino TANK_HEIGHT_CM)
LEVEL_HIGH   = 22.0;            % cm HIGH threshold
LEVEL_LOW    = 8.0;             % cm LOW threshold
MAX_HISTORY  = 120;             % Points to keep in live chart (~60 s)
%% ----------------------------------------------------------------

fprintf('=============================================================\n');
fprintf(' ULTRASONIC LEVEL TRANSMITTER CALIBRATION -- MATLAB HMI\n');
fprintf(' Method: Gauss Elimination on Normal Equations\n');
fprintf('=============================================================\n');

%% ---- Open Serial Port ------------------------------------------
s = serialport(COM_PORT, BAUD_RATE);
configureTerminator(s, "LF");
flush(s);
fprintf('[OK] Serial port %s opened at %d baud.\n', COM_PORT, BAUD_RATE);

%% ---- Calibration Data Buffers ----------------------------------
cal_dist  = [];   % Raw distance readings (cm)
cal_level = [];   % Reference/calibrated level readings (cm)

%% ---- Build MATLAB GUI (HMI) ------------------------------------
fig = figure('Name','Ultrasonic Level Transmitter HMI', ...
    'NumberTitle','off', 'Position',[50 50 1100 650], ...
    'Color',[0.08 0.08 0.12], 'CloseRequestFcn',@onClose);

% ---- Panel: Live Gauge (left column) ----------------------------
pnl_gauge = uipanel(fig, 'Title','LIVE STATUS', ...
    'Position',[0.01 0.55 0.22 0.43], ...
    'BackgroundColor',[0.1 0.1 0.15], ...
    'ForegroundColor',[0.6 0.9 1], 'FontSize',10, 'FontWeight','bold');

lbl_dist = uicontrol(pnl_gauge,'Style','text', ...
    'String','Dist: --- cm', 'Units','normalized', ...
    'Position',[0.05 0.75 0.90 0.15], ...
    'BackgroundColor',[0.1 0.1 0.15], 'ForegroundColor',[1 0.9 0.3], ...
    'FontSize',13, 'FontWeight','bold', 'HorizontalAlignment','left');

lbl_level = uicontrol(pnl_gauge,'Style','text', ...
    'String','Level: --- cm', 'Units','normalized', ...
    'Position',[0.05 0.55 0.90 0.15], ...
    'BackgroundColor',[0.1 0.1 0.15], 'ForegroundColor',[0.3 1 0.5], ...
    'FontSize',13, 'FontWeight','bold', 'HorizontalAlignment','left');

lbl_pct = uicontrol(pnl_gauge,'Style','text', ...
    'String','Fill: --- %', 'Units','normalized', ...
    'Position',[0.05 0.35 0.90 0.15], ...
    'BackgroundColor',[0.1 0.1 0.15], 'ForegroundColor',[0.5 0.8 1], ...
    'FontSize',13, 'FontWeight','bold', 'HorizontalAlignment','left');

lbl_pump = uicontrol(pnl_gauge,'Style','text', ...
    'String','PUMP: OFF', 'Units','normalized', ...
    'Position',[0.05 0.10 0.90 0.20], ...
    'BackgroundColor',[0.08 0.3 0.08], 'ForegroundColor',[0.3 1 0.3], ...
    'FontSize',14, 'FontWeight','bold', 'HorizontalAlignment','center');

% ---- Panel: Calibration Results (left column bottom) ------------
pnl_cal = uipanel(fig, 'Title','GAUSS ELIMINATION RESULTS', ...
    'Position',[0.01 0.02 0.22 0.50], ...
    'BackgroundColor',[0.1 0.1 0.15], ...
    'ForegroundColor',[0.6 0.9 1], 'FontSize',10, 'FontWeight','bold');

txt_cal = uicontrol(pnl_cal, 'Style','text', ...
    'String',{'Collect data points', 'then click CALIBRATE'}, ...
    'Units','normalized', 'Position',[0.03 0.50 0.94 0.45], ...
    'BackgroundColor',[0.1 0.1 0.15], 'ForegroundColor',[0.85 0.85 0.85], ...
    'FontSize',9, 'HorizontalAlignment','left');

btn_cal = uicontrol(pnl_cal, 'Style','pushbutton', ...
    'String','RUN GAUSS ELIMINATION', 'Units','normalized', ...
    'Position',[0.05 0.30 0.90 0.15], ...
    'BackgroundColor',[0.1 0.4 0.8], 'ForegroundColor','white', ...
    'FontSize',9, 'FontWeight','bold', 'Callback',@runCalibration);

btn_add = uicontrol(pnl_cal, 'Style','pushbutton', ...
    'String','ADD CURRENT POINT', 'Units','normalized', ...
    'Position',[0.05 0.12 0.90 0.15], ...
    'BackgroundColor',[0.1 0.6 0.3], 'ForegroundColor','white', ...
    'FontSize',9, 'FontWeight','bold', 'Callback',@addCalPoint);

lbl_npts = uicontrol(pnl_cal, 'Style','text', ...
    'String','Data points: 0', 'Units','normalized', ...
    'Position',[0.05 0.01 0.90 0.10], ...
    'BackgroundColor',[0.1 0.1 0.15], 'ForegroundColor',[0.7 0.7 0.7], ...
    'FontSize',9, 'HorizontalAlignment','center');

% ---- Axes: Live Level Trend (right top) -------------------------
ax_trend = axes('Parent',fig, 'Position',[0.26 0.55 0.72 0.42], ...
    'Color',[0.05 0.05 0.09], 'XColor',[0.7 0.7 0.7], ...
    'YColor',[0.7 0.7 0.7], 'GridColor',[0.2 0.2 0.25], ...
    'GridAlpha',0.5, 'XGrid','on', 'YGrid','on');
title(ax_trend, 'Live Water Level Trend', 'Color',[0.6 0.9 1], 'FontSize',12);
xlabel(ax_trend, 'Sample #', 'Color',[0.7 0.7 0.7]);
ylabel(ax_trend, 'Level (cm)', 'Color',[0.7 0.7 0.7]);
ylim(ax_trend, [0 TANK_HEIGHT * 1.1]);
hold(ax_trend,'on');

h_trend     = plot(ax_trend, NaN, NaN, '-', 'Color',[0.3 0.8 1], 'LineWidth',1.8);
h_high_line = yline(ax_trend, LEVEL_HIGH, '--', 'Color',[1 0.3 0.3], 'LineWidth',1.2);
h_low_line  = yline(ax_trend, LEVEL_LOW,  '--', 'Color',[0.3 1 0.3], 'LineWidth',1.2);
legend(ax_trend, {'Level (cm)','HIGH Threshold','LOW Threshold'}, ...
    'TextColor',[0.9 0.9 0.9], 'Color',[0.08 0.08 0.12], 'Location','northwest');

% ---- Axes: Calibration Curve (right bottom) ---------------------
ax_cal = axes('Parent',fig, 'Position',[0.26 0.07 0.72 0.42], ...
    'Color',[0.05 0.05 0.09], 'XColor',[0.7 0.7 0.7], ...
    'YColor',[0.7 0.7 0.7], 'GridColor',[0.2 0.2 0.25], ...
    'GridAlpha',0.5, 'XGrid','on', 'YGrid','on');
title(ax_cal, 'Calibration Curve — Gauss Elimination Fit', 'Color',[0.6 0.9 1], 'FontSize',12);
xlabel(ax_cal, 'HC-SR04 Distance (cm)', 'Color',[0.7 0.7 0.7]);
ylabel(ax_cal, 'Water Level (cm)', 'Color',[0.7 0.7 0.7]);
hold(ax_cal,'on');
h_pts  = scatter(ax_cal, NaN, NaN, 60, [1 0.7 0.2], 'filled', 'DisplayName','Measured Points');
h_fit  = plot(ax_cal, NaN, NaN, '-', 'Color',[0.3 1 0.5], 'LineWidth',2.0, 'DisplayName','Gauss Fit');
legend(ax_cal, 'TextColor',[0.9 0.9 0.9], 'Color',[0.08 0.08 0.12]);

%% ---- Shared state (accessible in callbacks) --------------------
state.dist    = 0;
state.level   = 0;
state.pct     = 0;
state.relay   = 0;
state.history = zeros(1, MAX_HISTORY);
state.count   = 0;
state.running = true;
state.a0      = NaN;
state.a1      = NaN;

%% ---- Main Read Loop --------------------------------------------
fprintf('[RUN] Reading live data. Close the figure window to stop.\n\n');

while state.running && isvalid(fig)
  try
    line = readline(s);
  catch
    break;
  end
  line = strtrim(line);
  if isempty(line) || line(1) == '#'
    continue;   % skip comments / header
  end

  % Parse: DIST,<d>,LEVEL,<l>,PCT,<p>,RELAY,<r>
  tok = regexp(line, ...
    'DIST,([\d.]+),LEVEL,([\d.]+),PCT,([\d.]+),RELAY,([01])', ...
    'tokens','once');
  if isempty(tok), continue; end

  state.dist  = str2double(tok{1});
  state.level = str2double(tok{2});
  state.pct   = str2double(tok{3});
  state.relay = str2double(tok{4});
  state.count = state.count + 1;

  % Update history ring
  state.history = [state.history(2:end), state.level];

  % Update live status labels
  set(lbl_dist,  'String', sprintf('Dist:  %.2f cm', state.dist));
  set(lbl_level, 'String', sprintf('Level: %.2f cm', state.level));
  set(lbl_pct,   'String', sprintf('Fill:  %.1f %%',  state.pct));

  if state.relay == 1
    set(lbl_pump, 'String','PUMP: ON', ...
        'BackgroundColor',[0.4 0.05 0.05], 'ForegroundColor',[1 0.4 0.4]);
  else
    set(lbl_pump, 'String','PUMP: OFF', ...
        'BackgroundColor',[0.05 0.25 0.05], 'ForegroundColor',[0.4 1 0.4]);
  end

  % Update trend chart
  valid_idx = find(~isnan(state.history));
  set(h_trend, 'XData', valid_idx, 'YData', state.history(valid_idx));
  xlim(ax_trend, [1 MAX_HISTORY]);

  drawnow limitrate;
end

%% ---- Cleanup ---------------------------------------------------
delete(s);
fprintf('\n[DONE] Serial port closed.\n');

%% ---- Callbacks -------------------------------------------------
function addCalPoint(~,~)
  cal_dist(end+1)  = state.dist;      % raw distance
  cal_level(end+1) = state.level;     % calibrated level
  set(lbl_npts, 'String', sprintf('Data points: %d', numel(cal_dist)));
  set(h_pts, 'XData', cal_dist, 'YData', cal_level);
  fprintf('[+] Point added: Dist=%.2f cm, Level=%.2f cm\n', ...
      cal_dist(end), cal_level(end));
end

function runCalibration(~,~)
  n = numel(cal_dist);
  if n < 3
    msgbox('Need at least 3 data points.','Error','error');
    return;
  end

  % Normal equations for Level = a0 + a1*Distance
  X = cal_dist(:);
  Y = cal_level(:);

  sum1  = n;
  sumX  = sum(X);
  sumX2 = sum(X.^2);
  sumY  = sum(Y);
  sumXY = sum(X.*Y);

  A_mat = [sum1, sumX; sumX, sumX2];
  B_vec = [sumY; sumXY];

  % ---- Gauss Elimination with Partial Pivoting ----------------
  coeffs = gaussElim(A_mat, B_vec);
  state.a0 = coeffs(1);
  state.a1 = coeffs(2);
  % ------------------------------------------------------------

  Y_fit = state.a0 + state.a1 * X;
  err   = Y - Y_fit;
  rmse  = sqrt(mean(err.^2));
  ss_tot = sum((Y - mean(Y)).^2);
  R2    = 1 - sum(err.^2)/ss_tot;

  % Update calibration plot
  d_range = linspace(min(X)*0.9, max(X)*1.1, 200);
  set(h_fit, 'XData', d_range, 'YData', state.a0 + state.a1*d_range);

  % Display results
  result_str = { ...
    sprintf('a0 = %.6f', state.a0), ...
    sprintf('a1 = %.6f', state.a1), ...
    sprintf('Formula: L = %.4f + (%.4f)*D', state.a0, state.a1), ...
    sprintf('RMSE = %.4f cm', rmse), ...
    sprintf('R^2  = %.6f', R2) };
  set(txt_cal, 'String', result_str);

  fprintf('\n=== GAUSS ELIMINATION CALIBRATION RESULT ===\n');
  fprintf('  a0 = %.8f\n', state.a0);
  fprintf('  a1 = %.8f\n', state.a1);
  fprintf('  Level = a0 + a1 * Distance\n');
  fprintf('  RMSE  = %.4f cm\n', rmse);
  fprintf('  R^2   = %.6f\n', R2);
  fprintf('  >> Update COEFF_A0 and COEFF_A1 in Level_Calibration.ino\n');
  fprintf('=============================================\n\n');
end

function onClose(~,~)
  state.running = false;
  delete(gcf);
end

%% ---- Gauss Elimination Function --------------------------------
function x = gaussElim(A, b)
  n  = length(b);
  Ab = [A, b];                    % Augmented matrix

  % Forward elimination with partial pivoting
  for k = 1:n-1
    [~, maxIdx] = max(abs(Ab(k:n, k)));
    pivRow = maxIdx + k - 1;
    if pivRow ~= k
      Ab([k pivRow], :) = Ab([pivRow k], :);   % Swap rows
    end
    for i = k+1:n
      factor      = Ab(i,k) / Ab(k,k);
      Ab(i, k:end) = Ab(i, k:end) - factor * Ab(k, k:end);
    end
  end

  % Back substitution
  x = zeros(n, 1);
  for i = n:-1:1
    x(i) = (Ab(i, end) - Ab(i, i+1:n) * x(i+1:n)) / Ab(i, i);
  end
end
