function optimize_dt_refined()
    % 改进的遗传算法，用于细化参数准确值
    
    % 第一阶段：全局搜索
    fprintf('=== 第一阶段：全局搜索 ===\n');
    nvars = 4;  % 参数数量: theta, v, t1, t2
    lb_global = [0, 70, 0, 0];
    ub_global = [2*pi, 140, 100, 100];
    
    options_global = optimoptions('ga', ...
        'PopulationSize', 150, ...
        'MaxGenerations', 80, ...
        'MutationRate', 0.15, ...
        'CrossoverFraction', 0.8, ...
        'EliteCount', 15, ...
        'Display', 'iter', ...
        'PlotFcn', @gaplotbestf);
    
    [best_params_global, best_dt_global] = ga(@(x) -fitness_function(x), ...
        nvars, [], [], [], [], lb_global, ub_global, [], options_global);
    
    % 第二阶段：局部精细优化 - 缩小参数范围
    fprintf('\n=== 第二阶段：局部精细优化 ===\n');
    
    % 为不同参数设置不同的收缩比例
    % theta和v可能需要更高精度，设置较小的范围
    theta_range = 0.05 * (ub_global(1) - lb_global(1));
    v_range = 0.03 * (ub_global(2) - lb_global(2));
    t1_range = 0.1 * (ub_global(3) - lb_global(3));
    t2_range = 0.1 * (ub_global(4) - lb_global(4));
    
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
    
    % 局部优化选项 - 更小的变异步长，更大的种群
    options_local = optimoptions('ga', ...
        'PopulationSize', 200, ...
        'MaxGenerations', 100, ...
        'MutationFcn', @(options, population, state) adaptive_mutation(options, population, state, [0.01, 0.01, 0.05, 0.05]), ...
        'CrossoverFraction', 0.9, ...
        'EliteCount', 20, ...
        'Display', 'iter', ...
        'PlotFcn', @gaplotbestf);
    
    [best_params_local, best_dt_local] = ga(@(x) -fitness_function(x), ...
        nvars, [], [], [], [], lb_local, ub_local, [], options_local);
    
    % 显示结果对比
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
end

function dt = fitness_function(params)
    % 与之前相同的适应度函数
    theta = params(1);
    v = params(2);
    t1 = params(3);
    t2 = params(4);
    
    g = 9.8;
    tau = [cos(theta), sin(theta)];
    
    GRD_1 = [
        17800 + v * t1 * tau(1), ...
        v * t1 * tau(2), ...
        1800 ...
    ];
    
    GRD_2 = [
        GRD_1(1) + v * t2 * tau(1), ...
        GRD_1(2) + v * t2 * tau(2), ...
        GRD_1(3) - 0.5 * g * t2^2 ...
    ];
    
    total_time = t1 + t2;
    M_2 = [
        20000 - (300 * total_time * 10) / sqrt(101), ...
        0, ...
        2000 - (300 * total_time) / sqrt(101) ...
    ];
    
    X1 = GRD_2(1);
    Y1 = GRD_2(2);
    Z1 = GRD_2(3);
    X2 = M_2(1);
    Z2 = X2 / 10;
    
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
            [t_1, t_2] = swap(t_1, t_2);
        end
        
        if t_2 >= 20
            t_2 = 20;
        end
        
        dt = t_2 - t_1;
        dt = max(dt, 0);
    end
end

function [a, b] = swap(a, b)
    temp = a;
    a = b;
    b = temp;
end

function mutation = adaptive_mutation(options, population, state, scales)
    % 自适应变异函数，为不同参数设置不同的变异尺度
    % scales: 每个参数的变异尺度因子
    
    [~, nvars] = size(population);
    mutation = population;
    
    % 对每个个体进行变异
    for i = 1:size(population, 1)
        for j = 1:nvars
            % 根据预设的尺度因子进行变异
            if rand < options.MutationRate
                % 高斯变异，尺度根据参数重要性调整
                mutation(i,j) = population(i,j) + scales(j) * randn;
            end
        end
    end
end
