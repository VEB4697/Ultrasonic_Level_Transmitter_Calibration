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
