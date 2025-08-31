clear; clc; close all;

%% define consts
m1 = 2433;              % 振子质量 (kg)
m2 = 4866;              % 浮子质量 (kg)
me = 1335.535;          % 附加惯性质量 (kg)
K = 80000;              % 弹簧刚度 (N/m)
C = 10000;              % 阻尼系数 (N·s/m)
CL = 656.3616;          % 兴波阻尼系数 (N·s/m)
rho_gA = 1025*9.8*pi;   % 静水恢复刚度 (N/m)
f0 = 6250;              % 波浪激励力振幅 (N)
omega = 1.4005;         % 激励角频率 (rad/s)

tspan = [0, 100];       % 时间范围 [起始, 结束]

initial_conditions = [0; 0; 0; 0];

%% define solver
options = odeset(...
    'RelTol', 1e-6, ...
    'AbsTol', [1e-8; 1e-8; 1e-8; 1e-8], ...
    'MaxStep', 0.001, ...
    'OutputFcn', @odeplot ...
);


[t, y] = ode45(...
    @(t,y) pto_system(t, y, m1, m2, me, K, C, CL, rho_gA, f0, omega), ...
    tspan, ...
    initial_conditions, ...
    options);


z1 = y(:, 1);       % 振子位移
z2 = y(:, 2);       % 浮子位移
zdot1 = y(:, 3);    % 振子速度
zdot2 = y(:, 4);    % 浮子速度
zr = z1 - z2;       % 相对位移

%% render the result
figure;
subplot(3,1,1);
plot(t, z1, 'b', t, z2, 'r');
xlabel('时间 (s)');
ylabel('位移 (m)');
legend('振子位移 z1', '浮子位移 z2');
title('振子和浮子的位移响应');
grid on;

subplot(3,1,2);
plot(t, zdot1, 'b', t, zdot2, 'r');
xlabel('时间 (s)');
ylabel('速度 (m/s)');
legend('振子速度', '浮子速度');
grid on;

subplot(3,1,3);
plot(t, zr, 'g');
xlabel('时间 (s)');
ylabel('相对位移 (m)');
title('振子相对于浮子的位移');
grid on;


time_points = [10, 20, 40, 60, 100];

fprintf('高精度特定时间点结果：\n');
fprintf('时间(s)\t振子位移(m)\t振子速度(m/s)\t浮子位移(m)\t浮子速度(m/s)\n');

for i = 1:length(time_points)
    z1_interp = interp1(t, z1, time_points(i), 'spline');
    z2_interp = interp1(t, z2, time_points(i), 'spline');
    zdot1_interp = interp1(t, zdot1, time_points(i), 'spline');
    zdot2_interp = interp1(t, zdot2, time_points(i), 'spline');
    
    results.Z1_Displacement(i) = z1_interp;
    results.Z1_Velocity(i) = zdot1_interp;
    results.Z2_Displacement(i) = z2_interp;
    results.Z2_Velocity(i) = zdot2_interp;
    
    fprintf('%.1f\t%.8f\t%.8f\t%.8f\t%.8f\n', ...
        time_points(i), ...
        z1_interp, ...
        zdot1_interp, ...
        z2_interp, ...
        zdot2_interp);
end


%% function and equals
function dydt = pto_system(t, y, m1, m2, me, K, C, CL, rho_gA, f0, omega)
    % functions
    z1 = y(1);
    z2 = y(2);
    zdot1 = y(3);
    zdot2 = y(4);
    
    % f_{3}
    f_wave = f0 * cos(omega * t);
    
    % ddot
    zddot1 = (-K*(z1 - z2) - C*sqrt(abs(zdot1-zdot2))*(zdot1 - zdot2)) / m1;
    zddot2 = (f_wave - CL*zdot2 - rho_gA*z2 - m1*zddot1) / (m2 + me);
    
    % define func
    dydt = [zdot1;
            zdot2;
            zddot1;
            zddot2];
end
