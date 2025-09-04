function optimize_dt()
    % 使用MATLAB遗传算法求解器优化(theta, v, t1, t2)以最大化dt值
    
    % 定义参数个数和范围
    nvars = 4;  % 参数数量: theta, v, t1, t2
    
    % 参数范围 [theta_min, v_min, t1_min, t2_min; theta_max, v_max, t1_max, t2_max]
    lb = [0, 70, 0, 0];       % 下界
    ub = [2*pi, 140, 100, 100]; % 上界
    
    % 设置遗传算法选项
    options = optimoptions('ga', ...
        'PopulationSize', 100, ...       % 种群大小
        'MaxGenerations', 100, ...       % 最大迭代代数
        'MutationRate', 0.1, ...         % 变异率
        'CrossoverFraction', 0.8, ...    % 交叉率
        'EliteCount', 10, ...            % 精英个体数量
        'Display', 'iter', ...           % 显示迭代过程
        'PlotFcn', @gaplotbestf);        % 绘制最佳适应度曲线
    
    % 运行遗传算法
    [best_params, best_dt] = ga(@(x) -fitness_function(x), nvars, [], [], [], [], lb, ub, [], options);
    % 注意: 使用负的适应度函数因为ga默认最小化目标函数
    
    % 显示优化结果
    fprintf('\n优化结果:\n');
    fprintf('最佳参数:\n');
    fprintf('theta: %.4f 弧度\n', best_params(1));
    fprintf('v: %.4f\n', best_params(2));
    fprintf('t1: %.4f\n', best_params(3));
    fprintf('t2: %.4f\n', best_params(4));
    fprintf('最大dt值: %.4f\n', -best_dt);  % 还原为正值
end

function dt = fitness_function(params)
    % 计算适应度函数，返回dt值
    % params = [theta, v, t1, t2]
    
    theta = params(1);
    v = params(2);
    t1 = params(3);
    t2 = params(4);
    
    g = 9.8;
    tau = [cos(theta), sin(theta)];
    
    % 计算GRD_1坐标
    GRD_1 = [
        17800 + v * t1 * tau(1), ...
        v * t1 * tau(2), ...
        1800 ...
    ];
    
    % 计算GRD_2坐标
    GRD_2 = [
        GRD_1(1) + v * t2 * tau(1), ...
        GRD_1(2) + v * t2 * tau(2), ...
        GRD_1(3) - 0.5 * g * t2^2 ...
    ];
    
    % 计算M_2坐标
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
    
    % 计算二次方程系数
    a = alpha^2 + (beta - 3)^2;
    b = 2 * alpha * (X1 - X2) + 2 * (beta - 3) * (Z1 - Z2);
    c = (X1 - X2)^2 + Y1^2 + (Z1 - Z2)^2 - 10^2;
    
    % 计算判别式
    discriminant = b^2 - 4 * a * c;
    
    if discriminant <= 0
        dt = 0;  % 无实根时返回0，表示适应度低
    else
        % 计算两个根
        t_1 = (-b + sqrt(discriminant)) / (2 * a);
        t_2 = (-b - sqrt(discriminant)) / (2 * a);
        
        % 确保t_1 <= t_2
        if t_1 > t_2
            [t_1, t_2] = swap(t_1, t_2);
        end
        
        % 应用约束
        if t_2 >= 20
            t_2 = 20;
        end
        
        % 计算dt值
        dt = t_2 - t_1;
        dt = max(dt, 0);  % 确保dt非负
    end
end

function [a, b] = swap(a, b)
    % 交换两个变量的值
    temp = a;
    a = b;
    b = temp;
end
