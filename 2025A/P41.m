function optimize_ccnt()
    % 定义变量范围: v(0-200), t1(0-5), t2(0-5)
    lb = [70, 0, 0];       % 下界
    ub = [140, 10, 10];     % 上界
    
    % 设置遗传算法参数
    options = gaoptimset('PopulationSize', 70,'Generations', 15,'EliteCount', 15,'CrossoverFraction', 0.8,'Display', 'iter');
    
    % 运行遗传算法
    [x, fval] = ga(@(x) -ccnt(x(1), x(2), x(3)), 3, [], [], [], [], lb, ub, [], options);
    
    % 显示优化结果
    fprintf('优化结果:\n');
    fprintf('v = %.4f\n', x(1));
    fprintf('t1 = %.4f\n', x(2));
    fprintf('t2 = %.4f\n', x(3));
    fprintf('最大ccnt值: %.0f\n', -fval);
end

function [ox, oy] = MissilePlace(t)
    alpha = 3000 / sqrt(101);
    beta = 300 / sqrt(101);
    ox = 20000 - alpha * t;
    oy = 2000 - beta * t;
end

function [gx, gy] = GRDPlace(t, v, t1, t2)
    if t < t1
        gx = 17800 - v * t;
        gy = 1800;
    elseif t < t1 + t2
        gx = 17800 - v * t;
        gy = 1800 - 0.5 * 9.8 * (t - t1)^2;
    else
        gx = 17800 - v * (t1 + t2);
        gy = 1800 - 0.5 * 9.8 * t2^2 - 3 * (t - t1 - t2);  % 修正原代码中的3(t...)语法
    end
end

function dist = lengther(t, v, t1, t2)
    [ox, oy] = MissilePlace(t);
    [gx, gy] = GRDPlace(t, v, t1, t2);
    
    % 计算平面内点到直线的距离
    cross_mod = abs(ox * gy - oy * gx);
    om_mod = sqrt(ox^2 + oy^2);
    
    if om_mod < 1e-6  % 避免除零
        dist = 0;
    else
        dist = cross_mod / om_mod;
    end
end

function count = ccnt(v, t1, t2)
    count = 0;
    t_values = 0:0.1:10;  % 时间从0到10，步长0.1
    for t = t_values
        if lengther(t, v, t1, t2) < 10
            count = count + 1;
        end
    end
end
    