% 定义已知固定参数
   

% 定义目标函数（适应度函数），返回负的P_bar，因为ga默认最小化
function fitness = objfun(x)
    C = x(1);
    MC = x(2);
    
    % 初值条件
    initial_conditions = zeros(8, 1);
    
    % 求解时间范围
    t_end_total = 200*pi/omega;
    tspan = [0, t_end_total];  
    
    % 求解器选项
    options = odeset(...
        'RelTol', 1e-6, ...
        'AbsTol', 1e-8, ...
        'MaxStep', 0.001 ...
    );
    
    % 调用ode45求解器
    [t, sol] = ode45(@(t, y) system_equations(t, y, C, MC), tspan, initial_conditions, options);
    
    % 提取结果
    zdot1 = sol(:, 5);
    zdot2 = sol(:, 6);
    thetadot1 = sol(:, 7);
    thetadot2 = sol(:, 8);
    
    % 计算积分区间
    t_start = 100*pi/omega;
    t_end = 200*pi/omega;
    
    % 找到积分区间索引
    idx_start = find(t >= t_start, 1, 'first');
    idx_end = find(t <= t_end, 1, 'last');
    
    % 处理边界情况
    if isempty(idx_start) || isempty(idx_end) || idx_start > idx_end
        fitness = -1e-9; % 极小值，避免错误
        return;
    end
    
    % 提取区间内数据
    zdot1_interval = zdot1(idx_start:idx_end);
    zdot2_interval = zdot2(idx_start:idx_end);
    thetadot1_interval = thetadot1(idx_start:idx_end);
    thetadot2_interval = thetadot2(idx_start:idx_end);
    t_interval = t(idx_start:idx_end);
    
    % 计算P_bar（时间加权积分）
    P_vals = C * (zdot1_interval - zdot2_interval).^2 + MC * (thetadot1_interval - thetadot2_interval).^2;
    P_bar = trapz(t_interval, P_vals) / (t_end - t_start);
    
    fitness = -P_bar; % GA默认最小化，所以返回负的P_bar以最大化
end

% 系统微分方程（内部使用，依赖外部固定参数）
function dydt = system_equations(t, y, C, MC)
    % 外部固定参数
    me = 1091.099;       
    m1 = 2433;       
    m2 = 4866;
    f0 = 1760;       
    omega = 1.9806;    
    CL = 528.5018;       
    rho = 1025;      
    g = 9.8;     
    A = pi;        
    K = 80000;        
    Ie = 7142.493;       
    I2 = 8398.43436369;       
    M0 = 2140;       
    MCL = 1655.909;      
    M3 = 8890.7;       
    MK = 250000;   
    
    % 状态变量
    z1 = y(1);
    z2 = y(2);
    theta1 = y(3);
    theta2 = y(4);
    zdot1 = y(5);
    zdot2 = y(6);
    thetadot1 = y(7);
    thetadot2 = y(8);
    
    % 计算I1
    I1 = 202.75 + 2433 * (0.75 + z1 - z2)^2;
    
    % 振子垂荡通道
    zddot1 = (-K*(z1 - z2) - C*(zdot1 - zdot2)) / m1;
    
    % 浮子垂荡通道
    zddot2 = (f0*cos(omega*t) - CL*zdot2 - rho*g*A*z2 - m1*zddot1) / (m2 + me);
    
    % 振子旋转通道
    thetaddot1 = (-MC*(thetadot1 - thetadot2) - MK*(theta1 - theta2)) / I1;
    
    % 浮子旋转通道
    thetaddot2 = (M0*cos(omega*t) - MCL*thetadot2 - M3*theta2 - I1*thetaddot1) / (I2 + Ie);
    
    % 构造一阶微分方程组
    dydt = [
        zdot1;               % z1的一阶导数
        zdot2;               % z2的一阶导数
        thetadot1;           % theta1的一阶导数
        thetadot2;           % theta2的一阶导数
        zddot1;              % z1的二阶导数
        zddot2;              % z2的二阶导数
        thetaddot1;          % theta1的二阶导数
        thetaddot2           % theta2的二阶导数
    ];
end

% 主函数：调用GA进行优化



% 赋值全局变量
me = 1091.099;       
m1 = 2433;       
m2 = 4866;
f0 = 1760;       
omega = 1.9806;    
CL = 528.5018;       
rho = 1025;      
g = 9.8;     
A = pi;        
K = 80000;        
Ie = 7142.493;       
I2 = 8398.43436369;       
M0 = 2140;       
MCL = 1655.909;      
M3 = 8890.7;       
MK = 250000;      

% 定义变量个数和范围
nvars = 2; % C和MC两个变量
lb = [0, 0]; % 下界
ub = [100000, 100000]; % 上界

% 调用GA优化
options = optimoptions('ga', ...
    'PopulationSize', 50, ...
    'MaxGenerations', 50, ...
    'Display', 'iter', ...
    'PlotFcn', @gaplotbestf);

[x_opt, fval_opt] = ga(@objfun, nvars, [], [], [], [], lb, ub, [], options);

% 显示结果
fprintf('最优参数：C = %.1f, MC = %.1f\n', x_opt(1), x_opt(2));
fprintf('最大P_bar = %.4f\n', -fval_opt);

% 绘制最优参数下的功率曲线
plot_optimal_power(x_opt);