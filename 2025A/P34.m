
% 使用MATLAB自带的遗传算法工具箱优化参数
% 优化目标：最大化ccnt函数
% 参数约束：v(70,140), th(7π/8, π), t1-t6(0,15), t3≥t1+1, t5≥t3+1

% 定义参数个数和范围
nvars = 8;  % 参数: v, th, t1, t2, t3, t4, t5, t6

% 参数下界和上界
lb = [70, 7*pi/8, 0, 0, 0, 0, 0, 0];    % 下界
ub = [140, pi, 15, 15, 15, 15, 15, 15]; % 上界

% 设置遗传算法选项
options = optimoptions('ga', ...
    'PopulationSize', 100, ...         % 种群大小
    'MaxGenerations', 15, ...        % 最大迭代次数
    'CrossoverFraction', 0.8, ...     % 交叉概率
    'MutationFcn', @mutationgaussian, ... % 变异函数
    'Display', 'iter', ...            % 显示迭代过程
    'StallGenLimit', 20, ...          % 停滞代数限制
    'PlotFcn', @gaplotbestf);         % 绘制最优适应度曲线

% 运行遗传算法
[best_params, best_fitness] = ga(@(x) -ccnt(x(1),x(2),x(3),x(4),x(5),x(6),x(7),x(8)), ...
    nvars, [], [], [], [], lb, ub, @constraintFcn, options);

% 显示优化结果
fprintf('\n优化完成!\n');
fprintf('最佳适应度值: %d\n', -best_fitness);
fprintf('最佳参数:\n');
fprintf('v = %.4f\n', best_params(1));
fprintf('th = %.4f 弧度 (%.2f 度)\n', best_params(2), rad2deg(best_params(2)));
fprintf('t1 = %.4f, t2 = %.4f\n', best_params(3), best_params(4));
fprintf('t3 = %.4f, t4 = %.4f\n', best_params(5), best_params(6));
fprintf('t5 = %.4f, t6 = %.4f\n', best_params(7), best_params(8));


% 约束条件函数
function [c, ceq] = constraintFcn(x)
    % x = [v, th, t1, t2, t3, t4, t5, t6]
    t1 = x(3);
    t3 = x(5);
    t5 = x(7);
    
    % 不等式约束: c <= 0
    % t3 >= t1 + 1 --> t1 + 1 - t3 <= 0
    % t5 >= t3 + 1 --> t3 + 1 - t5 <= 0
    % 各时间参数总和约束（确保不超过15）
    c = [
        t1 + 1 - t3;          % 约束1: t3 >= t1 + 1
        t3 + 1 - t5;          % 约束2: t5 >= t3 + 1
        t1 + t2 - 15;         % 约束3: t1 + t2 <= 15
        t3 + t4 - 15;         % 约束4: t3 + t4 <= 15
        t5 + t6 - 15          % 约束5: t5 + t6 <= 15
    ];
    
    % 等式约束: ceq = 0（无等式约束）
    ceq = [];
end

% 目标函数: 计算ccnt值（与Python代码逻辑一致）
function count = ccnt(v, th, t1, t2, t3, t4, t5, t6)
    g = 9.8;
    alpha = 3000 / sqrt(101);
    beta = 300 / sqrt(101);
    t_start = 0;
    t_end = 20;
    t_step = 0.01;
    t_values = t_start:t_step:t_end;
    % cntt = 0;
    cnttinf = zeros(1, length(t_values));
    
    for i = 1:length(t_values)
        t = t_values(i);
        % 检查三个时间段
        if t >= t1 + t2 && t <= 20 + t1 + t2
            [~, flag] = lengther(v, th, 1, t, t1, t2, t3, t4, t5, t6, g, alpha, beta);
            if flag
                cnttinf(i) = cnttinf(i) + 1;
            end
        end
        
        if t >= t3 + t4 && t <= 20 + t3 + t4
            [~, flag] = lengther(v, th, 2, t, t1, t2, t3, t4, t5, t6, g, alpha, beta);
            if flag
                cnttinf(i) = cnttinf(i) + 1;
            end
        end
        
        if t >= t5 + t6 && t <= 20 + t5 + t6
            [~, flag] = lengther(v, th, 3, t, t1, t2, t3, t4, t5, t6, g, alpha, beta);
            if flag
                cnttinf(i) = cnttinf(i) + 1;
            end
        end
    end
    
    % 统计有效计数
    count = sum(cnttinf >= 1);
end

% 计算点G到直线PM的距离并判断
function [t, flag] = lengther(v, th, num, t, t1, t2, t3, t4, t5, t6, g, alpha, beta)
    % 获取三点坐标
    P = [0, 200, 0];
    M = MissilePlace(t, alpha, beta);
    G = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6, g);
    
    % 计算向量
    vector_PM = M - P;
    vector_PG = G - P;
    
    % 计算叉积的模长除以PM的模长（点到直线距离）
    cross_product = cross(vector_PG, vector_PM);
    distance = norm(cross_product) / norm(vector_PM);
    
    % 判断距离是否小于10
    flag = distance < 10;
end

% 导弹位置函数
function pos = MissilePlace(t, alpha, beta)
    if 2000 - beta * t >= 0
        pos = [20000 - alpha * t, 0, 2000 - beta * t];
    else
        pos = [0, 0, 0];
    end
end

% 地面设备位置函数
function pos = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6, g)
    switch num
        case 1
            if t < t1
                pos = [17800 - v * t * cos(th), v * t * sin(th), 1800];
            elseif t < t1 + t2
                pos = [17800 - v * t * cos(th), v * t * sin(th), ...
                    1800 - 0.5 * g * (t - t1)^2];
            else
                pos = [17800 - v * (t1 + t2) * cos(th), v * (t1 + t2) * sin(th), ...
                    1800 - 0.5 * g * t2^2 - 3 * (t - t1 - t2)];
            end
        case 2
            if t < t3
                pos = [17800 - v * t * cos(th), v * t * sin(th), 1800];
            elseif t < t3 + t4
                pos = [17800 - v * t * cos(th), v * t * sin(th), ...
                    1800 - 0.5 * g * (t - t3)^2];
            else
                pos = [17800 - v * (t3 + t4) * cos(th), v * (t3 + t4) * sin(th), ...
                    1800 - 0.5 * g * t4^2 - 3 * (t - t3 - t4)];
            end
        case 3
            if t < t5
                pos = [17800 - v * t * cos(th), v * t * sin(th), 1800];
            elseif t < t5 + t6
                pos = [17800 - v * t * cos(th), v * t * sin(th), ...
                    1800 - 0.5 * g * (t - t5)^2];
            else
                pos = [17800 - v * (t5 + t6) * cos(th), v * (t5 + t6) * sin(th), ...
                    1800 - 0.5 * g * t6^2 - 3 * (t - t5 - t6)];
            end
    end
end
    