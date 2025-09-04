% 固定theta和v，绘制t1-t2-dt的3D图像
clear; clc; close all;

%% 1. 参数设置
theta_fixed = 0;          % 固定theta值
v_fixed = 70.5;           % 固定v值
t1_range = linspace(0, 5, 50);  % t1在[0,5]取50个点（密度可调整）
t2_range = linspace(0, 5, 50);  % t2在[0,5]取50个点（密度可调整）
[X_t1, Y_t2] = meshgrid(t1_range, t2_range);  % 生成t1-t2网格
Z_dt = zeros(size(X_t1));  % 存储对应的dt值

%% 2. 计算每个(t1,t2)对应的dt值
for i = 1:size(X_t1, 1)
    for j = 1:size(X_t1, 2)
        t1_current = X_t1(i, j);  % 当前t1
        t2_current = Y_t2(i, j);  % 当前t2
        % 构造参数向量（theta和v固定，仅t1、t2变化）
        params_current = [theta_fixed, v_fixed, t1_current, t2_current];
        % 调用fitness_function计算dt
        Z_dt(i, j) = fitness_function(params_current);
    end
end

%% 3. 绘制3D曲面图
figure('Position', [100, 100, 1000, 800]);  % 设置图像窗口大小
surf(X_t1, Y_t2, Z_dt);  % 绘制3D曲面
shading interp;  % 插值着色（使曲面更平滑）
colormap(jet);   % 使用jet颜色映射（色彩过渡更丰富）
colorbar;        % 添加颜色条（标注dt值对应颜色）

%% 4. 图像美化与标注
xlabel('t1', 'FontSize', 12, 'FontWeight', 'bold');  % x轴（t1）标注
ylabel('t2', 'FontSize', 12, 'FontWeight', 'bold');  % y轴（t2）标注
zlabel('dt', 'FontSize', 12, 'FontWeight', 'bold');  % z轴（dt）标注
title({'固定theta=0、v=70.5时，t1-t2-dt的3D图像'; 't1∈[0,5], t2∈[0,5]'}, ...
    'FontSize', 14, 'FontWeight', 'bold');  % 标题（分行显示）
grid on;  % 显示网格
rotate3d on;  % 启用3D旋转（可拖动图像调整视角）

%% 5. 嵌入fitness_function（确保代码可独立运行）
function dt = fitness_function(params)
    theta = params(1);
    v = params(2);
    t1 = params(3);
    t2 = params(4);

    g = 9.8;
    tau = [cos(theta), sin(theta)];

    % 计算GRD_1坐标
    GRD_1 = [17800 + v * t1 * tau(1), v * t1 * tau(2), 1800];
    % 计算GRD_2坐标
    GRD_2 = [GRD_1(1) + v * t2 * tau(1), ...
             GRD_1(2) + v * t2 * tau(2), ...
             GRD_1(3) - 0.5 * g * t2^2];

    % 计算M_2坐标
    total_time = t1 + t2;
    M_2 = [20000 - (300 * total_time * 10) / sqrt(101), ...
           0, ...
           2000 - (300 * total_time) / sqrt(101)];

    % 提取坐标分量
    X1 = GRD_2(1); Y1 = GRD_2(2); Z1 = GRD_2(3);
    X2 = M_2(1);   Z2 = X2 / 10;

    % 计算二次方程系数
    alpha = 3000 / sqrt(101);
    beta = alpha / 10;
    a = alpha^2 + (beta - 3)^2;
    b = 2 * alpha * (X1 - X2) + 2 * (beta - 3) * (Z1 - Z2);
    c = (X1 - X2)^2 + Y1^2 + (Z1 - Z2)^2 - 10^2;

    % 计算判别式并求解dt
    discriminant = b^2 - 4 * a * c;
    if discriminant <= 0
        dt = 0;  % 无实根时dt取0
    else
        % 求解二次方程的两个根
        t_1 = (-b + sqrt(discriminant)) / (2 * a);
        t_2 = (-b - sqrt(discriminant)) / (2 * a);
        % 确保t1 <= t2
        if t_1 > t_2
            tmp = t_1; t_1 = t_2; t_2 = tmp;
        end
        % 应用t2<=20的约束
        if t_2 >= 20
            t_2 = 20;
        end
        % 计算dt（确保非负）
        dt = max(t_2 - t_1, 0);
    end
end