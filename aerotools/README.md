# aerotools

简易气动问题 MATLAB 工具箱.

---

## 目录

- [1.sodsolver.m — 一维 Sod 激波管求解器](#1-sodsolverm--一维-sod-激波管求解器)
  - [1.1 数学模型](#11-数学模型)
  - [1.2 数值方法](#12-数值方法)
  - [1.3 输出](#13-输出)
  - [1.4 文件结构](#14-文件结构)
- [2.ugsolver.m — U-g 法机翼颤振求解器](#2-ugsolverm--u-g-法机翼颤振求解器)
  - [2.1 数学模型](#21-数学模型)
  - [2.2 输入](#22-输入)
  - [2.3 输出](#23-输出)
  - [2.4 文件结构](#24-文件结构)
- [3.postprocess.m — CFD 后处理入口](#3-postprocessm--cfd-后处理入口)
  - [3.1 plot_CL — 升力系数时程图](#31-plot_cl--升力系数时程图)
- [4.依赖](#4-依赖)

---

## 1.sodsolver.m — 一维 Sod 激波管求解器

一维 Sod 激波管问题的 **Lax-Friedrichs** 格式求解器.求解可压缩 Euler 方程组,模拟激波管中初始间断的演化过程.

### 1.1 数学模型

求解一维 Euler 方程:

$$
\frac{\partial \mathbf{U}}{\partial t} + \frac{\partial \mathbf{F}}{\partial x} = 0
$$

其中守恒变量 $\mathbf{U} = [\rho,\ \rho u,\ E]^T$,通量 $\mathbf{F} = [\rho u,\ \rho u^2 + p,\ u(E+p)]^T$,气体状态方程 $p = (\gamma-1)\rho e$.

### 1.2 数值方法

- **离散方式**:均匀网格.
- **时空离散**:Lax-Friedrichs 格式

$$
\mathbf{U}_j^{n+1} = \frac{1}{2}\left(\mathbf{U}_{j-1}^n + \mathbf{U}_{j+1}^n\right) - \frac{\Delta t}{2\Delta x}\left(\mathbf{F}_{j+1}^n - \mathbf{F}_{j-1}^n\right)
$$

- **边界条件**:恒定边界（Dirichlet）
- **CFL 数**:$CFL = \frac{\Delta t}{\Delta x}$,其中 $\Delta t$ 为时间步长,$\Delta x$ 为空间步长.

### 1.3 输出

1. **热力图**:速度 $u$、密度 $\rho$、压力 $p$ 在 $x-t$ 平面上的分布
2. **末态快照**: t = 0.2 时刻的速度、密度、压力、内能沿 $x$ 分布曲线

### 1.4 文件结构

| 函数 | 说明 |
|------|------|
| `lax_freidrichs(U_curr, F_curr, gamma, a, Nx)` | 执行一步 Lax-Friedrichs 时间推进,返回 `U_next, rho_next, u_next, p_next, F_next` |

---

## 2.ugsolver.m — U-g 法机翼颤振求解器

基于 **U-g 法** 的二元机翼颤振求解器,支持 **展长灵敏度分析**.采用 Theodorsen 非定常气动力理论,通过特征值分析求解颤振速度和频率.

### 2.1 数学模型

二元机翼二自由度（沉浮/俯仰）运动方程:

$$
\mathbf{M}\ddot{\mathbf{q}} + \mathbf{K}\mathbf{q} = \frac{1}{2}\rho U_\infty^2 \mathbf{Q}(k) \mathbf{q}
$$

计算原理:

1. **Theodorsen 函数** $C(k) = F(k) + i G(k)$ 由 Bessel 函数计算
2. **气动力矩阵** $\mathbf{Q}_0(k)$ 由四项叠加构成（含 Theodorsen 函数及其导数项）
3. 对每个展长 $l$,扫描折合频率 $k$,求解广义特征值问题
4. 跟踪两支特征值分支（沉浮/俯仰）,检测 $g = 0$ 穿越点即为颤振点

### 2.2 输入

参数从 `input_params.json` 读取:

> 运行前需确保 `input_params.json` 存在于同一目录下.

| 参数 | 说明 |
|------|------|
| `b` | 半弦长 |
| `a` | 弹性轴位置（相对半弦长） |
| `m` | 单位展长质量 |
| `S` | 单位展长静矩 |
| `I_alpha` | 单位展长转动惯量 |
| `k_w` | 沉浮刚度 |
| `k_alpha` | 俯仰刚度 |
| `rho` | 空气密度 |
| `k_start / k_end / k_step` | 折合频率扫描范围与步长 |
| `span_list` | 展长列表 |
| `ref_span / ref_U` | 参考展长与参考颤振速度（用于对比验证） |

### 2.3 输出

1. **控制台输出**:各展长的颤振速度 $U_f$、折合频率 $k_f$、颤振频率 $f_f$
2. **数据文件** `ug_flutter_data.txt`:完整的 $U-g$ 坐标及颤振汇总
3. **图片**:
   - `ug_flutter_span.png`:颤振速度 vs 展长曲线（与参考值对比）
   - `ug_curves_divergent.png`:各展长下发散分支的 $U-g$ 曲线

### 2.4 文件结构

| 函数 | 说明 |
|------|------|
| `theodorsen(k)` | 计算 Theodorsen 函数 $C(k) = F(k) + iG(k)$ |
| `build_Q0(k, b, a, l)` | 构建气动力矩阵 $\mathbf{Q}_0(k)$ |
| `solve_single_k(k, b, a, l, M, K, rho)` | 求解单个折合频率下的特征值 |
| `scan_k_with_branches(k_array, b, a, l, M, K, rho)` | 扫描 $k$,跟踪两支特征值分支 |
| `find_flutter_from_branches(branches)` | 从分支数据检测 $g=0$ 穿越点 |
| `solve_span(l_span, k_array, b, a, M, K, rho)` | 对单个展长求解完整流程 |

---

## 3.postprocess.m — CFD 后处理

对 CFD 仿真结果进行后处理.主要适用于 *Buffet* 现象.

<!-- 请注意,修改postprocess.m 无需更新README.md文件 -->

---

## 4.依赖

- MATLAB (R2019b 或更高版本,需支持 `besselj`、`bessely`、`jsondecode` 等函数)
