"""
level_calibration_gauss.py
==========================
Ultrasonic Level Transmitter Calibration
Gauss Elimination Method — Python Standalone Script

Project: Calibration of Ultrasonic Level Transmitter
         using Arduino UNO and Gauss Elimination Method
Course:  B.Tech ICE -- Numerical Methods (Semester 3)

Usage:
  python codes/level_calibration_gauss.py

Description:
  Implements Gauss Elimination with Partial Pivoting on
  Normal Equations to fit a linear calibration model:

      Level (cm) = a0 + a1 * Distance (cm)

  Error metrics computed:
    - RMSE (Root Mean Square Error)
    - R-squared (coefficient of determination)

  Outputs:
    - Console calibration report
    - Calibration curve plot (matplotlib)
    - Coefficients ready to paste into Arduino sketch
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec


# ---------------------------------------------------------------
# GAUSS ELIMINATION WITH PARTIAL PIVOTING
# ---------------------------------------------------------------
def gauss_elimination(A_in, b_in):
    """
    Solves A * x = b using Gauss Elimination with Partial Pivoting.

    Parameters
    ----------
    A_in : list[list[float]] or ndarray, shape (n, n)
    b_in : list[float]       or ndarray, shape (n,)

    Returns
    -------
    x : ndarray, shape (n,)  — solution vector
    """
    A = np.array(A_in, dtype=float)
    b = np.array(b_in, dtype=float)
    n = len(b)
    M = np.hstack([A, b.reshape(-1, 1)])   # Augmented matrix [A|b]

    # -- Forward Elimination with Partial Pivoting --
    for k in range(n - 1):
        # Find pivot row (maximum absolute value in column k)
        pivot = k + np.argmax(np.abs(M[k:, k]))
        if pivot != k:
            M[[k, pivot]] = M[[pivot, k]]   # Swap rows

        for i in range(k + 1, n):
            if np.isclose(M[k, k], 0):
                raise ValueError("Singular or near-singular matrix encountered.")
            factor = M[i, k] / M[k, k]
            M[i, k:] -= factor * M[k, k:]

    # -- Back Substitution --
    x = np.zeros(n)
    for i in range(n - 1, -1, -1):
        x[i] = (M[i, -1] - M[i, i+1:n] @ x[i+1:n]) / M[i, i]

    return x


# ---------------------------------------------------------------
# NORMAL EQUATIONS SETUP
# ---------------------------------------------------------------
def fit_linear_gauss(dist, level):
    """
    Fits  Level = a0 + a1 * Distance  using Normal Equations
    solved by Gauss Elimination.

    Normal Equations:
      [ n      sum(D)   ] [a0]   [sum(L)   ]
      [ sum(D) sum(D^2) ] [a1] = [sum(D*L) ]
    """
    n    = len(dist)
    sumD  = np.sum(dist)
    sumD2 = np.sum(dist ** 2)
    sumL  = np.sum(level)
    sumDL = np.sum(dist * level)

    A_mat = [[n,    sumD ],
             [sumD, sumD2]]
    b_vec = [sumL, sumDL]

    coeffs = gauss_elimination(A_mat, b_vec)
    a0, a1 = coeffs[0], coeffs[1]
    return a0, a1


# ---------------------------------------------------------------
# CALIBRATION ANALYSIS
# ---------------------------------------------------------------
def run_calibration():
    """
    Calibration data collected by placing tank at known reference
    levels (measured with a ruler) and recording HC-SR04 distance.

    Update the arrays below with YOUR experimental readings.
    Minimum 5 points; 7-10 points recommended.
    """
    # HC-SR04 raw distance readings (cm)
    dist_cm   = np.array([28.5, 23.2, 18.1, 13.4,  8.0], dtype=float)

    # True water level (ruler reference, cm)
    level_ref = np.array([ 4.0,  9.5, 14.8, 19.2, 24.5], dtype=float)

    n = len(dist_cm)

    # ---- Run Gauss Elimination ----
    a0, a1 = fit_linear_gauss(dist_cm, level_ref)

    level_fit = a0 + a1 * dist_cm
    errors    = level_ref - level_fit
    rmse      = np.sqrt(np.mean(errors ** 2))
    ss_tot    = np.sum((level_ref - level_ref.mean()) ** 2)
    r_squared = 1.0 - np.sum(errors ** 2) / ss_tot

    # ---- Console Report ----
    sep = '=' * 62
    print(sep)
    print('  ULTRASONIC LEVEL TRANSMITTER — GAUSS ELIMINATION REPORT')
    print(sep)
    print(f'\n  Calibration Model : Level = {a0:.6f} + ({a1:.6f}) * Distance')
    print(f'  RMSE              : {rmse:.4f} cm')
    print(f'  R-squared (R²)    : {r_squared:.6f}')
    print()
    print(f'  {"Pt":<4} {"Dist(cm)":<12} {"L_ref(cm)":<12} {"L_fit(cm)":<12} {"Error(cm)":<10}')
    print('  ' + '-' * 52)
    for i in range(n):
        print(f'  {i+1:<4} {dist_cm[i]:<12.2f} {level_ref[i]:<12.2f} '
              f'{level_fit[i]:<12.4f} {errors[i]:+.4f}')
    print()
    print('  >> Paste into Level_Calibration.ino:')
    print(f'     const float COEFF_A0 = {a0:.6f}f;')
    print(f'     const float COEFF_A1 = {a1:.6f}f;')
    print(sep)

    return dict(dist=dist_cm, level_ref=level_ref, level_fit=level_fit,
                errors=errors, a0=a0, a1=a1, rmse=rmse, r2=r_squared)


# ---------------------------------------------------------------
# PLOT
# ---------------------------------------------------------------
def plot_calibration(res):
    fig = plt.figure(figsize=(13, 5), dpi=130,
                     facecolor='#0a1020')
    gs  = gridspec.GridSpec(1, 2, wspace=0.35)

    ax1 = fig.add_subplot(gs[0])
    ax2 = fig.add_subplot(gs[1])

    for ax in (ax1, ax2):
        ax.set_facecolor('#0d1826')
        ax.tick_params(colors='#7a8aa0')
        for spine in ax.spines.values():
            spine.set_color('#1e3050')

    # ---- Subplot 1: Calibration Curve ----
    d_fine = np.linspace(min(res['dist']) * 0.9, max(res['dist']) * 1.1, 200)
    l_fine = res['a0'] + res['a1'] * d_fine

    ax1.scatter(res['dist'], res['level_ref'], s=80, color='#ffb300',
                zorder=5, label='Measured Points (Ruler)')
    ax1.plot(d_fine, l_fine, '-', color='#00e676', linewidth=2.2,
             label=f'Gauss Fit: L = {res["a0"]:.4f} + ({res["a1"]:.4f})·D')
    ax1.scatter(res['dist'], res['level_fit'], marker='x', s=60,
                color='#00d4ff', zorder=4, label='Fitted Values')

    ax1.set_title('Calibration Curve — Gauss Elimination', color='#00d4ff',
                  fontsize=12, fontweight='bold', pad=10)
    ax1.set_xlabel('HC-SR04 Distance (cm)', color='#7a8aa0', fontsize=10)
    ax1.set_ylabel('Water Level (cm)',       color='#7a8aa0', fontsize=10)
    ax1.grid(True, color='#1e3050', linestyle=':', alpha=0.8)
    ax1.legend(fontsize=9, facecolor='#0d1826', labelcolor='#c8d8e8',
               framealpha=0.9)

    # Text box
    txt = (f'a₀ = {res["a0"]:.6f}\n'
           f'a₁ = {res["a1"]:.6f}\n'
           f'RMSE = {res["rmse"]:.4f} cm\n'
           f'R² = {res["r2"]:.6f}')
    ax1.text(0.97, 0.05, txt, transform=ax1.transAxes, fontsize=8.5,
             verticalalignment='bottom', horizontalalignment='right',
             bbox=dict(boxstyle='round,pad=0.5', facecolor='#0a1828',
                       edgecolor='#00d4ff44', alpha=0.9),
             color='#c8d8e8', family='monospace')

    # ---- Subplot 2: Residual Errors ----
    colors = ['#ff4757' if e < 0 else '#00e676' for e in res['errors']]
    ax2.bar(range(1, len(res['dist']) + 1), res['errors'],
            color=colors, alpha=0.8, edgecolor='#1e3050')
    ax2.axhline(0, color='#7a8aa0', linewidth=1.2, linestyle='--')

    ax2.set_title('Residual Errors per Calibration Point', color='#00d4ff',
                  fontsize=12, fontweight='bold', pad=10)
    ax2.set_xlabel('Calibration Point #', color='#7a8aa0', fontsize=10)
    ax2.set_ylabel('Error (cm)',           color='#7a8aa0', fontsize=10)
    ax2.set_xticks(range(1, len(res['dist']) + 1))
    ax2.grid(True, axis='y', color='#1e3050', linestyle=':', alpha=0.8)

    fig.suptitle('Ultrasonic Level Transmitter — Gauss Elimination Calibration\n'
                 'B.Tech ICE Semester 3 | Numerical Methods Project',
                 color='#c8d8e8', fontsize=11, y=1.01)

    plt.tight_layout()
    plt.savefig('reports/calibration_curve.png', dpi=150,
                bbox_inches='tight', facecolor=fig.get_facecolor())
    print('\n[+] Plot saved to reports/calibration_curve.png')
    plt.show()


# ---------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------
if __name__ == '__main__':
    results = run_calibration()
    plot_calibration(results)
