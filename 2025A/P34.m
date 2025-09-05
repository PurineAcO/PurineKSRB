% 极简版：调用MATLAB自带遗传算法工具箱优化ccnt函数
% 仅保留参数上下界，无任何其他约束

%% 1. 核心参数配置（仅3个关键设置）
nvars = 8;  % 优化参数：[v, th, t1, t2, t3, t4, t5, t6]
lb = [70, 7*pi/8, 0, 0, 1, 0, 2, 0];    % 参数下界
ub = [140, pi, 15, 15, 15, 15, 15, 15]; % 参数上界

%% 2. 工具箱选项（极简配置，仅显示进度+画适应度曲线）
options = optimoptions('ga', ...
    'PopulationSize', 50, ...    % 种群大小（默认30，稍调大提升搜索性）
    'MaxGenerations', 30, ...    % 最大迭代次数（平衡效率与效果）
    'Display', 'iter', ...       % 显示每代迭代进度
    'PlotFcn', @gaplotbestf);    % 绘制最佳适应度曲线

%% 3. 调用工具箱优化（核心一行代码）
% 注：ga默认最小化，故对max(ccnt)取负转为min(-ccnt)
[best_params, best_fitness] = ga(@(x)-ccnt(x), nvars, [], [], [], [], lb, ub, [], options);

%% 4. 结果输出（直观展示最优解）
fprintf('\n================ 优化结果 ================\n');
fprintf('最佳ccnt值（目标函数值）：%d\n', -best_fitness);
fprintf('最佳参数：\n');
fprintf('v       = %.2f （70~140）\n', best_params(1));
fprintf('th      = %.4f 弧度 = %.2f 度 （7π/8~π）\n', best_params(2), rad2deg(best_params(2)));
fprintf('t1      = %.2f, t2 = %.2f （0~15）\n', best_params(3), best_params(4));
fprintf('t3      = %.2f, t4 = %.2f （0~15）\n', best_params(5), best_params(6));
fprintf('t5      = %.2f, t6 = %.2f （0~15）\n', best_params(7), best_params(8));



% ---------------------- 以下为原逻辑不变的辅助函数 ----------------------
% 目标函数：ccnt（与你提供的Python逻辑完全一致）
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