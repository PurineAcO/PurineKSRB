
% 定义已知参数值（这里使用示例值，需要根据实际情况修改）
me = 1028.876;       % 示例值
m1 = 2433;       % 示例值
m2 = 4866;
f0 = 3640;       % 示例值
omega = 1.7152;    % 示例值
CL = 683.4558;       % 示例值
rho = 1025;      % 示例值
g = 9.8;     % 重力加速度
A = pi;        % 示例值
K = 80000;        % 示例值
C = 10000;        % 示例值
Ie = 7001.914;       % 示例值
I2 = 8289;       % 示例值
M0 = 1690;       % 示例值
MCL = 654.3383;      % 示例值
M3 = 8890.7;       % 示例值
MC = 1000;       % 示例值
MK = 250000;       % 示例值

% 初值条件：所有变量初始值为0
% 状态向量：[z1; z2; theta1; theta2; zdot1; zdot2; thetadot1; thetadot2]
initial_conditions = zeros(8, 1);

% 求解时间范围
tspan = [0,100];  % 从0到10秒

%% define solver
options = odeset(...
    'RelTol', 1e-6, ...
    'AbsTol', [1e-8; 1e-8; 1e-8; 1e-8], ...
    'MaxStep', 0.001, ...
    'OutputFcn', @odeplot ...
);


% 调用ode45求解器
[t, sol] = ode45(@(t, y) system_equations(t, y, me, m1,m2, f0, omega, CL, ...
    rho, g, A, K, C, Ie, I1, M0, MCL, M3, MC, MK), tspan, initial_conditions, options);

% 提取结果
z1 = sol(:, 1);
z2 = sol(:, 2);
theta1 = sol(:, 3);
theta2 = sol(:, 4);
zdot1 = sol(:, 5);
zdot2 = sol(:, 6);
thetadot1 = sol(:, 7);
thetadot2 = sol(:, 8);

% 绘制结果
figure;
subplot(2,2,1);
plot(t, z1, t, z2);
legend('z1', 'z2');
xlabel('时间');
ylabel('位移');
title('z1和z2随时间变化');

subplot(2,2,2);
plot(t, theta1, t, theta2);
legend('\theta1', '\theta2');
xlabel('时间');
ylabel('角度');
title('\theta1和\theta2随时间变化');

subplot(2,2,3);
plot(t, zdot1, t, zdot2);
legend('z1速度', 'z2速度');
xlabel('时间');
ylabel('速度');
title('速度随时间变化');

subplot(2,2,4);
plot(t, thetadot1, t, thetadot2);
legend('\theta1角速度', '\theta2角速度');
xlabel('时间');
ylabel('角速度');
title('角速度随时间变化');


function dydt = system_equations(t, y, me, m1, m2,f0, omega, CL, rho, g, A, K, C, Ie, I2, M0, MCL, M3, MC, MK)
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
    I1 = 202.75 + 2433 * (0.75 + z1 - z2);
    
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
    