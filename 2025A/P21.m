%% 1. 定义二次方程求解函数 s2e (与原逻辑一致)
function sol = s2e(a, b, c)
    if a == 0 || (b^2 - 4*a*c) < 0
        sol = [];  
    else
        delta = sqrt(b^2 - 4*a*c);
        x1 = (-b + delta) / (2*a);
        x2 = (-b - delta) / (2*a);
        sol = [x1, x2];  
    end
end


%% 2. 定义目标函数 dt (与原逻辑一致)
function dt_val = dt(th, v, t1, t2)
    g = 9.8;
    alpha = 3000 / sqrt(101);
    beta = 300 / sqrt(101);
    
    % 计算M和GRD点坐标
    M = [20000 - (t1 + t2)*alpha, 0, 2000 - (t1 + t2)*beta];
    GRD = [17800 + v*(t1 + t2)*cos(th), ...
           v*(t1 + t2)*sin(th), ...
           1800 - 0.5*g*t2^2];
    
    % 生成网格点（与原逻辑一致，避免重复计算2π）
    mesh = [];
    for theta = 0:0.1:2*pi - 1e-6
        for r = 0:0.1:7
            x = r * cos(theta);
            y = 200 + r * sin(theta);
            z = 10;
            mesh = [mesh; x, y, z];
        end
    end
    for theta = 0:0.1:2*pi - 1e-6
        for z = 0:0.1:10
            x = 7 * cos(theta);
            y = 200 + 7 * sin(theta);
            mesh = [mesh; x, y, z];
        end
    end
    
    % 内部检测函数 solvek（判断线段是否与球相交）
    function ifclose = solvek(t)
        ifclose = false;
        M_new = [M(1) - alpha*t, 0, M(3) - beta*t];
        G_new = [GRD(1), 0, GRD(3) - 3*t];
        
        for i = 1:size(mesh, 1)
            point = mesh(i, :);
            P1 = point(1); P2 = point(2); P3 = point(3);
            M1 = M_new(1); M2 = M_new(2); M3 = M_new(3);
            G1 = G_new(1); G2 = G_new(2); G3 = G_new(3);
            
            % 计算二次方程系数
            a = (M1 - P1)^2 + (M2 - P2)^2 + (M3 - P3)^2;
            b = -2 * ((M1 - P1)*(G1 - P1) + (M2 - P2)*(G2 - P2) + (M3 - P3)*(G3 - P3));
            c = (G1 - P1)^2 + (G2 - P2)^2 + (G3 - P3)^2 - 10^2;
            
            % 判断是否有根在[0,1]范围内（允许微小误差）
            sol = s2e(a, b, c);
            if ~isempty(sol) && any(sol >= 0 - 1e-6) && any(sol <= 1 + 1e-6)
                ifclose = true;
            else
                ifclose = false;
                break;  % 一个点不相交则整体不相交，提前退出
            end
        end
    end
    
    % 时间遍历统计满足条件的t数量
    cntt = 0;
    t_start = 0;
    t_end = 60;
    t_step = 0.1;
    t_list = t_start:t_step:t_end;
    
    for t = t_list
        ifclose = solvek(t);
        if ifclose
            cntt = cntt + 1;
        end
    end
    
    % 计算最终dt值
    dt_val = (cntt - 1) * t_step;
end


%% 3. 按指定范围和步长遍历所有参数组合，计算并输出dt值
clear; clc; close all;

% ===================== 1. 设置参数范围和步长 =====================
% th: (-7π/8, -9π/8)，步长π/128（注意：-9π/8 < -7π/8，故起点为-9π/8，终点为-7π/8）
pi_val = pi;  % 定义π（避免重复计算）
th_start = -9 * pi_val / 8;
th_end = -7 * pi_val / 8;
th_step = pi_val / 128;
th_list = th_start:th_step:th_end;  % 生成th的所有取值

% v: 70~140，步长5
v_list = 70:5:140;

% t1: 0~5，步长0.5
t1_list = 0:0.5:5;

% t2: 0~5，步长0.5
t2_list = 0:0.5:5;

% ===================== 2. 计算总参数组合数（显示进度用） =====================
total_num = length(th_list) * length(v_list) * length(t1_list) * length(t2_list);
current_num = 0;  % 当前已计算的组合数
fprintf('总参数组合数：%d\n', total_num);
fprintf('开始计算dt值...\n');
fprintf('=============================\n');

% ===================== 3. 初始化结果存储表格 =====================
% 表格列：th(弧度)、th(度)、v、t1、t2、dt值
result_table = table(...
    zeros(total_num, 1), ...  % th_rad
    zeros(total_num, 1), ...  % th_deg
    zeros(total_num, 1), ...  % v
    zeros(total_num, 1), ...  % t1
    zeros(total_num, 1), ...  % t2
    zeros(total_num, 1), ...  % dt_val
    'VariableNames', {'th_rad', 'th_deg', 'v', 't1', 't2', 'dt_val'});

% ===================== 4. 遍历所有参数组合，计算dt值 =====================
for i = 1:length(th_list)
    th = th_list(i);
    th_deg = rad2deg(th);  % 转换为角度（方便阅读）
    
    for j = 1:length(v_list)
        v = v_list(j);
        
        for k = 1:length(t1_list)
            t1 = t1_list(k);
            
            for l = 1:length(t2_list)
                t2 = t2_list(l);
                
                % 计算当前组合的dt值
                dt_val = dt(th, v, t1, t2);
                
                % 更新当前计数和结果表格
                current_num = current_num + 1;
                result_table(current_num, :) = {th, th_deg, v, t1, t2, dt_val};
                
                % 每计算100个组合显示一次进度（避免无反馈）
                if mod(current_num, 100) == 0 || current_num == total_num
                    fprintf('进度：%d/%d (%.2f%%) | 当前参数：th=%.4f rad(%.2f°), v=%.0f, t1=%.1f, t2=%.1f | dt=%.4f\n', ...
                        current_num, total_num, current_num/total_num*100, ...
                        th, th_deg, v, t1, t2, dt_val);
                end
            end
        end
    end
end

% ===================== 5. 输出结果 =====================
% 1. 在命令行显示前10行结果（避免输出过长）
fprintf('\n=============================\n');
fprintf('前10行结果预览：\n');
disp(result_table(1:min(10, total_num), :));

% 2. 将完整结果保存到Excel文件（方便后续分析）
output_file = 'dt_values_result.xlsx';
writetable(result_table, output_file);
fprintf('\n完整结果已保存到：%s\n', fullfile(pwd, output_file));

% 3. 统计dt值的基本信息（最大值、最小值、平均值）
dt_min = min(result_table.dt_val);
dt_max = max(result_table.dt_val);
dt_mean = mean(result_table.dt_val);
fprintf('\ndt值统计：\n');
fprintf('  最小值：%.4f\n', dt_min);
fprintf('  最大值：%.4f\n', dt_max);
fprintf('  平均值：%.4f\n', dt_mean);