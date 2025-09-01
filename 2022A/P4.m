% 定义已知参数值
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
C = 58944;        
Ie = 7142.493;       
I2 = 8398.43436369;       
M0 = 2140;       
MCL = 1655.909;      
M3 = 8890.7;       
MC = 98227;       
MK = 250000;      

% 初值条件：所有变量初始值为0
% 状态向量：[z1; z2; theta1; theta2; zdot1; zdot2; thetadot1; thetadot2]
initial_conditions = zeros(8, 1);

% 求解时间范围（覆盖积分区间）
tspan = [0, 200*pi/omega];  

%% 定义求解器选项
options = odeset(...
    'RelTol', 1e-6, ...
    'AbsTol', 1e-8, ...  % 使用标量简化设置，适用于所有状态变量
    'MaxStep', 0.001 ...
);

% 调用ode45求解器
[t, sol] = ode45(@(t, y) system_equations(t, y, me, m1, m2, f0, omega, CL, ...
    rho, g, A, K, C, Ie, I2, M0, MCL, M3, MC, MK), tspan, initial_conditions, options);

% 提取结果
zdot1 = sol(:, 5);
zdot2 = sol(:, 6);
thetadot1 = sol(:, 7);
thetadot2 = sol(:, 8);

% 计算积分区间的起始和结束时间
t_start = 100*pi/omega;
t_end = 200*pi/omega;

% 找到积分区间内的索引
idx_start = find(t >= t_start, 1, 'first');
idx_end = find(t <= t_end, 1, 'last');

% 提取积分区间内的速度和角速度
zdot1_interval = zdot1(idx_start:idx_end);
zdot2_interval = zdot2(idx_start:idx_end);
thetadot1_interval = thetadot1(idx_start:idx_end);
thetadot2_interval = thetadot2(idx_start:idx_end);

% 计算时间步长
dt = t(2) - t(1);

% 计算P_bar
P_bar = 0;
for i = 1:length(zdot1_interval)
    dz_dot = zdot1_interval(i) - zdot2_interval(i);
    dtheta_dot = thetadot1_interval(i) - thetadot2_interval(i);
    P_bar = P_bar + (C * (dz_dot)^2 + MC * (dtheta_dot)^2) * dt;
end
P_bar=P_bar / (t_end - t_start);

% 显示结果
fprintf('P_bar = %f\n', P_bar);

% 绘制功率随时间的变化
P_time = zeros(size(t));
for i = 1:length(t)
    dz_dot = zdot1(i) - zdot2(i);
    dtheta_dot = thetadot1(i) - thetadot2(i);
    P_time(i) = C * (dz_dot)^2 + MC * (dtheta_dot)^2;
end

figure;
plot(t, P_time);
xlabel('时间 (s)');
ylabel('功率');
title('功率随时间的变化');
xlim([t_start t_end]);
ylim([0 max(P_time(idx_start:idx_end)) * 1.1]);

function dydt = system_equations(t, y, me, m1, m2, f0, omega, CL, rho, g, A, K, C, Ie, I2, M0, MCL, M3, MC, MK)
    % 状态变量
    z1 = y(1);
    z2 = y(2);
    theta1 = y(3);
    theta2 = y(4);
    zdot1 = y(5);
    zdot2 = y(6);
    thetadot1 = y(7);
    thetadot2 = y(8);
    
    % 计算I1，1表示振子，2表示浮子
    I1 = 202.75 + 2433 * (0.75 + z1 - z2)^2;
    
    % 振子垂荡通道
    zddot1 = (-K*(z1 - z2) - C*(zdot1 - zdot2)) / m1;
    
    % 代入第一个方程求解z2的二阶导数
    zddot2 = (f0*cos(omega*t) - CL*zdot2 - rho*g*A*z2 - m1*zddot1) / (m2 + me);
    
    % 从第四个方程求解theta1的二阶导数
    thetaddot1 = (-MC*(thetadot1 - thetadot2) - MK*(theta1 - theta2)) / I1;
    
    % 代入第三个方程求解theta2的二阶导数
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