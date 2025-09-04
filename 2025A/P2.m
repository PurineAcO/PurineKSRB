% 模拟退火算法（SA）：固定theta=0，优化v(t1,t2)使dt最大化
clear; clc; close all;

%% 1. 算法参数与约束设置
% 固定参数
theta_fixed = 0;              
% 待优化参数的约束范围 [v_min, v_max; t1_min, t1_max; t2_min, t2_max]
param_bounds = [70, 140;     % v的范围
                0,  0.5;     % t1的范围
                0,  0.5];    % t2的范围
param_num = size(param_bounds, 1);  % 待优化参数数量（3个：v, t1, t2）

% 模拟退火核心参数（可根据需求微调）
T0 = 100;              % 初始温度（需足够高，保证初期接受较差解）
T_end = 1e-6;          % 终止温度（温度足够低时停止迭代）
alpha = 0.98;          % 温度衰减系数（0.95~0.99，越小降温越快）
max_iter_per_T = 100;  % 每个温度下的最大迭代次数（邻域搜索次数）
step_factor = 0.02;    % 邻域搜索步长因子（控制每次参数变化幅度）

%% 2. 初始化
% 随机生成初始解（在约束范围内均匀采样）
current_sol = zeros(1, param_num);
for i = 1:param_num
    current_sol(i) = param_bounds(i,1) + rand() * (param_bounds(i,2) - param_bounds(i,1));
end
% 计算初始解的目标函数值（dt）
current_dt = fitness_function([theta_fixed, current_sol]);

% 初始化最优解（记录迭代过程中的全局最优）
best_sol = current_sol;
best_dt = current_dt;

% 初始化迭代记录（用于后续绘图分析）
iter_record = [];      % 迭代次数
T_record = [];         % 温度变化记录
current_dt_record = [];% 当前解的dt记录
best_dt_record = [];   % 全局最优的dt记录

%% 3. 模拟退火主循环
T = T0;                % 初始温度
iter_total = 0;        % 总迭代次数
while T > T_end        % 温度未降至终止温度时，持续迭代
    % 每个温度下进行多次邻域搜索
    for iter = 1:max_iter_per_T
        iter_total = iter_total + 1;
        
        % ---------------------- 3.1 生成邻域解（新解）----------------------
        new_sol = current_sol;
        for i = 1:param_num
            % 基于当前解生成邻域解：高斯随机扰动（步长与参数范围成正比）
            step = step_factor * (param_bounds(i,2) - param_bounds(i,1));  % 动态步长
            new_sol(i) = current_sol(i) + step * randn();                  % 高斯扰动
            % 强制新解在约束范围内（边界截断）
            new_sol(i) = max(param_bounds(i,1), min(new_sol(i), param_bounds(i,2)));
        end
        
        % ---------------------- 3.2 计算目标函数值 ----------------------
        % 构造完整参数向量（theta固定+新解）
        new_params = [theta_fixed, new_sol];
        new_dt = fitness_function(new_params);
        
        % ---------------------- 3.3 接受准则（Metropolis准则）----------------------
        dt_diff = new_dt - current_dt;  % 新解与当前解的目标函数差值（dt越大越好）
        if dt_diff > 0                  % 新解更优：直接接受
            current_sol = new_sol;
            current_dt = new_dt;
            % 更新全局最优
            if new_dt > best_dt
                best_sol = new_sol;
                best_dt = new_dt;
            end
        else                            % 新解较差：按概率接受（温度越高，接受概率越大）
            accept_prob = exp(dt_diff / T);  % 接受概率（基于温度T）
            if rand() < accept_prob          % 随机判断是否接受
                current_sol = new_sol;
                current_dt = new_dt;
            end
        end
        
        % ---------------------- 3.4 记录迭代信息 ----------------------
        iter_record = [iter_record, iter_total];
        T_record = [T_record, T];
        current_dt_record = [current_dt_record, current_dt];
        best_dt_record = [best_dt_record, best_dt];
    end
    
    % ---------------------- 3.5 温度衰减 ----------------------
    T = T * alpha;
    
    % 打印每轮温度的优化信息（每10次温度衰减打印一次，避免输出过多）
    if mod(floor(T0 / T), 10) == 0
        fprintf('温度T=%.4e | 当前dt=%.6f | 全局最优dt=%.6f\n', ...
            T, current_dt, best_dt);
    end
end

%% 4. 输出优化结果
fprintf('\n================================ 优化结果 ================================\n');
fprintf('固定参数：theta = %.4f 弧度\n', theta_fixed);
fprintf('最优参数：\n');
fprintf('  v    = %.6f （范围：70~140）\n', best_sol(1));
fprintf('  t1   = %.6f s （范围：0~0.5）\n', best_sol(2));
fprintf('  t2   = %.6f s （范围：0~0.5）\n', best_sol(3));
fprintf('最大dt值：%.6f\n', best_dt);
fprintf('==========================================================================\n');

%% 5. 绘制迭代过程曲线（分析算法收敛性）
figure('Position', [100, 100, 1200, 600]);

% 子图1：温度随迭代次数变化
subplot(1,2,1);
plot(iter_record, T_record, 'b-', 'LineWidth', 1.2);
xlabel('迭代次数', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('温度 T', 'FontSize', 11, 'FontWeight', 'bold');
title('模拟退火温度衰减曲线', 'FontSize', 12, 'FontWeight', 'bold');
grid on; grid minor;
set(gca, 'YScale', 'log');  % 对数坐标显示温度（更清晰）

% 子图2：当前解与最优解的dt随迭代次数变化
subplot(1,2,2);
plot(iter_record, current_dt_record, 'c-', 'LineWidth', 1, 'DisplayName', '当前解dt');
hold on;
plot(iter_record, best_dt_record, 'r-', 'LineWidth', 1.5, 'DisplayName', '全局最优dt');
xlabel('迭代次数', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('dt 值', 'FontSize', 11, 'FontWeight', 'bold');
title('迭代过程中dt值变化', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
grid on; grid minor;
hold off;

%% 6. 嵌入目标函数（fitness_function，确保代码可独立运行）
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

    % 提取坐标分量并计算二次方程系数
    X1 = GRD_2(1); Y1 = GRD_2(2); Z1 = GRD_2(3);
    X2 = M_2(1);   Z2 = X2 / 10;
    alpha = 3000 / sqrt(101);
    beta = alpha / 10;
    a = alpha^2 + (beta - 3)^2;
    b = 2 * alpha * (X1 - X2) + 2 * (beta - 3) * (Z1 - Z2);
    c = (X1 - X2)^2 + Y1^2 + (Z1 - Z2)^2 - 10^2;

    % 求解dt（基于判别式判断根的有效性）
    discriminant = b^2 - 4 * a * c;
    if discriminant <= 0
        dt = 0;  % 无实根时dt取0（适应度最低）
    else
        % 求解二次方程并调整根的顺序
        t_1 = (-b + sqrt(discriminant)) / (2 * a);
        t_2 = (-b - sqrt(discriminant)) / (2 * a);
        if t_1 > t_2
            tmp = t_1; t_1 = t_2; t_2 = tmp;
        end
        % 应用t2<=20的约束（当前t1/t2≤0.5，t2必然≤20，此处保留原逻辑）
        if t_2 >= 20
            t_2 = 20;
        end
        dt = max(t_2 - t_1, 0);  % 确保dt非负
    end
end