% 定义已知参数值
me = 1028.876;       
m1 = 2433;       
m2 = 4866;
f0 = 3640;       
omega = 1.7152;    
CL = 683.4558;       
rho = 1025;      
g = 9.8;     
A = pi;        
K = 80000;        
C = 10000;        
Ie = 7001.914;       
I2 = 8289.43436369;       
M0 = 1690;       
MCL = 654.3383;      
M3 = 8890.7;       
MC = 1000;       
MK = 250000;      

% 初值条件：所有变量初始值为0
% 状态向量：[z1; z2; theta1; theta2; zdot1; zdot2; thetadot1; thetadot2]
initial_conditions = zeros(8, 1);

% 求解时间范围
tspan = [0, 100];  % 从0到100秒

%% 定义求解器选项
options = odeset(...
    'RelTol', 1e-6, ...
    'AbsTol', 1e-8,...  % 使用标量简化设置，适用于所有状态变量
    'MaxStep', 0.001, ...
    'OutputFcn', @odeplot ...
);

% 调用ode45求解器
[t, sol] = ode45(@(t, y) system_equations(t, y, me, m1, m2, f0, omega, CL, ...
    rho, g, A, K, C, Ie, I2, M0, MCL, M3, MC, MK), tspan, initial_conditions, options);

% 提取结果
z1 = sol(:, 1);
z2 = sol(:, 2);
theta1 = sol(:, 3);
theta2 = sol(:, 4);
zdot1 = sol(:, 5);
zdot2 = sol(:, 6);
thetadot1 = sol(:, 7);
thetadot2 = sol(:, 8);

% 定义需要查询的时间点
query_times = [10, 20, 40, 60, 100];

% 创建结果表格
results = table();
results.Time = query_times;

% 插值计算各时间点的数值
results.z1 = interp1(t, z1, query_times);
results.z2 = interp1(t, z2, query_times);
results.theta1 = interp1(t, theta1, query_times);
results.theta2 = interp1(t, theta2, query_times);
results.zdot1 = interp1(t, zdot1, query_times);
results.zdot2 = interp1(t, zdot2, query_times);
results.thetadot1 = interp1(t, thetadot1, query_times);
results.thetadot2 = interp1(t, thetadot2, query_times);

% 显示结果
disp('特定时间点的计算结果：');
disp(results);

% 绘制结果
figure;
subplot(2,2,1);
plot(t, z1, t, z2);
hold on;
plot(query_times, results.z1, 'ro', query_times, results.z2, 'go');
legend('z1', 'z2', 'z1查询点', 'z2查询点');
xlabel('时间 (s)');
ylabel('位移');
title('z1和z2随时间变化');

subplot(2,2,2);
plot(t, theta1, t, theta2);
hold on;
plot(query_times, results.theta1, 'ro', query_times, results.theta2, 'go');
legend('\theta1', '\theta2', '\theta1查询点', '\theta2查询点');
xlabel('时间 (s)');
ylabel('角度 (rad)');
title('\theta1和\theta2随时间变化');

subplot(2,2,3);
plot(t, zdot1, t, zdot2);
hold on;
plot(query_times, results.zdot1, 'ro', query_times, results.zdot2, 'go');
legend('z1速度', 'z2速度', 'z1速度查询点', 'z2速度查询点');
xlabel('时间 (s)');
ylabel('速度');
title('速度随时间变化');

subplot(2,2,4);
plot(t, thetadot1, t, thetadot2);
hold on;
plot(query_times, results.thetadot1, 'ro', query_times, results.thetadot2, 'go');
legend('\theta1角速度', '\theta2角速度', '\theta1角速度查询点', '\theta2角速度查询点');
xlabel('时间 (s)');
ylabel('角速度 (rad/s)');
title('角速度随时间变化');


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
    