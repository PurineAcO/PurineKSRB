%% ga_optimize.m
% 遗传算法优化传动轴尺寸 (d_1, d_2, l_1, l_2)
% 约束: σ_r4,max < 90 MPa, l_1+l_2=0.2 m, d<80 mm
% 目标: min (0.7*V_norm + 0.3*σ_norm)

clear; clc;

%% ===== 1. 读取全局数据（与设计变量无关的部分）=====
% JSON
try
    json_path = fullfile(fileparts(mfilename('fullpath')), 'input_params.json');
catch
    json_path = 'input_params.json';
end
fid = fopen(json_path, 'r');
raw = fread(fid, inf, 'uint8=>char')';
fclose(fid);
params = jsondecode(raw);

b     = params.b;
rho   = params.rho;
c     = 2 * b;
U_inf = params.U_inf;
span  = 0.2;

% CFD 时程系数
coeff_data = readmatrix('merged_coefficients.txt', 'FileType', 'text', 'NumHeaderLines', 4);
CL_all = coeff_data(:, 2);
CD_all = coeff_data(:, 3);
CM_all = coeff_data(:, 4);

% 与设计变量无关的常量
S_wing = span * c;
q_dyn  = 0.5 * rho * U_inf^2;
L_all = q_dyn * S_wing * CL_all;
D_all = q_dyn * S_wing * CD_all;
M_all = q_dyn * S_wing * c * CM_all;

%% ===== 2. GA 设置 =====
% 设计变量: [d_1, d_2, l_1],  l_2 = 0.2 - l_1
% 单位: m
lb = [0.010, 0.010, 0.02];    % 下限
ub = [0.080, 0.080, 0.18];    % 上限 (<80mm, l_1<0.2)

nvars = 3;

% 参考值（用于归一化）
V_ref  = pi * 0.1^2 * 0.2 + pi * 0.1^2 * 0.2;  % 初始设计体积 [m³]
sig_ref = 90e6;                                   % 约束上限 [Pa]

% GA 选项
opts = optimoptions('ga', ...
    'PopulationSize', 100, ...
    'MaxGenerations', 80, ...
    'Display', 'iter', ...
    'PlotFcn', @gaplotbestf, ...
    'UseParallel', false);

% 包装适应度函数，传入预计算数据
obj_fun = @(x) fitness_func(x, L_all, D_all, M_all, span, V_ref, sig_ref);

fprintf('============================================================\n');
fprintf('  遗传算法优化 — 传动轴尺寸\n');
fprintf('  设计变量: d_1, d_2, l_1  (l_2 = 0.2 - l_1)\n');
fprintf('  约束: sigma_r4,max < 90 MPa,  d < 80 mm\n');
fprintf('  目标: min (0.7*V/V0 + 0.3*sigma/90MPa)\n');
fprintf('============================================================\n');

%% ===== 3. 运行 GA =====
rng(42);  % 固定随机种子以便复现
[x_opt, fval_opt, exitflag, output] = ga(obj_fun, nvars, [], [], [], [], lb, ub, [], opts);

%% ===== 4. 结果输出 =====
d1_opt = x_opt(1);
d2_opt = x_opt(2);
l1_opt = x_opt(3);
l2_opt = 0.2 - l1_opt;

V_opt  = pi * d1_opt^2 * l1_opt + pi * d2_opt^2 * l2_opt;
sig_opt = compute_global_sigma(d1_opt, d2_opt, l1_opt, l2_opt, L_all, D_all, M_all, span);

fprintf('\n');
fprintf('============================================================\n');
fprintf('  优化结果\n');
fprintf('============================================================\n');
fprintf('  设计变量:\n');
fprintf('    d_1 = %.2f mm\n', d1_opt*1e3);
fprintf('    d_2 = %.2f mm\n', d2_opt*1e3);
fprintf('    l_1 = %.3f m\n', l1_opt);
fprintf('    l_2 = %.3f m  (= 0.2 - l_1)\n', l2_opt);
fprintf('------------------------------------------------------------\n');
fprintf('  目标:\n');
fprintf('    体积 V      = %.4e m³  (初始: %.4e m³, 减少 %.1f%%)\n', ...
    V_opt, V_ref, (1 - V_opt/V_ref)*100);
fprintf('    全局 max σ  = %.2f MPa  (约束: < 90 MPa)\n', sig_opt/1e6);
fprintf('------------------------------------------------------------\n');
fprintf('  约束检查:\n');
fprintf('    σ < 90 MPa:  %s\n', iif(sig_opt < 90e6, '✓ 满足', '✗ 违反'));
fprintf('    l_1+l_2=0.2:  %s  (%.4f)\n', iif(abs(l1_opt+l2_opt-0.2)<1e-9, '✓ 满足', '✗ 违反'), l1_opt+l2_opt);
fprintf('    d_1 < 80 mm:  %s  (%.1f mm)\n', iif(d1_opt<0.08, '✓ 满足', '✗ 违反'), d1_opt*1e3);
fprintf('    d_2 < 80 mm:  %s  (%.1f mm)\n', iif(d2_opt<0.08, '✓ 满足', '✗ 违反'), d2_opt*1e3);
fprintf('============================================================\n');

% 与初始设计对比
d1_0 = 0.100;  d2_0 = 0.100;  l1_0 = 0.2;  l2_0 = 0.2;
V_0  = pi * d1_0^2 * l1_0 + pi * d2_0^2 * l2_0;
sig_0 = compute_global_sigma(d1_0, d2_0, l1_0, l2_0, L_all, D_all, M_all, span);

fprintf('\n============================================================\n');
fprintf('  与初始设计对比\n');
fprintf('============================================================\n');
fprintf('  %12s  %8s  %8s  %10s  %10s\n', 'd_1[mm]', 'd_2[mm]', 'l_1[m]', 'V[m³]', 'σ[MPa]');
fprintf('  --------------------------------------------------\n');
fprintf('  初始:  %8.1f  %8.1f  %8.2f  %10.4e  %10.2f\n', ...
    d1_0*1e3, d2_0*1e3, l1_0, V_0, sig_0/1e6);
fprintf('  优化:  %8.1f  %8.1f  %8.2f  %10.4e  %10.2f\n', ...
    d1_opt*1e3, d2_opt*1e3, l1_opt, V_opt, sig_opt/1e6);
fprintf('============================================================\n');

% 保存最优参数供后续绘图使用
opt_params = struct('d1', d1_opt, 'd2', d2_opt, 'l1', l1_opt, 'l2', l2_opt);
fid = fopen('opt_params.json', 'w');
fprintf(fid, '%s', jsonencode(opt_params));
fclose(fid);
fprintf('最优参数已保存: opt_params.json\n');

fprintf('\n===== Done =====\n');


%% ===== 适应度函数 =====
function f = fitness_func(x, L_all, D_all, M_all, span, V_ref, sig_ref)
    d1 = x(1);  d2 = x(2);  l1 = x(3);
    l2 = 0.2 - l1;

    % 体积
    V = pi * d1^2 * l1 + pi * d2^2 * l2;

    % 全局最大相当应力 [Pa]
    sig = compute_global_sigma(d1, d2, l1, l2, L_all, D_all, M_all, span);

    % 归一化 + 加权 (7:3)
    f = 0.7 * (V / V_ref) + 0.3 * (sig / sig_ref);

    % 约束惩罚: σ > 90 MPa 或 l2 <= 0
    if sig > sig_ref || l2 <= 0
        f = f + 100;   % 大惩罚
    end
end

%% ===== 全局最大应力计算 =====
function sig_max = compute_global_sigma(d1, d2, l1, l2, L_all, D_all, M_all, span)
    % 截面模量
    W_p1 = pi * d1^3 / 16;
    W_p2 = pi * d2^3 / 16;
    W_1  = pi * d1^3 / 32;
    W_2  = pi * d2^3 / 32;

    % 截面弯矩
    M_x1 = L_all * (span/2 + l1/2);
    M_y1 = D_all * (span/2 + l1/2);
    M_x2 = L_all * (span/2 + l1 + l2/2);
    M_y2 = D_all * (span/2 + l1 + l2/2);

    % 截面应力
    sig_x1 = M_x1 / W_1;   sig_y1 = M_y1 / W_1;
    sig_x2 = M_x2 / W_2;   sig_y2 = M_y2 / W_2;
    tau_1  = M_all / W_p1;
    tau_2  = M_all / W_p2;

    % 辅助角 → 最大等效应力
    A1 = sqrt(sig_x1.^2 + sig_y1.^2);
    A2 = sqrt(sig_x2.^2 + sig_y2.^2);
    sig_r4_1 = sqrt(A1.^2 + 3 * tau_1.^2);
    sig_r4_2 = sqrt(A2.^2 + 3 * tau_2.^2);

    % 全局最大值 [Pa]
    sig_max = max([sig_r4_1; sig_r4_2]);
end

%% ===== 辅助函数 =====
function val = iif(cond, v1, v2)
    if cond, val = v1; else, val = v2; end
end
