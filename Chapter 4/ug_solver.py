"""
U-g 法机翼颤振求解 —— 展长敏感性分析（单文件版）
求解顺序：参数 → Theodorsen → Q₀ → 特征值 → U-g 扫描 → 颤振判定 → 可视化
"""
import numpy as np
from scipy.special import j0, j1, y0, y1
import matplotlib.pyplot as plt

# ============================================================
# 1. 参数
# ============================================================
b, a = 0.1, -0.5
m, S, I_alpha = 1.85, 0.0309, 3.142e-3
k_w, k_alpha = 2542.0, 2.512
rho = 1.225

M = np.array([[m, S], [S, I_alpha]])
K = np.array([[k_w, 0.0], [0.0, k_alpha]])

k_array = np.arange(0.02, 3.0 + 0.005, 0.005)

# ============================================================
# 2. Theodorsen 函数 C(k) = F(k) + i G(k)
# ============================================================
def theodorsen(k):
    J0, J1 = j0(k), j1(k)
    Y0, Y1 = y0(k), y1(k)
    denom = (J1 + Y0)**2 + (J0 - Y1)**2
    F = (J1**2 + Y1**2 + J1*Y0 - J0*Y1) / denom
    G = -(J0*J1 + Y0*Y1) / denom
    return complex(F, G)

# ============================================================
# 3. 气动力矩阵 Q₀(k) —— 四项叠加
# ============================================================
def build_Q0(k, b, a, l):
    Ck = theodorsen(k)
    pi = np.pi

    T1 = Ck * l * np.array([
        [0.0, -4*pi*b],
        [0.0,  4*pi*b**2 * (a + 0.5)]
    ])

    T2 = 1j * k * l * np.array([
        [0.0, -2*pi*b],
        [0.0, -2*pi*b**2 * (0.5 - a)]
    ])

    T3 = 1j * k * l * Ck * np.array([
        [-4*pi,              -4*pi*b * (0.5 - a)],
        [4*pi*b * (a + 0.5), 4*pi*b**2 * (a + 0.5) * (0.5 - a)]
    ])

    T4 = k**2 * l * np.array([
        [2*pi,          -2*pi*b*a],
        [-2*pi*b*a,  2*pi*b**2 * (1/8 + a**2)]
    ])

    return T1 + T2 + T3 + T4

# ============================================================
# 4. U-g 特征值求解
# ============================================================
def solve_single_k(k, b, a, l, M, K, rho):
    Q0 = build_Q0(k, b, a, l)
    A = M * (k / b)**2 + (rho / 2.0) * Q0
    B_inv_A = np.array([
        [A[0, 0] / K[0, 0], A[0, 1] / K[0, 0]],
        [A[1, 0] / K[1, 1], A[1, 1] / K[1, 1]]
    ])
    return np.linalg.eigvals(B_inv_A)


def scan_k_with_branches(k_array, b, a, l, M, K, rho):
    prev_lambdas = None
    branches = [[], []]

    for k in k_array:
        lambdas = solve_single_k(k, b, a, l, M, K, rho)

        if prev_lambdas is None:
            idx = np.argsort([lam.real for lam in lambdas])[::-1]
            for bi, li in enumerate(idx):
                lam = lambdas[li]
                if lam.real > 1e-12:
                    branches[bi].append((k, lam.imag/lam.real, 1.0/np.sqrt(lam.real)))
            prev_lambdas = [lambdas[i] for i in idx]
        else:
            assigned = [False, False]
            new_order = [None, None]
            for lam_new in lambdas:
                dists = [abs(lam_new - old) for old in prev_lambdas]
                for cand in np.argsort(dists):
                    if not assigned[cand]:
                        assigned[cand] = True
                        new_order[cand] = lam_new
                        break
            for bi in range(2):
                lam = new_order[bi]
                if lam is not None and lam.real > 1e-12:
                    branches[bi].append((k, lam.imag/lam.real, 1.0/np.sqrt(lam.real)))
                elif lam is not None:
                    branches[bi].append((k, np.nan, np.nan))
            prev_lambdas = new_order

    return branches


def find_flutter_from_branches(branches):
    flutter_pts = []
    labels = ['分支1(偏沉浮)', '分支2(偏俯仰)']
    for bi, branch in enumerate(branches):
        valid = [(k, g, U) for k, g, U in branch if not (np.isnan(g) or np.isnan(U))]
        valid.sort(key=lambda x: x[0])
        for i in range(len(valid) - 1):
            k_i, g_i, U_i = valid[i]
            k_j, g_j, U_j = valid[i + 1]
            if g_i * g_j < 0:
                t = -g_i / (g_j - g_i)
                U_f = U_i + t * (U_j - U_i)
                k_f = k_i + t * (k_j - k_i)
                flutter_pts.append((U_f, k_f, labels[bi]))
    return flutter_pts


def solve_span(l_span):
    """对单个展长求解，返回 (branches, flutter_pts)"""
    branches = scan_k_with_branches(k_array, b, a, l_span, M, K, rho)
    flutter_pts = find_flutter_from_branches(branches)
    return branches, flutter_pts


# ============================================================
# 5. 主程序：展长遍历 + 双图可视化
# ============================================================
def main():
    span_list = [0.1, 0.2, 0.3, 0.4, 0.5]
    REF = {0.1: 27.8, 0.2: 19.6, 0.3: 15.6, 0.4: 13.1, 0.5: 11.5}
    all_data = {}  # l → (branches, flutter_pts)

    print("=" * 60)
    print("  U-g 法颤振求解 —— 展长敏感性分析")
    print(f"  b={b}, a={a}, ρ={rho}")
    print(f"  k ∈ [{k_array[0]}, {k_array[-1]}], Δk={k_array[1]-k_array[0]:.4f}")
    print("=" * 60)

    for l_val in span_list:
        print(f"\n--- l = {l_val:.1f} m ---")
        branches, pts = solve_span(l_val)
        all_data[l_val] = (branches, pts)
        if pts:
            for Uf, kf, label in pts:
                print(f"  颤振点: U_f = {Uf:.2f} m/s  (k = {kf:.4f}, {label})")
        else:
            print("  未检测到 g=0 穿越")

    print("\n" + "=" * 60)
    print(f"{'展长 [m]':>8}  {'计算 [m/s]':>12}  {'文献 [m/s]':>12}  {'误差':>8}")
    print("-" * 48)
    l_vals, U_vals = [], []
    for l_val in span_list:
        _, pts = all_data[l_val]
        if pts:
            Uf = min(p[0] for p in pts)
            l_vals.append(l_val); U_vals.append(Uf)
            err = (Uf - REF[l_val]) / REF[l_val] * 100
            print(f"{l_val:>8.1f}  {Uf:>12.2f}  {REF[l_val]:>12.1f}  {err:>+7.1f}%")
    print("=" * 60)

    # ---- 输出数据到 txt ----
    with open('ug_flutter_data.txt', 'w', encoding='utf-8') as f:
        f.write("U-g 法机翼颤振求解 —— 数据输出\n")
        f.write(f"b={b}, a={a}, ρ={rho}, k∈[{k_array[0]},{k_array[-1]}], Δk={k_array[1]-k_array[0]:.4f}\n")
        f.write("=" * 70 + "\n\n")

        f.write("第一部分：各展长下的 U, g 坐标\n")
        f.write("-" * 70 + "\n")
        for l_val in span_list:
            branches, _ = all_data[l_val]
            f.write(f"\n展长 l = {l_val:.1f} m\n")
            for bi, label in enumerate(['沉浮分支', '俯仰分支']):
                valid = [(k, g, U) for k, g, U in branches[bi]
                         if not (np.isnan(g) or np.isnan(U))]
                valid.sort(key=lambda x: x[0])
                f.write(f"  [{label}]  k          g          U [m/s]\n")
                for k, g, U in valid:
                    f.write(f"  {k:.5f}  {g:+.6f}  {U:.4f}\n")

        f.write("\n\n第二部分：各展长下的颤振速度\n")
        f.write("-" * 70 + "\n")
        f.write(f"{'展长 [m]':>10}  {'U_f [m/s]':>12}  {'k_f':>10}  {'文献 [m/s]':>12}  {'误差':>8}\n")
        f.write("-" * 58 + "\n")
        for l_val in span_list:
            _, pts = all_data[l_val]
            if pts:
                Uf = min(p[0] for p in pts)
                kf = [p[1] for p in pts if abs(p[0]-Uf)<0.01][0]
                err = (Uf - REF[l_val]) / REF[l_val] * 100
                f.write(f"{l_val:>10.1f}  {Uf:>12.3f}  {kf:>10.4f}  {REF[l_val]:>12.1f}  {err:>+7.1f}%\n")
        f.write("-" * 58 + "\n")

    print("数据已输出: ug_flutter_data.txt")

    plt.rcParams["font.sans-serif"] = ["SimHei"]
    plt.rcParams["axes.unicode_minus"] = False

    # ---- 图 1：U_f vs l 汇总 ----
    fig1, ax1 = plt.subplots(figsize=(9, 6))
    ax1.plot(l_vals, U_vals, 'o-', color='#1f77b4', lw=2, ms=8, label='U-g 法计算')
    l_ref = sorted(REF)
    ax1.plot(l_ref, [REF[l] for l in l_ref], 's--', color='#d62728', lw=2, ms=8, label='文献参考')
    for lv, uv in zip(l_vals, U_vals):
        ax1.annotate(f'{uv:.1f}', (lv, uv), xytext=(0, -18), textcoords='offset points', ha='center', fontsize=9, color='#1f77b4')
    for lv in l_ref:
        ax1.annotate(f'{REF[lv]:.1f}', (lv, REF[lv]), xytext=(0, 10), textcoords='offset points', ha='center', fontsize=9, color='#d62728')
    ax1.set_xlabel('机翼展长 $l$ [m]', fontsize=13)
    ax1.set_ylabel('颤振速度 $U_f$ [m/s]', fontsize=13)
    ax1.set_title(f'展长对颤振速度的影响 ($b={b}$ m, $a={a}$, ρ={rho} kg/m$^3$)', fontsize=14)
    ax1.legend(fontsize=11)
    ax1.grid(alpha=0.3)
    fig1.tight_layout()
    fig1.savefig('ug_flutter_span.png', dpi=150)
    print("\n图片已保存: ug_flutter_span.png")

    # ---- 图 2：各展长 U-g 曲线 ----
    fig2, axes = plt.subplots(2, 3, figsize=(16, 11))
    axes = axes.flatten()
    colors = ['#1f77b4', '#d62728']

    for idx, l_val in enumerate(span_list):
        ax = axes[idx]
        branches, pts = all_data[l_val]

        for bi, branch in enumerate(branches):
            valid = [(k, g, U) for k, g, U in branch if not (np.isnan(g) or np.isnan(U))]
            valid.sort(key=lambda x: x[0])
            if valid:
                U_arr = [v[2] for v in valid]
                g_arr = [v[1] for v in valid]
                ax.plot(U_arr, g_arr, '-', color=colors[bi], lw=1.2, label=['沉浮', '俯仰'][bi])

        ax.axhline(y=0, color='black', lw=0.8, ls='--', alpha=0.5)
        for Uf, kf, label in pts:
            ax.axvline(x=Uf, color='green', lw=1, ls=':', alpha=0.7)
            ax.plot(Uf, 0, 'go', ms=6, mfc='none', mew=2)

        ax.set_title(f'$l$ = {l_val:.1f} m', fontsize=12)
        ax.set_xlabel('$U_\\infty$ [m/s]', fontsize=10)
        ax.set_ylabel('$g$', fontsize=10)
        ax.legend(fontsize=8)
        ax.grid(alpha=0.3)

    # 隐藏第 6 个子图
    axes[5].set_visible(False)
    fig2.suptitle('各展长下的 U-g 曲线', fontsize=15, y=1.01)
    fig2.tight_layout()
    fig2.savefig('ug_curves_all_spans.png', dpi=150)
    print("图片已保存: ug_curves_all_spans.png")
    plt.show()


if __name__ == '__main__':
    main()
