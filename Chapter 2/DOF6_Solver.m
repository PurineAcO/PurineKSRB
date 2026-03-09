clear; clc; close all;clear functions; 

%% 1. define some consts
global m I_body I_inv r_body F_abs

% information of the rigid body
m = 2;                            % mass of rigid body (kg)
I_body = diag([1,1,1]);           % the inertia matrix of the rigid body (3×3 matrix)
I_inv = inv(I_body);              % the inverse of the inertia matrix of the rigid body (3×3 matrix)
r_body = reshape([1,1,1],1,3);    % the position vector of the force point relative to RIGID BODY
F_abs = reshape([1,0,0],1,3);     % the force vector acting on the rigid body relative to GROUND (1×3 row vector)

% the initial state vector (position, velocity, euler angles, angular velocity)
x0 = reshape([0,0,0,  0,0,0,  0,0,0,  0,0,0], 1, 12);  

% the simulation time interval
t_span = [0, 8];  

%% 2. ode45 solver

% if you want the 'OutFcn', you should define the state function.
options = odeset('RelTol',1e-6,'AbsTol',1e-9); 
[t, x] = ode45(@rigidBody6DOF, t_span, x0, options);


%% 3. extract the results
pos_hist = x(:,1:3);     
vel_hist = x(:,4:6);     
euler_hist = x(:,7:9);   
omega_hist = x(:,10:12); 

figure('Color','white','Position',[100,100,1200,800]);
subplot(3,2,1);plot(t,pos_hist);xlabel('t/s');ylabel('位置/m');title('质心位置');legend('x','y','z');grid on;
subplot(3,2,2);plot(t,vel_hist);xlabel('t/s');ylabel('速度/(m/s)');title('质心速度');legend('vx','vy','vz');grid on;
subplot(3,2,3);plot(t,euler_hist);xlabel('t/s');ylabel('欧拉角/rad');title('姿态');legend('theta','phi','psi');grid on;
subplot(3,2,4);plot(t,omega_hist);xlabel('t/s');ylabel('角速度/(rad/s)');title('随体角速度');legend('wx','wy','wz');grid on;
subplot(3,2,5);plot3(pos_hist(:,1),pos_hist(:,2),pos_hist(:,3));xlabel('X/m');ylabel('Y/m');zlabel('Z/m');title('3D轨迹');grid on;view(3);
subplot(3,2,6);plot(t,sqrt(sum(omega_hist.^2,2)));xlabel('t/s');ylabel('角速度幅值/(rad/s)');title('角速度幅值');grid on;

%% 0. solve function
function dxdt = rigidBody6DOF(t, x)

    global m I_body I_inv r_body F_abs
    
    % 0.1 get the state
    pos = reshape(x(1:3),1,3);      
    vel = reshape(x(4:6),1,3);       
    euler = reshape(x(7:9),1,3);     
    omega = reshape(x(10:12),1,3);   
    theta = euler(1); phi = euler(2); psi = euler(3);
    
    % 0.2 rotation matrix (GROUND to BODY)
    R = [cos(psi)*cos(phi),  cos(psi)*sin(phi)*sin(theta)-sin(psi)*cos(theta),  cos(psi)*sin(phi)*cos(theta)+sin(psi)*sin(theta);
         sin(psi)*cos(phi),  sin(psi)*sin(phi)*sin(theta)+cos(psi)*cos(theta),  sin(psi)*sin(phi)*cos(theta)-cos(psi)*sin(theta);
         -sin(phi),          cos(phi)*sin(theta),                               cos(phi)*cos(theta)];
    
    % 0.3 change the force from GROUND to BODY
    F_body = F_abs * R;                                
    M_body = cross(reshape(r_body,3,1), reshape(F_body,3,1)); 
    
    % 0.4 the acceleration of the rigid body
    % this equation is defined by Newton's second law
    pos_dot = vel;                                     % 1×3行向量
    vel_dot = F_abs / m;                               % 1×3行向量
    
    % 0.5 the angular acceleration of the rigid body
    % this equation is defined by I*dot(omega) + omega*(I times omega) = M_body
    omega_col = reshape(omega,3,1);    
    I_omega = I_body * omega_col;      
    omega_cross = cross(omega_col, I_omega); 
    omega_dot_col = I_inv * (M_body - omega_cross); 
    omega_dot = reshape(omega_dot_col,1,3); 
    
    % 0.6 form the euler angle rate matrix
    % the special case is ignored. usually this is be solved by quaternion
    if abs(phi) < pi/2 - 1e-6
        euler_rate_mat = [1, sin(theta)*tan(phi), cos(theta)*tan(phi);
                          0, cos(theta),          -sin(theta);
                          0, sin(theta)/cos(phi), cos(theta)/cos(phi)];
        euler_dot_col = euler_rate_mat * omega_col;
        euler_dot = reshape(euler_dot_col,1,3);     
    else
        euler_dot = omega;
    end
    
    % 0.7 get the dydt
    % ode45 requires the output to be a 12×1 column vector
    dxdt_row = [pos_dot, vel_dot, euler_dot, omega_dot]; 
    dxdt = reshape(dxdt_row,12,1);
end

