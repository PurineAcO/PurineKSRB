clear; clc; close all;

% ==========================================================
% 第一阶段：全局搜索
% ==========================================================
fprintf('=== 第一阶段：全局搜索 ===\n');
nvars = 4;  % 参数数量: theta, v, t1, t2
lb_global = [0, 70, 0, 0];
ub_global = [2*pi, 140, 100, 100];

options_global = optimoptions('ga', ...
    'PopulationSize', 5000, ...
    'MaxGenerations', 200, ...
    'CrossoverFraction', 0.8, ...
    'EliteCount', 35, ...
    'Display', 'iter', ...
    'PlotFcn', @gaplotbestf);

[best_params_global, best_dt_global] = ga(@(x) -fitness_function(x), ...
    nvars, [], [], [], [], lb_global, ub_global, [], options_global);

% ==========================================================
% 第二阶段：局部搜索
% ==========================================================
fprintf('\n=== 第二阶段：局部精细优化 ===\n');

% 为不同参数设置不同的收缩比例
theta_range = 0.05 * (ub_global(1) - lb_global(1));
v_range     = 0.03 * (ub_global(2) - lb_global(2));
t1_range    = 0.1  * (ub_global(3) - lb_global(3));
t2_range    = 0.1  * (ub_global(4) - lb_global(4));

% 新的参数范围（围绕第一阶段的最优解）
lb_local = [
    max(lb_global(1), best_params_global(1) - theta_range), ...
    max(lb_global(2), best_params_global(2) - v_range), ...
    max(lb_global(3), best_params_global(3) - t1_range), ...
    max(lb_global(4), best_params_global(4) - t2_range)
];

ub_local = [
    min(ub_global(1), best_params_global(1) + theta_range), ...
    min(ub_global(2), best_params_global(2) + v_range), ...
    min(ub_global(3), best_params_global(3) + t1_range), ...
    min(ub_global(4), best_params_global(4) + t2_range)
];

% 局部优化选项 - 使用自定义变异函数
options_local = optimoptions('ga', ...
    'PopulationSize', 1000, ...
    'MaxGenerations', 100, ...
    'MutationFcn', @adaptive_mutation, ... % ? 直接调用函数
    'CrossoverFraction', 0.9, ...
    'EliteCount', 25, ...
    'Display', 'iter', ...
    'PlotFcn', @gaplotbestf);

[best_params_local, best_dt_local] = ga(@(x) -fitness_function(x), ...
    nvars, [], [], [], [], lb_local, ub_local, [], options_local);

% ==========================================================
% 结果对比
% ==========================================================
fprintf('\n=== 优化结果对比 ===\n');
fprintf('全局搜索最优dt: %.6f\n', -best_dt_global);
fprintf('局部优化最优dt: %.6f\n', -best_dt_local);

fprintf('\n全局搜索最佳参数:\n');
fprintf('theta: %.6f 弧度\n', best_params_global(1));
fprintf('v: %.6f\n', best_params_global(2));
fprintf('t1: %.6f\n', best_params_global(3));
fprintf('t2: %.6f\n', best_params_global(4));

fprintf('\n局部优化最佳参数:\n');
fprintf('theta: %.6f 弧度\n', best_params_local(1));
fprintf('v: %.6f\n', best_params_local(2));
fprintf('t1: %.6f\n', best_params_local(3));
fprintf('t2: %.6f\n', best_params_local(4));


% ==========================================================
% 适应度函数
% ==========================================================
function dt = fitness_function(params)
    theta = params(1);
    v = params(2);
    t1 = params(3);
    t2 = params(4);

    g = 9.8;
    tau = [cos(theta), sin(theta)];

    GRD_1 = [17800 + v * t1 * tau(1), v * t1 * tau(2), 1800];
    GRD_2 = [GRD_1(1) + v * t2 * tau(1), ...
             GRD_1(2) + v * t2 * tau(2), ...
             GRD_1(3) - 0.5 * g * t2^2];

    total_time = t1 + t2;
    M_2 = [20000 - (300 * total_time * 10) / sqrt(101), ...
           0, ...
           2000 - (300 * total_time) / sqrt(101)];

    X1 = GRD_2(1); Y1 = GRD_2(2); Z1 = GRD_2(3);
    X2 = M_2(1);   Z2 = X2 / 10;

    alpha = 3000 / sqrt(101);
    beta = alpha / 10;

    a = alpha^2 + (beta - 3)^2;
    b = 2 * alpha * (X1 - X2) + 2 * (beta - 3) * (Z1 - Z2);
    c = (X1 - X2)^2 + Y1^2 + (Z1 - Z2)^2 - 10^2;

    discriminant = b^2 - 4 * a * c;

    if discriminant <= 0
        dt = 0;
    else
        t_1 = (-b + sqrt(discriminant)) / (2 * a);
        t_2 = (-b - sqrt(discriminant)) / (2 * a);

        if t_1 > t_2
            tmp = t_1; t_1 = t_2; t_2 = tmp;
        end
        if t_2 >= 20, t_2 = 20; end

        dt = max(t_2 - t_1, 0);
    end
end

% ==========================================================
% 自适应变异函数
% ==========================================================
function mutationChildren = adaptive_mutation(parents, options, nvars, FitnessFcn, state, thisScore, thisPopulation)
    % 固定 scales，可以根据需要调整
    scales = [0.01, 0.01, 0.05, 0.05];

    mutationChildren = zeros(length(parents), nvars);

    for i = 1:length(parents)
        parent = thisPopulation(parents(i), :);
        child = parent;
        for j = 1:nvars
            if rand < 0.2   % 变异概率（可以调节，比如 0.2）
                child(j) = parent(j) + scales(j) * randn;
            end
        end
        mutationChildren(i,:) = child;
    end
end
