%% GA优化部分
clear; clc; close all;

% 优化参数配置
nVars = 4;                  
lb = [pi-0.1, 70, 0, 0];         
ub = [pi+0.1, 100, 1, 1];                   

% GA设置
options = optimoptions('ga', ...
    'PopulationSize', 100, ...    
    'MaxGenerations', 15, ...    
    'CrossoverFraction', 0.6, ...
    'MutationFcn', @mutationadaptfeasible, ...  
    'Display', 'iter', ...       
    'PlotFcn', @gaplotbestf);    

[x_opt, fval, exitflag, output] = ga(@ga_fitness, nVars, [], [], [], [], lb, ub, [], intcon, options);
dt_opt = -fval;

fprintf('==================== 遗传算法优化结果 ====================\n');
fprintf('最优参数组合：\n');
fprintf('  角度 th = %.4f 弧度 (%.2f 度)\n', x_opt(1), rad2deg(x_opt(1)));
fprintf('  速度 v = %.4f\n', x_opt(2));
fprintf('  时间 t1 = %.4f\n', x_opt(3));
fprintf('  时间 t2 = %.4f\n', x_opt(4));
fprintf('最优参数对应的dt值：%.4f\n', dt_opt);


%% 原型函数（同supple)
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


function dt_val = dt(th, v, t1, t2)
    g = 9.8;
    alpha = 3000 / sqrt(101);
    beta = 300 / sqrt(101);
    
    M = [20000 - (t1 + t2)*alpha, 0, 2000 - (t1 + t2)*beta];
    GRD = [17800 - v*(t1 + t2)*cos(th), ...
           v*(t1 + t2)*sin(th), ...
           1800 - 0.5*g*t2^2];
    
    % 生成网格点
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
    
    function [t, ifclose] = solvek(t)
        ifclose = false;
        M_new = [M(1) - alpha*t, 0, M(3) - beta*t];
        G_new = [GRD(1), GRD(2), GRD(3) - 3*t];
        
        for i = 1:size(mesh, 1)
            point = mesh(i, :);
            P1 = point(1); P2 = point(2); P3 = point(3);
            M1 = M_new(1); M2 = M_new(2); M3 = M_new(3);
            G1 = G_new(1); G2 = G_new(2); G3 = G_new(3);
            
            a = (M1 - P1)^2 + (M2 - P2)^2 + (M3 - P3)^2;
            b = -2 * ((M1 - P1)*(G1 - P1) + (M2 - P2)*(G2 - P2) + (M3 - P3)*(G3 - P3));
            c = (G1 - P1)^2 + (G2 - P2)^2 + (G3 - P3)^2 - 10^2;
            
            sol = s2e(a, b, c);
            if ~isempty(sol) && any(sol >= 0 - 1e-6) && any(sol <= 1 + 1e-6)
                ifclose = true;
            else
                ifclose = false;
                break;
            end
        end
    end
    
    cntt = 0;
    t_start = 0;
    t_end = 10;
    t_step = 0.002;
    t_list = t_start:t_step:t_end;
    
    for t = t_list
        [~, ifclose] = solvek(t);
        if ifclose
            cntt = cntt + 1;
        end
    end
    
    dt_val = (cntt - 1) * t_step;
end


function fitness = ga_fitness(x)
    th = x(1);   
    v = x(2);    
    t1 = x(3);  
    t2 = x(4);  
    
    dt_val = dt(th, v, t1, t2);
    fitness = -dt_val;  
end
