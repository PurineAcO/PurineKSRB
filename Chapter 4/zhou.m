%% zhou.m
% 读取 merged_coefficients.txt 中的 CL/CD/CM 时程数据
% 使用 JSON 中新增的 Ma、U_inf（Re=3e6），展长固定 0.2 m
% （1）单时间点应力分析  （2）σ_r4,max—时间可视化  （3）全局最大相当应力

clear; clc;

%% ===== 1. 读取 JSON 参数 =====
try
    json_path = fullfile(fileparts(mfilename('fullpath')), 'input_params.json');
catch
    json_path = 'input_params.json';
end
fid = fopen(json_path, 'r');
raw = fread(fid, inf, 'uint8=>char')';
fclose(fid);
params = jsondecode(raw);

b     = params.b;          % 半弦长 [m]
rho   = params.rho;        % 空气密度 [kg/m³]
c     = 2 * b;             % 弦长 [m]
Ma    = params.Ma;         % 马赫数
U_inf = params.U_inf;      % 来流速度（Re=3e6 对应）[m/s]
span  = 0.2;               % 展长固定 [m]

%% ===== 2. 读取 merged_coefficients.txt =====
data = readmatrix('merged_coefficients.txt', 'FileType', 'text', 'NumHeaderLines', 4);
t_all = data(:, 1);    % 流动时间 [s]
CL_all = data(:, 2);
CD_all = data(:, 3);
CM_all = data(:, 4);
n_t = length(t_all);

%% ===== 3. 轴段参数 & 截面模量（常数）=====
d_1 = 100e-3;       % 轴段1直径 [m]
d_2 = 100e-3;       % 轴段2直径 [m]
l_1 = 0.2;          % 轴段1长度 [m]
l_2 = 0.2;          % 轴段2长度 [m]

W_p1 = pi * d_1^3 / 16;     % 抗扭截面模量 [m³]
W_p2 = pi * d_2^3 / 16;
W_1  = pi * d_1^3 / 32;     % 抗弯截面模量 [m³]
W_2  = pi * d_2^3 / 32;

%% ===== 4. 全时程应力计算（向量化）=====
S = span * c;                      % 机翼面积 [m²]
q = 0.5 * rho * U_inf^2;           % 动压 [Pa]

% 气动力
L_all = q * S * CL_all;
D_all = q * S * CD_all;
M_all = q * S * c * CM_all;

% 传动轴载荷
T_all = M_all;                                  % 扭矩
M_x_all = L_all * (span / 2);                   % 翼根 x弯矩
M_y_all = D_all * (span / 2);                   % 翼根 y弯矩

% 截面弯矩
M_x1_all = L_all * (span/2 + l_1/2);
M_y1_all = D_all * (span/2 + l_1/2);
M_x2_all = L_all * (span/2 + l_1 + l_2/2);
M_y2_all = D_all * (span/2 + l_1 + l_2/2);

% 截面应力
sigma_x1_all = M_x1_all / W_1;
sigma_y1_all = M_y1_all / W_1;
sigma_x2_all = M_x2_all / W_2;
sigma_y2_all = M_y2_all / W_2;
tau_1_all    = T_all / W_p1;
tau_2_all    = T_all / W_p2;

% 辅助角公式 → 最大等效应力
A_1_all = sqrt(sigma_x1_all.^2 + sigma_y1_all.^2);
A_2_all = sqrt(sigma_x2_all.^2 + sigma_y2_all.^2);

sigma_r4_max_1_all = sqrt(A_1_all.^2 + 3 * tau_1_all.^2) / 1e6;  % [MPa]
sigma_r4_max_2_all = sqrt(A_2_all.^2 + 3 * tau_2_all.^2) / 1e6;

% 最大应力对应角度
phi_1_all = atan2d(sigma_y1_all, sigma_x1_all);
phi_2_all = atan2d(sigma_y2_all, sigma_x2_all);
theta_max_1_all = 90 - phi_1_all;
theta_max_2_all = 90 - phi_2_all;

%% ===== 5. (1) 单时间点应力分析 (t = 0.5 s) =====
t_target = 0.5;
[~, idx_t] = min(abs(t_all - t_target));
t_sel = t_all(idx_t);

CL_sel = CL_all(idx_t);  CD_sel = CD_all(idx_t);  CM_sel = CM_all(idx_t);
L_sel  = q * S * CL_sel;
D_sel  = q * S * CD_sel;
M_sel  = q * S * c * CM_sel;

fprintf('============================================================\n');
fprintf('  (1) 单时间点应力分析: t = %.4f s\n', t_sel);
fprintf('============================================================\n');
fprintf('  CL=%.4f,  CD=%.4f,  CM=%.4f\n', CL_sel, CD_sel, CM_sel);
fprintf('  L=%.3f N, D=%.4f N, M=%.4f N·m\n', L_sel, D_sel, M_sel);
fprintf('------------------------------------------------------------\n');
fprintf('  截面1: sigma_{r4,max}=%.3f MPa  @ theta=%.1f deg\n', ...
    sigma_r4_max_1_all(idx_t), theta_max_1_all(idx_t));
fprintf('  截面2: sigma_{r4,max}=%.3f MPa  @ theta=%.1f deg\n', ...
    sigma_r4_max_2_all(idx_t), theta_max_2_all(idx_t));
fprintf('============================================================\n');

%% ===== 6. (2) 可视化: sigma_r4,max 随时间变化 =====
figure('Name', '最大等效应力-时间曲线', 'Position', [100, 100, 900, 400]);

plot(t_all, sigma_r4_max_1_all, 'b-', 'LineWidth', 1.2, ...
    'DisplayName', '截面1');
hold on;
plot(t_all, sigma_r4_max_2_all, 'r--', 'LineWidth', 1.2, ...
    'DisplayName', '截面2');
xlabel('流动时间 [s]', 'FontSize', 12);
ylabel('\sigma_{r4, max} [MPa]', 'FontSize', 12);
title('最大等效应力随时间变化', 'FontSize', 14);
legend('Location', 'best', 'FontSize', 11);
grid on;
saveas(gcf, 'sigma_r4_vs_time.png');
fprintf('\nFigure saved: sigma_r4_vs_time.png\n');

%% ===== 7. 绘图: 单点 theta-sigma 曲线 (t = 0.5 s) =====
theta = linspace(0, 2*pi, 360);
theta_deg = rad2deg(theta);

sigma_theta_1 = A_1_all(idx_t) * sin(theta + deg2rad(phi_1_all(idx_t)));
sigma_r4_1    = sqrt(sigma_theta_1.^2 + 3 * tau_1_all(idx_t)^2);
sigma_theta_2 = A_2_all(idx_t) * sin(theta + deg2rad(phi_2_all(idx_t)));
sigma_r4_2    = sqrt(sigma_theta_2.^2 + 3 * tau_2_all(idx_t)^2);

figure('Name', '圆轴边缘应力分布', 'Position', [100, 100, 900, 600]);
subplot(2, 1, 1);
plot(theta_deg, sigma_theta_1/1e6, 'b-', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('截面1 (tau=%.2f MPa)', tau_1_all(idx_t)/1e6));
hold on;
plot(theta_deg, sigma_theta_2/1e6, 'r--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('截面2 (tau=%.2f MPa)', tau_2_all(idx_t)/1e6));
yline(0, 'k-', 'LineWidth', 0.8, 'Alpha', 0.5);
xlabel('角度 \theta [°]', 'FontSize', 12);
ylabel('正应力 \sigma [MPa]', 'FontSize', 12);
title(sprintf('\\sigma(\\theta) @ t=%.4f s', t_sel), 'FontSize', 13);
legend('Location', 'best', 'FontSize', 10);
grid on;  xlim([0, 360]);

subplot(2, 1, 2);
plot(theta_deg, sigma_r4_1/1e6, 'b-', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('截面1  max=%.2f MPa', max(sigma_r4_1)/1e6));
hold on;
plot(theta_deg, sigma_r4_2/1e6, 'r--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('截面2  max=%.2f MPa', max(sigma_r4_2)/1e6));
xlabel('角度 \theta [°]', 'FontSize', 12);
ylabel('\sigma_{r4} [MPa]', 'FontSize', 12);
title('\sigma_{r4}(\theta) = \surd(\sigma^2 + 3\tau^2)', 'FontSize', 13);
legend('Location', 'best', 'FontSize', 10);
grid on;  xlim([0, 360]);

sgtitle(sprintf('圆轴边缘应力分布 (@ t=%.4f s)', t_sel), 'FontSize', 15);
saveas(gcf, 'stress_theta.png');
fprintf('Figure saved: stress_theta.png\n');

%% ===== 8. (3) 全局最大相当应力（时间+空间）=====
sigma_r4_combined = [sigma_r4_max_1_all; sigma_r4_max_2_all];
[global_max, global_idx] = max(sigma_r4_combined);

if global_idx <= n_t
    sec = 1;  time_idx = global_idx;
else
    sec = 2;  time_idx = global_idx - n_t;
end

fprintf('\n============================================================\n');
fprintf('  (3) 全局最大相当应力（时间+空间）\n');
fprintf('============================================================\n');
fprintf('  sigma_{r4, global max} = %.4f MPa\n', global_max);
fprintf('  所在截面: %d\n', sec);
fprintf('  对应时间: t = %.4f s\n', t_all(time_idx));
fprintf('  对应角度: theta = %.1f deg\n', ...
    iif(sec==1, theta_max_1_all(time_idx), theta_max_2_all(time_idx)));
fprintf('  对应 CL=%.4f, CD=%.4f, CM=%.4f\n', ...
    CL_all(time_idx), CD_all(time_idx), CM_all(time_idx));
fprintf('------------------------------------------------------------\n');
% 空间位置
if sec == 1
    x_pos = span/2 + l_1/2;
else
    x_pos = span/2 + l_1 + l_2/2;
end
theta_g = iif(sec==1, theta_max_1_all(time_idx), theta_max_2_all(time_idx));
% 判断方位
if theta_g < 45 || theta_g > 315
    side_str = '侧边(阻力方向)';
elseif theta_g < 135
    side_str = '顶部(升力正方向)';
elseif theta_g < 225
    side_str = '另一侧(-阻力方向)';
else
    side_str = '底部(升力负方向)';
end
fprintf('  空间位置:\n');
fprintf('    距翼根 x = %.2f m  (截面%d中心)\n', x_pos, sec);
fprintf('    周向 theta = %.1f deg  →  %s\n', theta_g, side_str);
fprintf('============================================================\n');

fprintf('\n===== Done =====\n');

%% ===== 辅助函数 =====
function val = iif(cond, v1, v2)
    if cond, val = v1; else, val = v2; end
end
