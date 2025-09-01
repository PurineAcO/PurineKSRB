clear; clc; close all;

%% define GA
nvars = 2;                          % 优化变量数量 [C, alpha]
lb = [0, 0];                        % 下界
ub = [100000, 0.5];                 % 上界
PopulationSize = 50;                
MaxGenerations = 10;                % 可以适当增加迭代次数
CrossoverFraction = 0.8;            

% define GA
ga_options = optimoptions('ga', ...
    'PopulationSize', PopulationSize, ...
    'MaxGenerations', MaxGenerations, ...
    'CrossoverFraction', CrossoverFraction, ...
    'FunctionTolerance', 1e-6, ...
    'Display', 'iter', ...
    'PlotFcn', @gaplotbestf);

[x_opt, P_max, exitflag, output] = ga(@(x) -calc_P(x), ...
                                      nvars, [], [], [], [], lb, ub, [], ga_options);

C_opt = x_opt(1);
alpha_opt = x_opt(2);
P_max = -P_max;

%% result1
fprintf('\n===================== 遗传算法优化结果 =====================\n');
fprintf('最优阻尼系数 C_opt = %.2f N·s/m\n', C_opt);
fprintf('最优 alpha = %.4f\n', alpha_opt);
fprintf('最大平均功率 P_max = %.4f W\n', P_max);
fprintf('迭代终止原因：%s\n', output.message);
fprintf('总函数评估次数：%d\n', output.funccount);

%% define solver
function dydt=solver(t,y,C,alpha)
    
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
    zddot1 = (-K*(z1 - z2) - C*(zdot1 - zdot2)*((abs(zdo1-zdot2))^alpha)) / m1;
    zddot2 = (f_wave - CL*zdot2 - rho_gA*z2 - m1*zddot1) / (m2 + me);

    % define the cols where is f^(1)
    dydt=[zdot1;
          zdot2;
          zddot1;
          zddot2];  

end
%% define the J
function P = calc_P(x)
    C = x(1);
    alpha = x(2);

    % define some consts
    omega=2.2143;                           
    tspan = 0:0.1:200*2*pi/omega;           
    initial_conditions = [0; 0; 0; 0];      
    start_time = 100*2*pi/omega;            
    end_time = 200*2*pi/omega;              
    T = end_time - start_time;              

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
