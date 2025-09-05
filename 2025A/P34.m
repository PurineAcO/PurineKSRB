%% ---------------------- 2. 遗传算法核心逻辑（无工具箱） ----------------------
clear; clc; close all;

% ===================== 2.1 算法参数设置（可根据需求调整） =====================
pop_size = 50;          % 种群规模（每代个体数量）
gen_num = 100;          % 迭代代数（训练轮数）
cross_rate = 0.8;       % 交叉概率（0.7-0.9较优）
mutate_rate = 0.05;     % 变异概率（0.01-0.1较优）
elite_rate = 0.2;       % 精英保留比例（前20%最优个体直接保留）

% ===================== 2.2 参数范围定义（根据物理意义约束） =====================
% 每个参数的【下限，上限】：[v, th(弧度), t1, t2, t3, t4, t5, t6]
% - v：设备移动速度（100-1000，参考原Python逻辑）
% - th：角度（0-π/2，即0-90度，避免反向移动）
% - t1-t6：时间参数（0-10，避免设备动作时间过长）
param_bounds = [
    70,    140;    % v：速度
    7*pi/8,      pi;    % th：角度（弧度）
    0,      15;      % t1：设备1水平移动时间
    0,      10;      % t2：设备1下降时间
    1,      15;      % t3：设备2水平移动时间
    0,      10;      % t4：设备2下降时间
    2,      15;      % t5：设备3水平移动时间
    0,      10       % t6：设备3下降时间
];
param_dim = size(param_bounds, 1);  % 参数维度（共8个参数）


% ===================== 2.3 第一步：初始化种群（满足约束的初始个体） =====================
pop = zeros(pop_size, param_dim);  % 种群矩阵：[个体数×参数数]
for i = 1:pop_size
    % 随机生成初始个体（均匀分布在参数范围内）
    for j = 1:param_dim
        pop(i,j) = param_bounds(j,1) + rand() * (param_bounds(j,2) - param_bounds(j,1));
    end
    % 强制筛选：若初始个体不满足t3-t1≤1或t5-t3≤1，重新生成
    while ~is_valid(pop(i,:))
        for j = 1:param_dim
            pop(i,j) = param_bounds(j,1) + rand() * (param_bounds(j,2) - param_bounds(j,1));
        end
    end
end


% ===================== 2.4 第二步：迭代进化（核心循环） =====================
best_ccnt = zeros(gen_num, 1);  % 记录每代的最优ccnt值
best_param = zeros(gen_num, param_dim);  % 记录每代的最优参数

for gen = 1:gen_num
    % ---------------------- 2.4.1 计算所有个体的适应度（ccnt值） ----------------------
    fitness = zeros(pop_size, 1);
    for i = 1:pop_size
        fitness(i) = ccnt(pop(i,:));  % 适应度=目标函数值（越大越好）
    end
    
    % 记录当前代的最优结果
    [current_best_fit, best_idx] = max(fitness);
    best_ccnt(gen) = current_best_fit;
    best_param(gen,:) = pop(best_idx,:);
    
    % 打印迭代信息（每10代打印一次，避免输出过多）
    if mod(gen, 10) == 0 || gen == 1
        fprintf('第%d代 | 最优ccnt值：%.0f | 最优角度：%.1f度\n', ...
            gen, current_best_fit, rad2deg(best_param(gen,2)));
    end
    
    % ---------------------- 2.4.2 选择操作（轮盘赌选择+精英保留） ----------------------
    elite_size = round(pop_size * elite_rate);  % 精英个体数量（前N个最优）
    new_pop = zeros(pop_size, param_dim);       % 新一代种群容器
    
    % 1. 精英保留：直接复制前elite_size个最优个体到新一代
    [~, elite_idx] = sort(fitness, 'descend');  % 按适应度降序排序
    new_pop(1:elite_size,:) = pop(elite_idx(1:elite_size),:);
    
    % 2. 轮盘赌选择：基于适应度概率选择剩余个体（避免负适应度，先平移）
    fitness_norm = fitness - min(fitness) + 1e-6;  % 适应度平移（确保非负）
    fitness_prob = fitness_norm / sum(fitness_norm);  % 选择概率
    select_idx = randsample(pop_size, pop_size - elite_size, true, fitness_prob);
    new_pop(elite_size+1:end,:) = pop(select_idx,:);
    
    % ---------------------- 2.4.3 交叉操作（单点交叉，仅对非精英个体） ----------------------
    for i = elite_size+1:2:pop_size  % 两两配对交叉（步长=2）
        if rand() < cross_rate  % 按交叉概率执行交叉
            cross_pos = randi(param_dim-1);  % 随机选择交叉位置（1-7）
            % 交换交叉位置后的参数
            temp = new_pop(i, cross_pos+1:end);
            new_pop(i, cross_pos+1:end) = new_pop(i+1, cross_pos+1:end);
            new_pop(i+1, cross_pos+1:end) = temp;
        end
    end
    
    % ---------------------- 2.4.4 变异操作（高斯变异，避免参数越界） ----------------------
    for i = 1:pop_size
        for j = 1:param_dim
            if rand() < mutate_rate  % 按变异概率执行变异
                % 高斯变异：在原参数附近添加小扰动（扰动幅度=参数范围的5%）
                perturb = 0.05 * (param_bounds(j,2) - param_bounds(j,1)) * randn();
                new_pop(i,j) = new_pop(i,j) + perturb;
                % 强制参数在范围内（避免变异后超出物理意义）
                new_pop(i,j) = max(param_bounds(j,1), min(new_pop(i,j), param_bounds(j,2)));
            end
        end
    end
    
    % ---------------------- 2.4.5 强制筛选：淘汰不满足约束的个体 ----------------------
    for i = 1:pop_size
        % 若个体不满足t3-t1≤1或t5-t3≤1，用当前代最优个体替换（保证种群合法性）
        while ~is_valid(new_pop(i,:))
            new_pop(i,:) = best_param(gen,:);  % 用最优个体"修复"非法个体
        end
    end
    
    % ---------------------- 2.4.6 更新种群（进入下一代） ----------------------
    pop = new_pop;
end


% ===================== 2.5 结果分析与可视化 =====================
% 1. 找出全局最优结果
[global_best_fit, global_best_gen] = max(best_ccnt);
global_best_param = best_param(global_best_gen,:);

% 2. 打印最终结果
fprintf('\n==================== 遗传算法训练完成 ====================\n');
fprintf('全局最优ccnt值：%.0f（第%d代）\n', global_best_fit, global_best_gen);
fprintf('全局最优参数：\n');
fprintf(' - 速度v：%.1f\n', global_best_param(1));
fprintf(' - 角度th：%.1f度（%.3f弧度）\n', rad2deg(global_best_param(2)), global_best_param(2));
fprintf(' - t1：%.2f, t2：%.2f, t3：%.2f, t4：%.2f, t5：%.2f, t6：%.2f\n', ...
    global_best_param(3), global_best_param(4), global_best_param(5), ...
    global_best_param(6), global_best_param(7), global_best_param(8));
fprintf('约束满足情况：t3-t1=%.2f≤1，t5-t3=%.2f≤1\n', ...
    global_best_param(5)-global_best_param(3), global_best_param(7)-global_best_param(5));

% 3. 绘制迭代曲线（观察收敛趋势）
figure('Position', [100, 100, 800, 400]);
plot(1:gen_num, best_ccnt, 'b-', 'LineWidth', 1.5);
hold on;
plot(global_best_gen, global_best_fit, 'ro', 'MarkerSize', 8, 'DisplayName', ...
    sprintf('全局最优：%.0f（第%d代）', global_best_fit, global_best_gen));
xlabel('迭代代数', 'FontSize', 12);
ylabel('最优ccnt值（目标函数值）', 'FontSize', 12);
title('遗传算法迭代收敛曲线', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
legend('每代最优值', '全局最优值', 'FontSize', 10);
hold off;



%% ---------------------- 1. 原逻辑辅助函数（无需修改） ----------------------
% 目标函数：计算ccnt（最大化目标）
function count = ccnt(x)
% x = [v, th, t1, t2, t3, t4, t5, t6]
v = x(1); th = x(2); t1 = x(3); t2 = x(4); t3 = x(5); t4 = x(6); t5 = x(7); t6 = x(8);
g = 9.8; alpha = 3000/sqrt(101); beta = 300/sqrt(101);
t_start = 0; t_end = 20; t_step = 0.01;
t_values = t_start:t_step:t_end; cnttinf = zeros(1, length(t_values));

for i = 1:length(t_values)
    t = t_values(i);
    % 设备1有效时段
    if t >= t1+t2 && t <= 20+t1+t2
        [~, flag] = lengther(v, th, 1, t, t1, t2, t3, t4, t5, t6, g, alpha, beta);
        if flag, cnttinf(i) = 1; end
    end
    % 设备2有效时段
    if t >= t3+t4 && t <= 20+t3+t4
        [~, flag] = lengther(v, th, 2, t, t1, t2, t3, t4, t5, t6, g, alpha, beta);
        if flag, cnttinf(i) = 1; end
    end
    % 设备3有效时段
    if t >= t5+t6 && t <= 20+t5+t6
        [~, flag] = lengther(v, th, 3, t, t1, t2, t3, t4, t5, t6, g, alpha, beta);
        if flag, cnttinf(i) = 1; end
    end
end
count = sum(cnttinf);
end

% 点G到直线PM的距离计算+判断
function [t, flag] = lengther(v, th, num, t, t1, t2, t3, t4, t5, t6, g, alpha, beta)
P = [0, 200, 0];                  % 固定点P
M = MissilePlace(t, alpha, beta);  % 导弹位置M
G = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6, g);  % 地面设备位置G

% 空间点到直线距离公式：|PG × PM| / |PM|
vector_PM = M - P;
vector_PG = G - P;
cross_product = cross(vector_PG, vector_PM);
distance = norm(cross_product) / norm(vector_PM);

flag = distance < 10;  % 距离<10则满足条件
end

% 导弹位置计算
function pos = MissilePlace(t, alpha, beta)
if 2000 - beta*t >= 0
    pos = [20000 - alpha*t, 0, 2000 - beta*t];
else
    pos = [0, 0, 0];  % 导弹落地后位置（原逻辑不变）
end
end

% 地面设备位置计算
function pos = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6, g)
switch num
    case 1
        if t < t1
            pos = [17800 - v*t*cos(th), v*t*sin(th), 1800];
        elseif t < t1+t2
            pos = [17800 - v*t*cos(th), v*t*sin(th), 1800 - 0.5*g*(t-t1)^2];
        else
            pos = [17800 - v*(t1+t2)*cos(th), v*(t1+t2)*sin(th), 1800 - 0.5*g*t2^2 - 3*(t-t1-t2)];
        end
    case 2
        if t < t3
            pos = [17800 - v*t*cos(th), v*t*sin(th), 1800];
        elseif t < t3+t4
            pos = [17800 - v*t*cos(th), v*t*sin(th), 1800 - 0.5*g*(t-t3)^2];
        else
            pos = [17800 - v*(t3+t4)*cos(th), v*(t3+t4)*sin(th), 1800 - 0.5*g*t4^2 - 3*(t-t3-t4)];
        end
    case 3
        if t < t5
            pos = [17800 - v*t*cos(th), v*t*sin(th), 1800];
        elseif t < t5+t6
            pos = [17800 - v*t*cos(th), v*t*sin(th), 1800 - 0.5*g*(t-t5)^2];
        else
            pos = [17800 - v*(t5+t6)*cos(th), v*(t5+t6)*sin(th), 1800 - 0.5*g*t6^2 - 3*(t-t5-t6)];
        end
end
end

% 辅助：弧度转角度（仅用于结果显示）
function deg = rad2deg(rad)
deg = rad * 180 / pi;
end





%% ---------------------- 3. 辅助函数：判断个体是否满足约束 ----------------------
function valid = is_valid(x)
% x = [v, th, t1, t2, t3, t4, t5, t6]
t1 = x(3);
t3 = x(5);
t5 = x(7);
% 约束条件：t3-t1≤1 且 t5-t3≤1（允许等于，避免严格小于导致无可行解）
valid = (t3 - t1 >= 1) && (t5 - t3 >= 1);
end



