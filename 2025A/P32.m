
% 主函数：设置优化参数并调用遗传算法

% 参数范围设置
% 变量顺序：th, v, t1, t2, t3, t4, t5, t6
nVars = 8;                          % 优化变量数量
lb = [7*pi/8 + 1e-6, 70, 0, 0, 0, 0, 0, 0];  % 下界（th略大于7π/8避免边界问题）
ub = [pi - 1e-6, 140, 20, 20, 20, 20, 20, 20];% 上界（th略小于π）

% 遗传算法选项设置
options = optimoptions('ga', ...
    'PopulationSize', 100, ...        % 种群大小
    'MaxGenerations', 15, ...         % 最大进化代数
    'CrossoverFraction', 0.6, ...     % 交叉概率
    'MutationFcn', @mutationadaptfeasible, ...  % 自适应变异
    'ConstraintTolerance', 1e-6, ...  % 约束容差
    'Display', 'iter', ...            % 显示迭代过程
    'PlotFcn', @gaplotbestf);         % 绘制最优适应度曲线

% 调用遗传算法进行优化
[x_opt, fval, exitflag, output] = ga(@(x)fitness_func(x), nVars, ...
    [], [], [], [], lb, ub, @constraint_func, [], options);

% 输出优化结果
fprintf('\n==================== 优化结果 ====================\n');
fprintf('最优参数组合：\n');
fprintf('  th = %.4f 弧度 (%.2f 度)\n', x_opt(1), rad2deg(x_opt(1)));
fprintf('  v = %.4f\n', x_opt(2));
fprintf('  t1 = %.4f, t2 = %.4f\n', x_opt(3), x_opt(4));
fprintf('  t3 = %.4f, t4 = %.4f\n', x_opt(5), x_opt(6));
fprintf('  t5 = %.4f, t6 = %.4f\n', x_opt(7), x_opt(8));
fprintf('最优目标函数值 (dt)：%.4f\n', fval);
fprintf('优化收敛标志：%d (1=收敛，0=达到最大代数，-1=失败)\n', exitflag);
fprintf('总进化代数：%d\n', output.generations);
fprintf('==================================================\n');


function fitness = fitness_func(x)
    % 适应度函数：计算dt值（直接返回dt作为适应度，因为我们要最小化dt）
    th = x(1);
    v = x(2);
    t1 = x(3);
    t2 = x(4);
    t3 = x(5);
    t4 = x(6);
    t5 = x(7);
    t6 = x(8);
    
    % 计算目标函数值
    fitness = -dt(th, v, t1, t2, t3, t4, t5, t6);
end

function [c, ceq] = constraint_func(x)
    % 约束函数：定义非线性约束
    % c <= 0 为不等式约束，ceq = 0 为等式约束
    t1 = x(3);
    t3 = x(5);
    t5 = x(7);
    
    % 不等式约束：t3 >= t1 + 1 和 t5 >= t3 + 1（转换为 <= 0 形式）
    c(1) = t1 + 1 - t3;  % t3 >= t1 + 1 => t1 + 1 - t3 <= 0
    c(2) = t3 + 1 - t5;  % t5 >= t3 + 1 => t3 + 1 - t5 <= 0
    
    % 无等式约束
    ceq = [];
end

function mesh = create_mesh()
    % 创建网格点（与Python代码逻辑一致）
    mesh = [];
    % 第一部分网格
    for theta = 0:0.1:2*pi - 1e-6
        x = 7 * cos(theta);
        y = 200 + 7 * sin(theta);
        z = 10;
        mesh = [mesh; x, y, z];
    end
    % 第二部分网格
    for theta = 0:0.1:2*pi - 1e-6
        for z = 0:0.1:10
            x = 7 * cos(theta);
            y = 200 + 7 * sin(theta);
            mesh = [mesh; x, y, z];
        end
    end
end

function sol = s2e(a, b, c)
    % 二次方程求解（对应Python的s2e函数）
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
    % 地面位置计算（对应Python的GRDPlace函数）
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
            if t < t3
                pos = [base_x, base_y, 1800];
            elseif t < t3 + t4
                pos = [base_x, base_y, 1800 - 0.5*g*(t-t3)^2];
            else
                z = 1800 - 0.5*g*t4^2 - 3*(t - t3 - t4);
                pos = [17800 - v*(t3+t4)*cos(th), v*(t3+t4)*sin(th), z];
            end
            
        case 3  % 第三个目标
            if t < t5
                pos = [base_x, base_y, 1800];
            elseif t < t5 + t6
                pos = [base_x, base_y, 1800 - 0.5*g*(t-t5)^2];
            else
                z = 1800 - 0.5*g*t6^2 - 3*(t - t5 - t6);
                pos = [17800 - v*(t5+t6)*cos(th), v*(t5+t6)*sin(th), z];
            end
    end
end

function [t, ifclose] = solvek(t, mesh, v, th, num, t1, t2, t3, t4, t5, t6)
    % 检测函数（对应Python的solvek函数）
    ifclose = false;
    M = MissilePlace(t);
    G = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6);
    
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
end

function cntt = dt(th, v, t1, t2, t3, t4, t5, t6)
    % 目标函数计算（对应Python的dt函数）
    mesh = create_mesh();  % 创建网格点
    
    t_start = 0;
    t_end = 20;
    t_step = 0.01;
    t_list = t_start:t_step:t_end;
    cnttinf = zeros(1, length(t_list));  % 用于计数的数组
    
    % 遍历所有时间点
    for idx = 1:length(t_list)
        t = t_list(idx);
        
        % 检查第一个目标的时间区间
        if t >= t1 + t2 && t <= 20 + t1 + t2
            [~, ifclose] = solvek(t, mesh, v, th, 1, t1, t2, t3, t4, t5, t6);
            if ifclose
                cnttinf(idx) = cnttinf(idx) + 1;
            end
        end
        
        % 检查第二个目标的时间区间
        if t >= t3 + t4 && t <= 20 + t3 + t4
            [~, ifclose] = solvek(t, mesh, v, th, 2, t1, t2, t3, t4, t5, t6);
            if ifclose
                cnttinf(idx) = cnttinf(idx) + 1;
            end
        end
        
        % 检查第三个目标的时间区间
        if t >= t5 + t6 && t <= 20 + t5 + t6
            [~, ifclose] = solvek(t, mesh, v, th, 3, t1, t2, t3, t4, t5, t6);
            if ifclose
                cnttinf(idx) = cnttinf(idx) + 1;
            end
        end
    end
    
    % 统计满足条件的时间点数量
    cntt = sum(cnttinf >= 1);
end
    