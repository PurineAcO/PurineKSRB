function [best_params, best_value] = optimized_ga()
    % 优化三个参数：th, t1, t2
    % 其他参数关系：t4=t6=t2, t3=t1+1, t5=t3+1, v=105
    
    % 参数数量及范围
    nvars = 3;  % th, t1, t2
    lb = [0; 0; 0];          % 下界：th=0, t1=0, t2=0
    ub = [pi/8; 3; 3];       % 上界：th=pi/8, t1=3, t2=3
    
    % 遗传算法选项设置
    options = gaoptimset( ...
        'PopulationSize', 100, ...        % 种群大小
        'Generations', 20, ...           % 迭代代数
        'CrossoverFraction', 0.8, ...    % 交叉率
        'Display', 'iter', ...           % 显示迭代过程
        'PlotFcn', @gaplotbestf);        % 绘制最佳适应度曲线
    
    % 运行遗传算法
    [best_params, best_value] = ga(@fitness_fun, nvars, [], [], [], [], lb, ub, [], options);
    best_value = -best_value;  % 还原为原dt值
    
    % 显示优化结果
    fprintf('\n===================== 优化结果 =====================\n');
    th = best_params(1);
    t1 = best_params(2);
    t2 = best_params(3);
    t3 = t1 + 1;
    t4 = t2;
    t5 = t3 + 1;
    t6 = t2;
    v = 105;
    
    fprintf('最佳参数：\n');
    fprintf('  th(弧度)=%6.4f (≈%4.1f°), t1=%6.2f, t2=%6.2f\n', ...
        th, rad2deg(th), t1, t2);
    fprintf('  衍生参数：t3=%6.2f, t4=%6.2f, t5=%6.2f, t6=%6.2f, v=%d\n', ...
        t3, t4, t5, t6, v);
    fprintf('最佳dt值：%d\n', best_value);
end

% 适应度函数
function f = fitness_fun(params)
    % 提取优化参数
    th = params(1);
    t1 = params(2);
    t2 = params(3);
    
    % 根据规则计算其他参数
    t3 = t1 + 1;
    t4 = t2;
    t5 = t3 + 1;
    t6 = t2;
    v = 105;  % 固定值
    
    % 计算dt值作为适应度（由于ga是最小化算法，返回其负值）
    f = -dt(th, v, t1, t2, t3, t4, t5, t6);
end

% 以下是原有函数（保持不变）
function mesh = create_mesh()
    % 创建网格点（优化版本，预分配内存）
    theta_list = 0:0.1:2*pi - 1e-6;
    z_list = 0:0.1:10;
    n_theta = length(theta_list);
    n_z = length(z_list);
    
    % 第一部分网格（z=10）
    mesh1 = zeros(n_theta, 3);
    for i = 1:n_theta
        theta = theta_list(i);
        mesh1(i, :) = [7*cos(theta), 200 + 7*sin(theta), 10];
    end
    
    % 第二部分网格（z变化）
    mesh2 = zeros(n_theta * n_z, 3);
    idx = 1;
    for i = 1:n_theta
        theta = theta_list(i);
        for j = 1:n_z
            z = z_list(j);
            mesh2(idx, :) = [7*cos(theta), 200 + 7*sin(theta), z];
            idx = idx + 1;
        end
    end
    
    % 合并两部分网格
    mesh = [mesh1; mesh2];
end

function sol = s2e(a, b, c)
    % 二次方程求解
    if a == 0 || (b^2 - 4*a*c) < 0
        sol = [];  % 无实根返回空
    else
        delta = sqrt(b^2 - 4*a*c);
        x1 = (-b + delta) / (2*a);
        x2 = (-b - delta) / (2*a);
        sol = [x1, x2];
    end
end

function pos = MissilePlace(t)
    % 导弹位置计算
    g = 9.8;
    alpha = 3000 / sqrt(101);
    beta = 300 / sqrt(101);
    
    if 2000 - beta*t >= 0
        pos = [20000 - alpha*t, 0, 2000 - beta*t];
    else
        pos = [0, 0, 0];
    end
end

function pos = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6)
    % 地面位置计算
    g = 9.8;
    base_x = 17800 - v * t * cos(th);
    base_y = v * t * sin(th);
    
    switch num
        case 1  % 第一个目标
            if t < t1
                pos = [base_x, base_y, 1800];
            elseif t < t1 + t2
                pos = [base_x, base_y, 1800 - 0.5*g*(t-t1)^2];
            else
                z = 1800 - 0.5*g*t2^2 - 3*(t - t1 - t2);
                pos = [17800 - v*(t1+t2)*cos(th), v*(t1+t2)*sin(th), z];
            end
            
        case 2  % 第二个目标
            if t < t1+t3
                pos = [base_x, base_y, 1800];
            elseif t < (t1+t3) + t4
                pos = [base_x, base_y, 1800 - 0.5*g*(t-(t1+t3))^2];
            else
                z = 1800 - 0.5*g*t4^2 - 3*(t - (t1+t3) - t4);
                pos = [17800 - v*((t1+t3)+t4)*cos(th), v*((t1+t3)+t4)*sin(th), z];
            end
            
        case 3  % 第三个目标
            if t < t1+t3+t5
                pos = [base_x, base_y, 1800];
            elseif t < (t1+t3+t5) + t6
                pos = [base_x, base_y, 1800 - 0.5*g*(t-(t1+t3+t5))^2];
            else
                z = 1800 - 0.5*g*t6^2 - 3*(t - (t1+t3+t5) - t6);
                pos = [17800 - v*((t1+t3+t5)+t6)*cos(th), v*((t1+t3+t5)+t6)*sin(th), z];
            end
    end
end

function [t_out, ifclose] = solvek(t_in, mesh, v, th, num, t1, t2, t3, t4, t5, t6)
    % 检测函数
    ifclose = false;
    M = MissilePlace(t_in);
    G = GRDPlace(v, th, num, t_in, t1, t2, t3, t4, t5, t6);
    
    M1 = M(1); M2 = M(2); M3 = M(3);
    G1 = G(1); G2 = G(2); G3 = G(3);
    
    for i = 1:size(mesh, 1)
        P = mesh(i, :);
        P1 = P(1); P2 = P(2); P3 = P(3);
        
        % 计算二次方程系数
        a = (M1 - P1)^2 + (M2 - P2)^2 + (M3 - P3)^2;
        b = -2 * ((M1 - P1)*(G1 - P1) + (M2 - P2)*(G2 - P2) + (M3 - P3)*(G3 - P3));
        c = (G1 - P1)^2 + (G2 - P2)^2 + (G3 - P3)^2 - 10^2;
        
        sol = s2e(a, b, c);
        if ~isempty(sol) && any(sol >= 0 - 1e-6) && any(sol <= 1 + 1e-6)
            ifclose = true;
        else
            ifclose = false;
            break;  % 只要一个点不满足就返回false
        end
    end
    t_out = t_in;  % 输出t值
end

function cntt = dt(th, v, t1, t2, t3, t4, t5, t6)
    % 目标函数计算（使用静态变量存储mesh）
    persistent mesh;
    if isempty(mesh)
        mesh = create_mesh();  % 仅创建一次网格
    end
    
    t_start = 0;
    t_end = 20;
    t_step = 0.01;
    t_list = t_start:t_step:t_end;
    cnttinf = zeros(1, length(t_list));  % 用于计数的数组
    
    % 遍历所有时间点
    for idx = 1:length(t_list)
        t = t_list(idx);
        
        % 检查第一个目标的时间区间
        t_low1 = t1 + t2;
        t_high1 = min(20 + t1 + t2, 20);
        if t_low1 <= 20 && t >= t_low1 && t <= t_high1
            [~, ifclose] = solvek(t, mesh, v, th, 1, t1, t2, t3, t4, t5, t6);
            if ifclose
                cnttinf(idx) = cnttinf(idx) + 1;
            end
        end
        
        % 检查第二个目标的时间区间
        t_low2 = t1 + t3 + t4;
        t_high2 = min(20 + t1 + t3 + t4, 20);
        if t_low2 <= 20 && t >= t_low2 && t <= t_high2
            [~, ifclose] = solvek(t, mesh, v, th, 2, t1, t2, t3, t4, t5, t6);
            if ifclose
                cnttinf(idx) = cnttinf(idx) + 1;
            end
        end
        
        % 检查第三个目标的时间区间
        t_low3 = t1 + t3 + t5 + t6;
        t_high3 = min(20 + t1 + t3 + t5 + t6, 20);
        if t_low3 <= 20 && t >= t_low3 && t <= t_high3
            [~, ifclose] = solvek(t, mesh, v, th, 3, t1, t2, t3, t4, t5, t6);
            if ifclose
                cnttinf(idx) = cnttinf(idx) + 1;
            end
        end
    end
    
    % 统计满足条件的时间点数量
    cntt = sum(cnttinf >= 1);
end