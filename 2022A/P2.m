clear; clc; close all;


%% define solver
function dydt=solver(t,y,C)
    
    % define some consts
    m1 = 2433;                          % 振子质量 (kg)
    m2 = 4866;                          % 浮子质量 (kg)
    me = 1165.992;                      % 附加惯性质量 (kg)
    K = 80000;                          % 弹簧刚度 (N/m)
    CL = 167.8395;                      % 兴波阻尼系数 (N·s/m)
    rho_gA = 1025*9.8*pi;               % 静水恢复刚度 (N/m)
    f0 = 4890;                          % 波浪激励力振幅 (N)
    omega = 2.2143;                     % 激励角频率 (rad/s)

    % define the cols where is f^(0)
    z1=y(1);                            % 振子位移
    z2=y(2);                            % 浮子位移
    zdot1=y(3);                         % 振子速度
    zdot2=y(4);                         % 浮子速度

    % wave force
    f_wave=f0*cos(omega*t);

    % calculate acceleration
    zddot1 = (-K*(z1 - z2) - C*(zdot1 - zdot2)) / m1;
    zddot2 = (f_wave - CL*zdot2 - rho_gA*z2 - m1*zddot1) / (m2 + me);

    % define the cols where is f^(1)
    dydt=[zdot1;
          zdot2;
          zddot1;
          zddot2];  

end
%% define the J
function P = calc_P(C)

    % define some consts
    omega=2.2143;                           % 稳态圆频率 (rad/s)
    tspan = 0:0.1:200*2*pi/omega;           % 仿真时间网格 (s)
    initial_conditions = [0; 0; 0; 0];      % 初始条件
    start_time = 100*2*pi/omega;            % 积分开始时间 (s)
    end_time = 200*2*pi/omega;              % 积分结束时间 (s)
    T = end_time - start_time;              % 积分时间长度 (s)
    alpha = 0;                              % 功率公式指数

    % define the ode solver
    options_ode = odeset(...
        'RelTol', 1e-6, ...
        'AbsTol', [1e-8; 1e-8; 1e-8; 1e-8], ...
        'MaxStep', 0.001);
    [t, y] = ode45(@(t,y) solver(t,y,C), tspan, initial_conditions, options_ode);

    % calc the P
    idx = t >= start_time & t <= end_time;
    t_selected = t(idx);
    zdot1_selected = y(idx, 3);
    zdot2_selected = y(idx, 4);
    relative_velocity = zdot1_selected - zdot2_selected;
    instantaneous_power = C * abs(relative_velocity).^(2 + alpha);
    total_energy = trapz(t_selected, instantaneous_power);  
    P = total_energy / T; 
end
%% define GA
% define some consts
nvars = 1;                          % 优化变量数量
lb = 0;                             % 变量下界
ub = 50000;                        % 变量上界
PopulationSize = 50;                % 种群规模
MaxGenerations = 5;                % 最大迭代次数
CrossoverFraction = 0.8;            % 交叉概率

% define GA
ga_options = optimoptions('ga', ...
    'PopulationSize', PopulationSize, ...
    'MaxGenerations', MaxGenerations, ...
    'CrossoverFraction', CrossoverFraction, ...
    'FunctionTolerance', 1e-6, ...
    'Display', 'iter', ...
    'PlotFcn', @gaplotbestf);

[C_opt, P_max, exitflag, output] = ga(@(C) -calc_P(C), ...
                                      nvars, [], [], [], [], lb, ub, [], ga_options);

P_max = -P_max;


%% result1
fprintf('\n===================== 遗传算法优化结果 =====================\n');
fprintf('最优阻尼系数 C_opt = %.2f N·s/m\n', C_opt);
fprintf('最大平均功率 P_max = %.4f W\n', P_max);
fprintf('迭代终止原因：%s\n', output.message);
fprintf('总函数评估次数：%d\n', output.funccount);

%% result2
tspan = 0:0.1:200*2*pi/2.2143;
[t_opt, y_opt] = ode45(@(t,y) solver(t,y,C_opt), ...
                       tspan, initial_conditions, ...
                       odeset('RelTol',1e-6, 'AbsTol',1e-8));

z1_opt = y_opt(:,1);        % 振子位移
z2_opt = y_opt(:,2);        % 浮子位移
zdot1_opt = y_opt(:,3);     % 振子速度
zdot2_opt = y_opt(:,4);     % 浮子速度
zr_opt = z1_opt - z2_opt;   % 相对位移


zdot1_opt_interp = interp1(t_opt, zdot1_opt, t_power, 'spline', 0);
zdot2_opt_interp = interp1(t_opt, zdot2_opt, t_power, 'spline', 0);
relative_velocity_opt = zdot1_opt_interp - zdot2_opt_interp;
instantaneous_power_opt = C_opt * abs(relative_velocity_opt).^(2 + alpha);


figure('Position', [100 100 1000 800]);
sgtitle(sprintf('最优阻尼系数下的PTO系统响应（C_opt=%.2f N·s/m，P_max=%.4f W）', C_opt, P_max));


subplot(4,1,1);
plot(t_opt, z1_opt, 'b-', 'LineWidth', 1.2, 'DisplayName', '振子位移 z1');
hold on;
plot(t_opt, z2_opt, 'r-', 'LineWidth', 1.2, 'DisplayName', '浮子位移 z2');
xlabel('时间 (s)');
ylabel('位移 (m)');
legend('Location', 'best');
grid on;
title('位移响应');


subplot(4,1,2);
plot(t_opt, zdot1_opt, 'b-', 'LineWidth', 1.2, 'DisplayName', '振子速度');
hold on;
plot(t_opt, zdot2_opt, 'r-', 'LineWidth', 1.2, 'DisplayName', '浮子速度');
xlabel('时间 (s)');
ylabel('速度 (m/s)');
legend('Location', 'best');
grid on;
title('速度响应');


subplot(4,1,3);
plot(t_opt, zr_opt, 'g-', 'LineWidth', 1.2);
xlabel('时间 (s)');
ylabel('相对位移 (m)');
grid on;
title('振子-浮子相对位移');


subplot(4,1,4);
plot(t_power, instantaneous_power_opt, 'm-', 'LineWidth', 1.2);
xlabel('时间 (s)');
ylabel('瞬时功率 (W)');
grid on;
title(sprintf('瞬时功率曲线（平均功率：%.4f W）', P_max));



set(gcf, 'Position', get(gcf, 'Position').*[1 1 1.1 1.1]);


%% result 3
C_range = linspace(0, 100000, 50);
P_range = zeros(size(C_range));

for i = 1:length(C_range)
    P_range(i) = calc_P(C_range(i));  % 使用现有calc_P函数，而非未定义的fitness_function
    fprintf('计算进度: %.0f%%\r', (i/length(C_range))*100);
end
fprintf('\n');

figure('Position', [200 200 800 500]);
plot(C_range, P_range, 'b-', 'LineWidth', 1.5, 'DisplayName', '平均功率');
hold on;
plot(C_opt, P_max, 'ro', 'MarkerSize', 8, 'MarkerEdgeColor', 'k', 'DisplayName', '最优解');
xlabel('阻尼系数 C (N·s/m)');
ylabel('平均功率 P (W)');
title('阻尼系数对平均功率的影响曲线');
legend('Location', 'best');
grid on;
    