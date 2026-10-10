<<<<<<< HEAD
%% Ultrasonic Level Transmitter Calibration & Gaussian Elimination
% Author: B.Tech ICE S.Y. Project Team
% File: codes/level_calibration_gauss.m
% Description: MATLAB script implementing Gaussian Elimination with partial 
%              pivoting to fit a linear calibration curve for an Ultrasonic 
%              Level Transmitter system (HC-SR04 / JSN-SR04T).

clear; clc; close all;

%% 1. Experimental Calibration Data
% True liquid level in tank (cm)
true_level = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]'; 

% Measured Transmitter Output Voltage (V)
v_upscale   = [1.02, 1.38, 1.81, 2.21, 2.62, 3.01, 3.40, 3.79, 4.18, 4.60, 4.98]'; % Loading
v_downscale = [1.05, 1.41, 1.84, 2.24, 2.65, 3.03, 3.42, 3.81, 4.20, 4.61, 5.00]'; % Unloading

v_avg = (v_upscale + v_downscale) / 2.0;

fsr_voltage = 4.0; % Full Scale Range (1V to 5V = 4V)
fsr_level   = 100.0; % 0 to 100 cm

%% 2. Setup Normal Equations for Least-Squares Linear Fit: V = m*Level + c
N = length(true_level);
sum_x  = sum(true_level);
sum_y  = sum(v_avg);
sum_x2 = sum(true_level.^2);
sum_xy = sum(true_level .* v_avg);

% Normal matrix equation [A] * [coeff] = [B]
A = [sum_x2, sum_x; 
     sum_x,  N];
B = [sum_xy; sum_y];

%% 3. Custom Gaussian Elimination with Partial Pivoting
coeff = gaussian_elimination_matlab(A, B);
m = coeff(1);
c = coeff(2);

%% 4. Error Metrics Calculation
v_fit = m * true_level + c;
residuals = v_avg - v_fit;

% Linearity Error (% FSR)
max_linearity_err = max(abs(residuals));
linearity_err_pct = (max_linearity_err / fsr_voltage) * 100;

% Hysteresis (% FSR)
max_hysteresis = max(abs(v_downscale - v_upscale));
hysteresis_pct = (max_hysteresis / fsr_voltage) * 100;

% Zero & Span Errors
zero_err = v_avg(1) - 1.00;
zero_err_pct = (zero_err / fsr_voltage) * 100;

measured_span = v_avg(end) - v_avg(1);
span_err = measured_span - 4.00;
span_err_pct = (span_err / 4.00) * 100;

% Goodness of Fit
ss_tot = sum((v_avg - mean(v_avg)).^2);
ss_res = sum(residuals.^2);
r_squared = 1 - (ss_res / ss_tot);
rmse = sqrt(mean(residuals.^2));

%% 5. Display Console Summary
fprintf('=====================================================\n');
fprintf(' ULTRASONIC LEVEL TRANSMITTER CALIBRATION (MATLAB)  \n');
fprintf('=====================================================\n');
fprintf(' Fitted Model          : V = %.5f * Level + %.5f\n', m, c);
fprintf(' Sensitivity           : %.5f V/cm (%.4f mA/cm)\n', m, m * 4);
fprintf(' Zero Error            : %+.4f V (%+.2f%% FSR)\n', zero_err, zero_err_pct);
fprintf(' Span Error            : %+.4f V (%+.2f%%)\n', span_err, span_err_pct);
fprintf(' Max Linearity Error   : %.4f V (%.2f%% FSR)\n', max_linearity_err, linearity_err_pct);
fprintf(' Max Hysteresis        : %.4f V (%.2f%% FSR)\n', max_hysteresis, hysteresis_pct);
fprintf(' RMSE                  : %.5f V\n', rmse);
fprintf(' R-squared (R^2)       : %.6f\n', r_squared);
fprintf('=====================================================\n');

%% 6. Plotting Calibration Curve
figure('Name', 'Ultrasonic Transmitter Calibration', 'Position', [100, 100, 1000, 450]);

subplot(1, 2, 1);
plot(true_level, 1.0 + 0.04*true_level, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Ideal Linear (1-5V)');
hold on;
plot(true_level, v_upscale, 'bo-', 'LineWidth', 1.2, 'DisplayName', 'Upscale (Loading)');
plot(true_level, v_downscale, 'ro--', 'LineWidth', 1.2, 'DisplayName', 'Downscale (Unloading)');
plot(true_level, v_fit, 'g-', 'LineWidth', 2, 'DisplayName', sprintf('Gauss Fit (y=%.4fx+%.3f)', m, c));
title('Calibration Curve & Hysteresis');
xlabel('True Level (cm)');
ylabel('Transmitter Output Voltage (V)');
grid on;
legend('Location', 'northwest');

subplot(1, 2, 2);
stem(true_level, residuals, 'b', 'filled', 'LineWidth', 1.5, 'DisplayName', 'Residual Error (V)');
hold on;
plot(true_level, v_downscale - v_upscale, 'm^--', 'LineWidth', 1.2, 'DisplayName', 'Hysteresis Error (V)');
yline(0, 'r--', 'Zero Reference');
title('Residuals & Hysteresis Error');
xlabel('True Level (cm)');
ylabel('Error (V)');
grid on;
legend('Location', 'northeast');

%% Gaussian Elimination Subfunction
function x = gaussian_elimination_matlab(A, B)
    M = [A, B];
    n = length(B);
    
    % Forward Elimination with Partial Pivoting
    for i = 1:n
        [~, max_idx] = max(abs(M(i:n, i)));
        pivot_row = max_idx + i - 1;
        if pivot_row ~= i
            M([i, pivot_row], :) = M([pivot_row, i], :); % Swap rows
        end
        
        for j = (i+1):n
            factor = M(j, i) / M(i, i);
            M(j, i:end) = M(j, i:end) - factor * M(i, i:end);
        end
    end
    
    % Back Substitution
    x = zeros(n, 1);
    for i = n:-1:1
        x(i) = (M(i, end) - M(i, (i+1):n) * x((i+1):n)) / M(i, i);
    end
end
=======
% ============================================================
% Ultrasonic Level Transmitter Calibration - MATLAB
% Method: Linear Fit via Gauss Elimination (Normal Equations)
% ============================================================
clear; clc; close all;

Distance = [28.5; 23.2; 18.1; 13.4; 8.0];   % HC-SR04 (cm)
Level_ref = [4.0; 9.5; 14.8; 19.2; 24.5];  % Ruler (cm)

fprintf('=============================================================\n');
fprintf(' ULTRASONIC LEVEL TRANSMITTER CALIBRATION (MATLAB)\n');
fprintf(' Method: Gauss Elimination on Normal Equations\n');
fprintf('=============================================================\n\n');

fprintf('1. Experimental Data:\n');
fprintf('   Point   Distance   Level_ref\n');
for i = 1:length(Distance)
    fprintf('   %d       %-8.1f   %.1f\n', i, Distance(i), Level_ref(i));
end

A = [ones(size(Distance))  Distance];
b = Level_ref;

ATA = A' * A;
ATb = A' * b;
coeffs = ATA \ ATb;          % Gauss Elimination

a0 = coeffs(1);
a1 = coeffs(2);

fprintf('\n2. Calibration Coefficients (Gauss Elimination):\n');
fprintf('   a0 = %.8f\n', a0);
fprintf('   a1 = %.8f\n', a1);
fprintf('\n   Level (cm) = %.4f + (%.6f) * Distance\n', a0, a1);

Level_fit = A * coeffs;
errors = Level_ref - Level_fit;
RMSE = sqrt(mean(errors.^2));

fprintf('\n3. Error Analysis:\n');
fprintf('   Dist    L_ref   L_fit    Error\n');
for i = 1:length(Distance)
    fprintf('   %-6.1f  %-6.1f  %-7.3f  %.3f\n', ...
        Distance(i), Level_ref(i), Level_fit(i), errors(i));
end
fprintf('\n   RMSE = %.4f cm\n', RMSE);

% Plot
figure;
plot(Distance, Level_ref, 'ro', 'MarkerSize', 10, 'LineWidth', 1.5); hold on;
d_fine = linspace(5, 32, 200);
plot(d_fine, a0 + a1*d_fine, 'b-', 'LineWidth', 2.5);
plot(Distance, 32.5 - Distance, 'g--x');
xlabel('Sensor Distance (cm)');
ylabel('Water Level (cm)');
title({'Ultrasonic Level Transmitter Calibration'; ...
       'Linear Fit via Gauss Elimination'});
legend('Experimental (Ruler)', 'Calibrated (Gauss)', 'Raw (32.5-Dist)', ...
       'Location', 'best');
grid on;
saveas(gcf, 'calibration_curve_matlab.png');

fprintf('\n>>> Done. Copy a0, a1 into Arduino sketch.\n');
fprintf('=============================================================\n');
>>>>>>> 79a392ae3a07bcecb962858f4711c69c548a4c4c
