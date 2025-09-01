% ������֪�̶�����
   
% ��ֵȫ�ֱ���
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

% ������������ͷ�Χ
nvars = 2; % C��MC��������
lb = [0, 0]; % �½�
ub = [100000, 100000]; % �Ͻ�

% ����GA�Ż�
options = optimoptions('ga', ...
    'PopulationSize', 50, ...
    'MaxGenerations', 50, ...
    'Display', 'iter', ...
    'PlotFcn', @gaplotbestf);

[x_opt, fval_opt] = ga(@objfun, nvars, [], [], [], [], lb, ub, [], options);

% ��ʾ���
fprintf('���Ų�����C = %.1f, MC = %.1f\n', x_opt(1), x_opt(2));
fprintf('���P_bar = %.4f\n', -fval_opt);

% �������Ų����µĹ�������
plot_optimal_power(x_opt);

% ����Ŀ�꺯������Ӧ�Ⱥ����������ظ���P_bar����ΪgaĬ����С��
function fitness = objfun(x)
    C = x(1);
    MC = x(2);
    omega = 1.9806;   
    % ��ֵ����
    initial_conditions = zeros(8, 1);
    
    % ���ʱ�䷶Χ
    t_end_total = 200*pi/omega;
    tspan = [0, t_end_total];  
    
    % �����ѡ��
    options = odeset(...
        'RelTol', 1e-6, ...
        'AbsTol', 1e-8, ...
        'MaxStep', 0.001 ...
    );
    
    % ����ode45�����
    [t, sol] = ode45(@(t, y) system_equations(t, y, C, MC), tspan, initial_conditions, options);
    
    % ��ȡ���
    zdot1 = sol(:, 5);
    zdot2 = sol(:, 6);
    thetadot1 = sol(:, 7);
    thetadot2 = sol(:, 8);
    
    % �����������
    t_start = 100*pi/omega;
    t_end = 200*pi/omega;
    
    % �ҵ�������������
    idx_start = find(t >= t_start, 1, 'first');
    idx_end = find(t <= t_end, 1, 'last');
    
    % �����߽����
    if isempty(idx_start) || isempty(idx_end) || idx_start > idx_end
        fitness = -1e-9; % ��Сֵ���������
        return;
    end
    
    % ��ȡ����������
    zdot1_interval = zdot1(idx_start:idx_end);
    zdot2_interval = zdot2(idx_start:idx_end);
    thetadot1_interval = thetadot1(idx_start:idx_end);
    thetadot2_interval = thetadot2(idx_start:idx_end);
    t_interval = t(idx_start:idx_end);
    
    % ����P_bar��ʱ���Ȩ���֣�
    P_vals = C * (zdot1_interval - zdot2_interval).^2 + MC * (thetadot1_interval - thetadot2_interval).^2;
    P_bar = trapz(t_interval, P_vals) / (t_end - t_start);
    
    fitness = -P_bar; % GAĬ����С�������Է��ظ���P_bar�����
end

% ϵͳ΢�ַ��̣��ڲ�ʹ�ã������ⲿ�̶�������
function dydt = system_equations(t, y, C, MC)
    % �ⲿ�̶�����
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
    
    % ״̬����
    z1 = y(1);
    z2 = y(2);
    theta1 = y(3);
    theta2 = y(4);
    zdot1 = y(5);
    zdot2 = y(6);
    thetadot1 = y(7);
    thetadot2 = y(8);
    
    % ����I1
    I1 = 202.75 + 2433 * (0.75 + z1 - z2)^2;
    
    % ���Ӵ���ͨ��
    zddot1 = (-K*(z1 - z2) - C*(zdot1 - zdot2)) / m1;
    
    % ���Ӵ���ͨ��
    zddot2 = (f0*cos(omega*t) - CL*zdot2 - rho*g*A*z2 - m1*zddot1) / (m2 + me);
    
    % ������תͨ��
    thetaddot1 = (-MC*(thetadot1 - thetadot2) - MK*(theta1 - theta2)) / I1;
    
    % ������תͨ��
    thetaddot2 = (M0*cos(omega*t) - MCL*thetadot2 - M3*theta2 - I1*thetaddot1) / (I2 + Ie);
    
    % ����һ��΢�ַ�����
    dydt = [
        zdot1;               % z1��һ�׵���
        zdot2;               % z2��һ�׵���
        thetadot1;           % theta1��һ�׵���
        thetadot2;           % theta2��һ�׵���
        zddot1;              % z1�Ķ��׵���
        zddot2;              % z2�Ķ��׵���
        thetaddot1;          % theta1�Ķ��׵���
        thetaddot2           % theta2�Ķ��׵���
    ];
end

% ������������GA�����Ż�


