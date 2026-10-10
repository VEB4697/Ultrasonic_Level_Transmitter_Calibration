"""
Ultrasonic Level Transmitter Calibration & Gaussian Elimination Curve Fitting
Author: B.Tech ICE S.Y. Project Team
File: codes/level_calibration_gauss.py

Description:
  This script performs calibration analysis on experimental data collected from an 
  Ultrasonic Level Transmitter system. It utilizes Gaussian Elimination (with Partial Pivoting)
  to solve normal equations for least-squares linear and polynomial curve fitting.
  
Key Calibration Parameters Analyzed:
  - Zero Error and Span Error
  - Sensitivity (V/cm and mA/cm)
  - Linearity Error (% Full Scale Range)
  - Hysteresis Loop Analysis (Upscale vs Downscale)
  - Root Mean Square Error (RMSE) and R-squared coefficient (R²)
"""

import numpy as np
import matplotlib.pyplot as plt


def gaussian_elimination(A_in, B_in):
    """
    Solves linear system A * x = B using Gaussian Elimination with Partial Pivoting.
    
    Parameters:
        A_in (list of lists or 2D array): Coefficient matrix (n x n)
        B_in (list or 1D array): Right hand side vector (n)
        
    Returns:
        x (numpy array): Solution vector (n)
    """
    A = np.array(A_in, dtype=float).copy()
    B = np.array(B_in, dtype=float).copy()
    n = len(B)

    # Augmented matrix [A | B]
    M = np.hstack([A, B.reshape(-1, 1)])

    # Forward Elimination with Partial Pivoting
    for i in range(n):
        # Pivot selection: find row with max pivot element
        max_row = i + np.argmax(np.abs(M[i:, i]))
        if max_row != i:
            M[[i, max_row]] = M[[max_row, i]]  # Swap rows

        pivot = M[i, i]
        if np.isclose(pivot, 0):
            raise ValueError(f"Matrix is singular or near-singular at pivot {i}.")

        # Eliminate elements below pivot
        for j in range(i + 1, n):
            factor = M[j, i] / pivot
            M[j, i:] -= factor * M[i, i:]

    # Back Substitution
    x = np.zeros(n)
    for i in range(n - 1, -1, -1):
        x[i] = (M[i, -1] - np.dot(M[i, i + 1:n], x[i + 1:n])) / M[i, i]

    return x


def fit_linear_gaussian(x, y):
    """
    Fits y = a1 * x + a0 using Gaussian Elimination on normal equations:
      [ sum(x^2)   sum(x) ] [ a1 ] = [ sum(x*y) ]
      [ sum(x)     N      ] [ a0 ]   [ sum(y)   ]
    """
    N = len(x)
    sum_x = np.sum(x)
    sum_y = np.sum(y)
    sum_x2 = np.sum(x**2)
    sum_xy = np.sum(x * y)

    A = [[sum_x2, sum_x],
         [sum_x, N]]
    B = [sum_xy, sum_y]

    sol = gaussian_elimination(A, B)
    a1, a0 = sol[0], sol[1]
    return a1, a0


def run_calibration_analysis():
    """
    Performs complete ultrasonic transmitter calibration analysis.
    """
    # ---------------------------------------------------------
    # Experimental Calibration Data (Tank Height = 100 cm)
    # ---------------------------------------------------------
    true_level = np.array([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100], dtype=float)  # cm
    
    # Measured Transmitter Voltage Output (1.0 V to 5.0 V nominal FSR)
    v_upscale   = np.array([1.02, 1.38, 1.81, 2.21, 2.62, 3.01, 3.40, 3.79, 4.18, 4.60, 4.98]) # Loading
    v_downscale = np.array([1.05, 1.41, 1.84, 2.24, 2.65, 3.03, 3.42, 3.81, 4.20, 4.61, 5.00]) # Unloading

    # Average measured voltage
    v_avg = (v_upscale + v_downscale) / 2.0
    
    # FSR = Full Scale Range (V_max - V_min nominal = 4.0 V)
    fsr_voltage = 4.0  # V (1V to 5V)
    fsr_level = 100.0  # cm (0cm to 100cm)

    # 1. Fit linear model using Gaussian Elimination: V = m * Level + c
    m, c = fit_linear_gaussian(true_level, v_avg)

    # 2. Calibrated level prediction from measured voltage: Level_pred = (V - c) / m
    level_pred_up = (v_upscale - c) / m
    level_pred_down = (v_downscale - c) / m
    level_pred_avg = (v_avg - c) / m

    # 3. Ideal Response: V_ideal = 1.0 + 0.04 * Level
    v_ideal = 1.0 + 0.04 * true_level

    # 4. Error Calculations
    residuals_v = v_avg - (m * true_level + c)
    linearity_err_v = np.max(np.abs(residuals_v))
    linearity_err_pct = (linearity_err_v / fsr_voltage) * 100.0

    # Hysteresis = Max Difference between Upscale & Downscale readings
    hysteresis_v = np.max(np.abs(v_downscale - v_upscale))
    hysteresis_pct = (hysteresis_v / fsr_voltage) * 100.0

    # Zero Error (at Level = 0 cm)
    zero_error_v = v_avg[0] - 1.00
    zero_error_pct = (zero_error_v / fsr_voltage) * 100.0

    # Span Error (Measured Span - Ideal Span)
    measured_span = v_avg[-1] - v_avg[0]
    ideal_span = 4.00
    span_error_v = measured_span - ideal_span
    span_error_pct = (span_error_v / ideal_span) * 100.0

    # Sensitivity
    sensitivity_v_per_cm = m  # V/cm
    sensitivity_ma_per_cm = m * 4.0  # 4mA/V for 4-20mA standard

    # Goodness of fit (R-squared)
    ss_tot = np.sum((v_avg - np.mean(v_avg))**2)
    ss_res = np.sum(residuals_v**2)
    r_squared = 1.0 - (ss_res / ss_tot)
    rmse = np.sqrt(np.mean((v_avg - (m * true_level + c))**2))

    # Print Formatted Report Summary
    print("=" * 65)
    print(" ULTRASONIC LEVEL TRANSMITTER CALIBRATION REPORT ")
    print(" (Gaussian Elimination Least-Squares Analysis) ")
    print("=" * 65)
    print(f" Calibration Model      : V_out = ({m:.5f}) * Level + ({c:.5f})")
    print(f" Sensitivity            : {sensitivity_v_per_cm:.5f} V/cm  ({sensitivity_ma_per_cm:.4f} mA/cm)")
    print(f" Zero Error             : {zero_error_v:+.4f} V ({zero_error_pct:+.2f}% FSR)")
    print(f" Span Error             : {span_error_v:+.4f} V ({span_error_pct:+.2f}%)")
    print(f" Max Linearity Error    : {linearity_err_v:.4f} V ({linearity_err_pct:.2f}% FSR)")
    print(f" Max Hysteresis         : {hysteresis_v:.4f} V ({hysteresis_pct:.2f}% FSR)")
    print(f" RMSE                   : {rmse:.5f} V")
    print(f" R-squared (R²)         : {r_squared:.6f}")
    print("=" * 65)

    results = {
        "true_level": true_level,
        "v_upscale": v_upscale,
        "v_downscale": v_downscale,
        "v_avg": v_avg,
        "v_ideal": v_ideal,
        "m": m,
        "c": c,
        "sensitivity": sensitivity_v_per_cm,
        "zero_error_pct": zero_error_pct,
        "span_error_pct": span_error_pct,
        "linearity_err_pct": linearity_err_pct,
        "hysteresis_pct": hysteresis_pct,
        "r_squared": r_squared,
        "rmse": rmse
    }
    return results


def plot_calibration(results, save_path=None):
    """
    Plots high-resolution calibration curves and error metrics.
    """
    true_level = results["true_level"]
    v_upscale = results["v_upscale"]
    v_downscale = results["v_downscale"]
    v_avg = results["v_avg"]
    v_ideal = results["v_ideal"]
    m, c = results["m"], results["c"]

    fig, axes = plt.subplots(1, 2, figsize=(13, 5.5), dpi=300)

    # Subplot 1: Calibration Curve & Hysteresis
    ax1 = axes[0]
    ax1.plot(true_level, v_ideal, 'k--', label='Ideal Linear (1-5V)', linewidth=1.8)
    ax1.plot(true_level, v_upscale, 'bo-', label='Upscale (Loading)', markersize=6)
    ax1.plot(true_level, v_downscale, 'ro--', label='Downscale (Unloading)', markersize=6)
    ax1.plot(true_level, m * true_level + c, 'g-', label=f'Gaussian Fit (y={m:.4f}x+{c:.3f})', linewidth=2)
    
    ax1.set_title("Ultrasonic Transmitter Calibration Curve", fontsize=12, fontweight='bold')
    ax1.set_xlabel("True Liquid Level (cm)", fontsize=11)
    ax1.set_ylabel("Transmitter Output (Volts)", fontsize=11)
    ax1.grid(True, linestyle=':', alpha=0.7)
    ax1.legend(loc='upper left', fontsize=9)

    # Subplot 2: Linearity Residuals & Error Band
    ax2 = axes[1]
    residuals = v_avg - (m * true_level + c)
    ax2.axhline(0, color='red', linestyle='--', linewidth=1.5, label='Zero Error Reference')
    ax2.stem(true_level, residuals, linefmt='b-', markerfmt='bo', basefmt=" ", label='Residual Error (V)')
    ax2.plot(true_level, v_downscale - v_upscale, 'm^--', label='Hysteresis Error (V)')
    
    ax2.set_title("Calibration Residuals & Hysteresis Error", fontsize=12, fontweight='bold')
    ax2.set_xlabel("True Liquid Level (cm)", fontsize=11)
    ax2.set_ylabel("Error Deviation (Volts)", fontsize=11)
    ax2.grid(True, linestyle=':', alpha=0.7)
    ax2.legend(loc='upper right', fontsize=9)

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, bbox_inches='tight')
        print(f"[+] Calibration plot successfully saved to: {save_path}")
    else:
        plt.show()
    plt.close()


if __name__ == "__main__":
    res = run_calibration_analysis()
    plot_calibration(res, save_path=None)
