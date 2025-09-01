%% define consts
me = 1091.099;          % 垂荡附加质量
m1 = 2433;              % 振子质量
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

%% define GA
nvars = 2; 
lb = [0, 0]; 
ub = [100000, 100000]; 


options = optimoptions('ga', ...
    'PopulationSize', 50, ...
    'MaxGenerations', 50, ...
    'Display', 'iter', ...
    'PlotFcn', @gaplotbestf);

[x_opt, fval_opt] = ga(@objfun, nvars, [], [], [], [], lb, ub, [], options);


fprintf('���Ų�����C = %.1f, MC = %.1f\n', x_opt(1), x_opt(2));
fprintf('���P_bar = %.4f\n', -fval_opt);


plot_optimal_power(x_opt);

%% define the J
function fitness = objfun(x)
    C = x(1);
    MC = x(2);
    omega = 1.9806;   
    initial_conditions = zeros(8, 1);
    
    t_end_total = 200*pi/omega;
    tspan = [0, t_end_total];  
    
    options = odeset(...
        'RelTol', 1e-6, ...
        'AbsTol', 1e-8, ...
        'MaxStep', 0.001 ...
    );
    
    [t, sol] = ode45(@(t, y) system_equations(t, y, C, MC), tspan, initial_conditions, options);
    
    zdot1 = sol(:, 5);
    zdot2 = sol(:, 6);
    thetadot1 = sol(:, 7);
    thetadot2 = sol(:, 8);
    
    t_start = 100*pi/omega;
    t_end = 200*pi/omega;

    idx_start = find(t >= t_start, 1, 'first');
    idx_end = find(t <= t_end, 1, 'last');

    if isempty(idx_start) || isempty(idx_end) || idx_start > idx_end
        fitness = -1e-9; 
        return;
    end
    
    zdot1_interval = zdot1(idx_start:idx_end);
    zdot2_interval = zdot2(idx_start:idx_end);
    thetadot1_interval = thetadot1(idx_start:idx_end);
    thetadot2_interval = thetadot2(idx_start:idx_end);
    t_interval = t(idx_start:idx_end);
    
    P_vals = C * (zdot1_interval - zdot2_interval).^2 + MC * (thetadot1_interval - thetadot2_interval).^2;
    P_bar = trapz(t_interval, P_vals) / (t_end - t_start);
    
    fitness = -P_bar; 
end

%% define the solver
function dydt = system_equations(t, y, C, MC)
    % define some consts
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
    
    z1 = y(1);
    z2 = y(2);
    theta1 = y(3);
    theta2 = y(4);
    zdot1 = y(5);
    zdot2 = y(6);
    thetadot1 = y(7);
    thetadot2 = y(8);
    
    % equ (5)
    I1 = 202.75 + 2433 * (0.75 + z1 - z2)^2;
    
    % equ (1)
    zddot1 = (-K*(z1 - z2) - C*(zdot1 - zdot2)) / m1;
    
    % equ (2)
    zddot2 = (f0*cos(omega*t) - CL*zdot2 - rho*g*A*z2 - m1*zddot1) / (m2 + me);
    
    % equ (3)
    thetaddot1 = (-MC*(thetadot1 - thetadot2) - MK*(theta1 - theta2)) / I1;
    
    % equ (4)
    thetaddot2 = (M0*cos(omega*t) - MCL*thetadot2 - M3*theta2 - I1*thetaddot1) / (I2 + Ie);
    
    % DDD
    dydt = [
        zdot1;               
        zdot2;               
        thetadot1;           
        thetadot2;          
        zddot1;              
        zddot2;          
        thetaddot1;         
        thetaddot2          
    ];
end


