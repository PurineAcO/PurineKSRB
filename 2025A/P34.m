% 修正版：使用MATLAB遗传算法工具箱优化ccnt函数
% 解决问题：t1<0、约束失效、迭代提前终止、适应度异常

%% 1. 优化参数配置（关键修正：迭代次数、停滞代数匹配）
nvars = 8;  % 参数顺序：[v, th, t1, t2, t3, t4, t5, t6]
pop_size = 100;          % 种群大小（足够大以覆盖解空间）
max_gen = 50;            % 最大迭代次数（≥停滞代数，避免提前终止）
stall_gen = 15;          % 停滞代数（检测到15代无改进则停止）

%% 2. 参数边界（关键修正：补全t1-t6的下界0，避免负数值）
lb = [70,          7*pi/8,  0, 0,  0, 0,  0, 0];  % 下界：v≥70, th≥7π/8, t1-t6≥0
ub = [140,         pi,      15,15, 15,15, 15,15];  % 上界：v≤140, th≤π, t1-t6≤15

%% 3. 遗传算法选项（关键修正：初始种群过滤、显示详细信息）
options = optimoptions('ga', ...
    'PopulationSize', pop_size, ...
    'MaxGenerations', max_gen, ...
    'StallGenLimit', stall_gen, ...
    'CrossoverFraction', 0.8, ...
    'MutationFcn', @mutationgaussian, ...
    'MutationScale', 0.1, ...  % 减小变异幅度，避免参数跳变到约束外
    'Display', 'iter', ...     % 显示每代详细信息（便于排查约束问题）
    'PlotFcn', {@gaplotbestf, @gaplotmeanf}, ...  % 同时画最优/平均适应度
    'InitialPopulationCreationFcn', @create_feasible_pop, ...  % 初始种群必须满足约束
    'ConstraintTolerance', 1e-6);  % 约束容忍度（严格满足约束）

%% 4. 运行遗传算法（目标函数取负：ga默认最小化，需转为最大化ccnt）
[best_params, best_fitness, exitflag, output] = ga(...
    @(x) -ccnt(x(1),x(2),x(3),x(4),x(5),x(6),x(7),x(8)), ...  % 负目标函数
    nvars, ...
    [], [], [], [], ...  % 无线性等式/不等式约束（全部用非线性约束处理）
    lb, ub, ...
    @constraintFcn_fixed, ...  % 修正后的约束函数
    options);

%% 5. 结果输出（验证最优解是否满足约束）
fprintf('\n=====================================\n');
fprintf('优化完成！退出标志：%d（1=收敛，0=迭代结束，-1=失败）\n', exitflag);
fprintf('总迭代次数：%d\n', output.generations);
fprintf('最佳适应度值（ccnt）：%d\n', -best_fitness);  % 还原为原目标函数值

% 解析最佳参数
v_best = best_params(1);
th_best = best_params(2);
t1_best = best_params(3);
t2_best = best_params(4);
t3_best = best_params(5);
t4_best = best_params(6);
t5_best = best_params(7);
t6_best = best_params(8);

% 验证约束满足情况（关键：确保输出解有效）
fprintf('\n【约束验证】\n');
fprintf('t3 ≥ t1+1：%s（t3=%.2f, t1+1=%.2f）\n', ...
    num2str(t3_best >= t1_best + 1 - 1e-6), t3_best, t1_best + 1);
fprintf('t5 ≥ t3+1：%s（t5=%.2f, t3+1=%.2f）\n', ...
    num2str(t5_best >= t3_best + 1 - 1e-6), t5_best, t3_best + 1);
fprintf('t1+t2 ≤15：%s（t1+t2=%.2f）\n', num2str(t1_best + t2_best <= 15 + 1e-6), t1_best + t2_best);
fprintf('t3+t4 ≤15：%s（t3+t4=%.2f）\n', num2str(t3_best + t4_best <= 15 + 1e-6), t3_best + t4_best);
fprintf('t5+t6 ≤15：%s（t5+t6=%.2f）\n', num2str(t5_best + t6_best <= 15 + 1e-6), t5_best + t6_best);

% 输出最佳参数
fprintf('\n【最佳参数】\n');
fprintf('v = %.4f（70~140）\n', v_best);
fprintf('th = %.4f 弧度 = %.2f 度（7π/8≈2.7489~π≈3.1416）\n', ...
    th_best, rad2deg(th_best));
fprintf('t1 = %.4f, t2 = %.4f（t1+t2=%.4f ≤15）\n', t1_best, t2_best, t1_best + t2_best);
fprintf('t3 = %.4f, t4 = %.4f（t3+t4=%.4f ≤15，t3-t1=%.4f ≥1）\n', ...
    t3_best, t4_best, t3_best + t4_best, t3_best - t1_best);
fprintf('t5 = %.4f, t6 = %.4f（t5+t6=%.4f ≤15，t5-t3=%.4f ≥1）\n', ...
    t5_best, t6_best, t5_best + t6_best, t5_best - t3_best);



%% 关键修正1：约束函数（逻辑符号、边界全部正确）
function [c, ceq] = constraintFcn_fixed(x)
% 非线性不等式约束：c ≤ 0 表示满足约束
% x = [v, th, t1, t2, t3, t4, t5, t6]
t1 = x(3);
t2 = x(4);
t3 = x(5);
t4 = x(6);
t5 = x(7);
t6 = x(8);

% 1. t3 ≥ t1 + 1 → 转化为：t1 + 1 - t3 ≤ 0（约束1）
% 2. t5 ≥ t3 + 1 → 转化为：t3 + 1 - t5 ≤ 0（约束2）
% 3. t1 + t2 ≤ 15 → 转化为：t1 + t2 - 15 ≤ 0（约束3）
% 4. t3 + t4 ≤ 15 → 转化为：t3 + t4 - 15 ≤ 0（约束4）
% 5. t5 + t6 ≤ 15 → 转化为：t5 + t6 - 15 ≤ 0（约束5）
c = [
    t1 + 1 - t3;      % 约束1：t3 ≥ t1+1
    t3 + 1 - t5;      % 约束2：t5 ≥ t3+1
    t1 + t2 - 15;     % 约束3：t1+t2 ≤15
    t3 + t4 - 15;     % 约束4：t3+t4 ≤15
    t5 + t6 - 15      % 约束5：t5+t6 ≤15
];

% 无等式约束
ceq = [];
end


%% 关键修正2：初始种群生成（确保所有初始解满足约束，避免无效解）
function pop = create_feasible_pop(nvars, lb, ub, options)
pop_size = options.PopulationSize;
pop = zeros(pop_size, nvars);  % 种群矩阵（每行一个解）

for i = 1:pop_size
    % 循环生成，直到找到满足约束的解
    feasible = false;
    while ~feasible
        % 1. 按边界随机生成候选解
        candidate = rand(1, nvars) .* (ub - lb) + lb;
        v = candidate(1);
        th = candidate(2);
        t1 = candidate(3);
        t2 = candidate(4);
        t3 = candidate(5);
        t4 = candidate(6);
        t5 = candidate(7);
        t6 = candidate(8);
        
        % 2. 检查是否满足所有约束（避免调用约束函数，提高效率）
        if t3 >= t1 + 1 - 1e-6 && ...  % 允许微小误差
           t5 >= t3 + 1 - 1e-6 && ...
           t1 + t2 <= 15 + 1e-6 && ...
           t3 + t4 <= 15 + 1e-6 && ...
           t5 + t6 <= 15 + 1e-6
            feasible = true;
            pop(i, :) = candidate;  % 保存可行解
        end
    end
end
end


%% 目标函数：ccnt（与Python逻辑一致，无修改）
function count = ccnt(v, th, t1, t2, t3, t4, t5, t6)
g = 9.8;
alpha = 3000 / sqrt(101);
beta = 300 / sqrt(101);
t_start = 0;
t_end = 20;
t_step = 0.01;
t_values = t_start:t_step:t_end;
cnttinf = zeros(1, length(t_values));

% 遍历每个时间点，统计满足条件的时刻
for i = 1:length(t_values)
    t = t_values(i);
    % 检查3个设备的有效时间段
    if t >= t1 + t2 && t <= 20 + t1 + t2
        [~, flag] = lengther(v, th, 1, t, t1, t2, t3, t4, t5, t6, g, alpha, beta);
        if flag, cnttinf(i) = cnttinf(i) + 1; end
    end
    if t >= t3 + t4 && t <= 20 + t3 + t4
        [~, flag] = lengther(v, th, 2, t, t1, t2, t3, t4, t5, t6, g, alpha, beta);
        if flag, cnttinf(i) = cnttinf(i) + 1; end
    end
    if t >= t5 + t6 && t <= 20 + t5 + t6
        [~, flag] = lengther(v, th, 3, t, t1, t2, t3, t4, t5, t6, g, alpha, beta);
        if flag, cnttinf(i) = cnttinf(i) + 1; end
    end
end

% 统计有效时间点数量（只要有一个设备满足就算）
count = sum(cnttinf >= 1);
end


%% 辅助函数：计算点G到直线PM的距离（无修改，验证过正确性）
function [t, flag] = lengther(v, th, num, t, t1, t2, t3, t4, t5, t6, g, alpha, beta)
P = [0, 200, 0];          % 固定点P
M = MissilePlace(t, alpha, beta);  % 导弹位置M
G = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6, g);  % 地面设备位置G

% 空间点到直线距离公式：|PG × PM| / |PM|
vector_PM = M - P;
vector_PG = G - P;
cross_product = cross(vector_PG, vector_PM);
distance = norm(cross_product) / norm(vector_PM);

% 距离<10则满足条件（注意：原代码是distance>=10返回false，此处逻辑一致）
flag = distance < 10;
end


%% 辅助函数：导弹位置计算（无修改）
function pos = MissilePlace(t, alpha, beta)
if 2000 - beta * t >= 0
    pos = [20000 - alpha * t, 0, 2000 - beta * t];
else
    pos = [0, 0, 0];  % 导弹落地后位置（可根据实际需求调整）
end
end


%% 辅助函数：地面设备位置计算（无修改）
function pos = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6, g)
switch num
    case 1  % 设备1
        if t < t1
            pos = [17800 - v * t * cos(th), v * t * sin(th), 1800];
        elseif t < t1 + t2
            pos = [17800 - v * t * cos(th), v * t * sin(th), ...
                1800 - 0.5 * g * (t - t1)^2];
        else
            pos = [17800 - v * (t1 + t2) * cos(th), v * (t1 + t2) * sin(th), ...
                1800 - 0.5 * g * t2^2 - 3 * (t - t1 - t2)];
        end
    case 2  % 设备2
        if t < t3
            pos = [17800 - v * t * cos(th), v * t * sin(th), 1800];
        elseif t < t3 + t4
            pos = [17800 - v * t * cos(th), v * t * sin(th), ...
                1800 - 0.5 * g * (t - t3)^2];
        else
            pos = [17800 - v * (t3 + t4) * cos(th), v * (t3 + t4) * sin(th), ...
                1800 - 0.5 * g * t4^2 - 3 * (t - t3 - t4)];
        end
    case 3  % 设备3
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


%% 辅助函数：弧度转角度（用于结果显示）
function deg = rad2deg(rad)
deg = rad * 180 / pi;
end