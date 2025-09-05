function [best_params, best_value] = genetic_algorithm_dt()
    % 遗传算法参数设置
    pop_size = 50;         % 种群大小
    generations = 100;     % 迭代代数
    mutation_rate = 0.1;   % 变异率
    crossover_rate = 0.8;  % 交叉率
    
    % 参数范围设置
    % th: 角度(弧度), v: 速度, t1-t6: 时间参数
    param_ranges = [
        7*pi/8, pi;          % th (0到45度)
        70, 90;         % v
        0, 10;            % t1
        0, 5;             % t2
        1, 10;            % t3
        0, 5;             % t4
        2, 10;            % t5
        0, 5];            % t6
    
    % 初始化种群
    pop = initialize_population(pop_size, param_ranges);
    
    % 约束条件筛选 - 移除不满足条件的个体
    pop = filter_population(pop);
    
    % 如果筛选后种群为空，重新初始化
    while size(pop, 1) < pop_size/2
        pop = [pop; initialize_population(pop_size - size(pop, 1), param_ranges)];
        pop = filter_population(pop);
    end
    
    best_value = -Inf;
    best_params = [];
    
    % 进化循环
    for gen = 1:generations
        % 计算适应度 (dt函数值)
        fitness = zeros(size(pop, 1), 1);
        for i = 1:size(pop, 1)
            params = pop(i, :);
            th = params(1);
            v = params(2);
            t1 = params(3);
            t2 = params(4);
            t3 = params(5);
            t4 = params(6);
            t5 = params(7);
            t6 = params(8);
            
            fitness(i) = dt(th, v, t1, t2, t3, t4, t5, t6);
        end
        
        % 记录最佳个体
        [current_best, idx] = max(fitness);
        if current_best > best_value
            best_value = current_best;
            best_params = pop(idx, :);
        end
        
        % 显示当前代数的最佳适应度
        fprintf('Generation %d: Best Fitness = %f\n', gen, current_best);
        
        % 选择操作
        parents = selection(pop, fitness);
        
        % 交叉操作
        offspring = crossover(parents, crossover_rate, param_ranges);
        
        % 变异操作
        offspring = mutation(offspring, mutation_rate, param_ranges);
        
        % 合并父代和子代，并筛选
        pop = [pop; offspring];
        pop = filter_population(pop);
        
        % 保持种群大小
        if size(pop, 1) > pop_size
            % 计算新种群的适应度
            new_fitness = zeros(size(pop, 1), 1);
            for i = 1:size(pop, 1)
                params = pop(i, :);
                new_fitness(i) = dt(params(1), params(2), params(3), params(4), ...
                                   params(5), params(6), params(7), params(8));
            end
            % 选择适应度最高的个体
            [~, sorted_idx] = sort(new_fitness, 'descend');
            pop = pop(sorted_idx(1:pop_size), :);
        end
    end
    
    fprintf('\nOptimization complete.\n');
    fprintf('Best parameters: th=%f, v=%f, t1=%f, t2=%f, t3=%f, t4=%f, t5=%f, t6=%f\n', best_params);
    fprintf('Best dt value: %f\n', best_value);
end

function pop = initialize_population(pop_size, param_ranges)
    % 初始化种群
    num_params = size(param_ranges, 1);
    pop = zeros(pop_size, num_params);
    
    for i = 1:num_params
        min_val = param_ranges(i, 1);
        max_val = param_ranges(i, 2);
        pop(:, i) = min_val + (max_val - min_val) * rand(pop_size, 1);
    end
end

function pop = filter_population(pop)
    % 筛选种群，移除不满足约束条件的个体
    % 约束条件：t3-t1 > 1 且 t5-t3 > 1
    to_keep = [];
    
    for i = 1:size(pop, 1)
        t1 = pop(i, 3);
        t3 = pop(i, 5);
        t5 = pop(i, 7);
        
        % 检查约束条件
        if (t3 - t1) > 1 && (t5 - t3) > 1
            to_keep = [to_keep, i];
        end
    end
    
    if isempty(to_keep)
        pop = [];
    else
        pop = pop(to_keep, :);
    end
end

function parents = selection(pop, fitness)
    % 轮盘赌选择
    pop_size = size(pop, 1);
    parents = zeros(pop_size, size(pop, 2));
    
    % 确保适应度非负
    fitness = fitness - min(fitness) + 1e-6;
    total_fitness = sum(fitness);
    prob = fitness / total_fitness;
    
    for i = 1:pop_size
        % 轮盘赌选择一个父代
        r = rand;
        cum_prob = 0;
        for j = 1:pop_size
            cum_prob = cum_prob + prob(j);
            if cum_prob >= r
                parents(i, :) = pop(j, :);
                break;
            end
        end
    end
end

function offspring = crossover(parents, crossover_rate, param_ranges)
    % 单点交叉
    pop_size = size(parents, 1);
    num_params = size(parents, 2);
    offspring = zeros(pop_size, num_params);
    
    for i = 1:2:pop_size
        % 选择两个亲本
        parent1 = parents(i, :);
        if i+1 <= pop_size
            parent2 = parents(i+1, :);
        else
            parent2 = parents(1, :);  % 处理奇数情况
        end
        
        % 决定是否进行交叉
        if rand < crossover_rate
            % 随机选择交叉点
            crossover_point = randi([1, num_params-1]);
            
            % 生成子代
            offspring(i, :) = [parent1(1:crossover_point), parent2(crossover_point+1:end)];
            if i+1 <= pop_size
                offspring(i+1, :) = [parent2(1:crossover_point), parent1(crossover_point+1:end)];
            end
        else
            % 不交叉，直接复制
            offspring(i, :) = parent1;
            if i+1 <= pop_size
                offspring(i+1, :) = parent2;
            end
        end
    end
    
    % 确保参数在范围内
    for i = 1:num_params
        min_val = param_ranges(i, 1);
        max_val = param_ranges(i, 2);
        offspring(:, i) = max(min(offspring(:, i), max_val), min_val);
    end
end

function offspring = mutation(offspring, mutation_rate, param_ranges)
    % 高斯变异
    num_params = size(offspring, 2);
    
    for i = 1:size(offspring, 1)
        for j = 1:num_params
            if rand < mutation_rate
                % 高斯变异，标准差为参数范围的10%
                min_val = param_ranges(j, 1);
                max_val = param_ranges(j, 2);
                sigma = 0.1 * (max_val - min_val);
                offspring(i, j) = offspring(i, j) + sigma * randn;
                
                % 确保变异后参数仍在范围内
                offspring(i, j) = max(min(offspring(i, j), max_val), min_val);
            end
        end
    end
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