%% 0. constant definition

% rigid body parameters
m = 5;                     % mass (kg)
J = diag([1,2,3]);         % inertia matrix (non-diagonal also ok)

% initial conditions, all vectors are in the ground absolute coordinate system
r0 = [0,0,0]';             % initial position of the center of mass (X,Y,Z) (m)
Euler0 = [0,0,0]';         % initial Euler angles (roll φ, pitch θ, yaw ψ) (rad)
omega0 = [0,0,0]';         % initial angular velocity in the body frame (rad/s)
velocity0 = [0,0,0]';      % initial velocity of the center of mass (X,Y,Z) (m)

% external force and its application point, all vectors are in the ground absolute coordinate system
F_ground = [1,0,0]';       % external force (N)
r_p_ground = [0.5,0,0]';   % vector from the center of mass to the application point (m)

% simulation time parameters
t_start = 0;               % start time (s)
t_end = 10;                % end time (s)
t_step = 0.01;             % time step (s)
t_span = [t_start,t_end];
t_eval = t_start:t_step:t_end;

%% 1. Pre-processing: Initial Values

% convert Euler angles to quaternion, normalize, and form initial generalized coordinates
theta0 = euler2quat(Euler0); 
theta0 = theta0 / norm(theta0); 
q0 = [r0; theta0'];

% form initial generalized coordinate derivatives
G0 = G_matrix(theta0'); 
dq0_theta = pinv(2*G0) * omega0; 
dq0 = [velocity0; dq0_theta];

%% 2. Establish the ODE solver
options = odeset('RelTol',1e-6,'AbsTol',1e-9,'OutputFcn',@odeplot);
[~,q_sol] = ode45(@(t,q) rigid_body_ode_quat(t,q,m,J,F_ground,r_p_ground),...
                  t_span,...
                  [q0; dq0],...
                  options);

%% 3. 结果解析(仅此处四元数转欧拉角用于可视化)
% 提取质心位置
x = q_sol(:,1); y = q_sol(:,2); z = q_sol(:,3);
% 提取四元数并转换为欧拉角(仅可视化用)
quat = q_sol(:,4:7);
Euler = zeros(size(quat,1),3);
omega = zeros(size(quat,1),3);
for i = 1:size(quat,1)
    % 四元数归一化(防止数值误差)
    quat_i = quat(i,:) / norm(quat(i,:));
    % 四元数转欧拉角(Z-Y-X)
    Euler(i,:) = quat2euler(quat_i);
    % 四元数导数转随体角速度(核心：ω=2G*θ_dot)
    dq_theta = q_sol(i,11:14)'; % 提取四元数导数
    G = G_matrix(quat_i');
    omega(i,:) = (2 * G * dq_theta)';
end

%% 4. 结果可视化(与原逻辑一致)
figure('Color','w','Position',[100,100,1200,800]);
% 子图1：质心3D轨迹
subplot(2,3,1);
plot3(x,y,z,'LineWidth',2);
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
title('质心3D平动轨迹'); grid on; view(3);
% 子图2：位置随时间变化
subplot(2,3,2);
plot(t_eval,x,'r-',t_eval,y,'g-',t_eval,z,'b-','LineWidth',2);
xlabel('时间 t (s)'); ylabel('位置 (m)');
legend('X','Y','Z'); title('质心位置随时间变化'); grid on;
% 子图3：欧拉角(仅可视化)
subplot(2,3,3);
plot(t_eval,Euler(:,1),'r-',t_eval,Euler(:,2),'g-',t_eval,Euler(:,3),'b-','LineWidth',2);
xlabel('时间 t (s)'); ylabel('欧拉角 (rad)');
legend('滚转φ','俯仰θ','偏航ψ'); title('姿态角(四元数转换)'); grid on;
% 子图4：随体角速度
subplot(2,3,4);
plot(t_eval,omega(:,1),'r-',t_eval,omega(:,2),'g-',t_eval,omega(:,3),'b-','LineWidth',2);
xlabel('时间 t (s)'); ylabel('角速度 (rad/s)');
legend('wx','wy','wz'); title('随体坐标系角速度'); grid on;
% 子图5：X位置-欧拉角关联
subplot(2,3,5);
plot(x,Euler(:,1),'r-',x,Euler(:,2),'g-',x,Euler(:,3),'b-','LineWidth',2);
xlabel('X位置 (m)'); ylabel('欧拉角 (rad)');
legend('滚转φ','俯仰θ','偏航ψ'); title('X位置-姿态角关联'); grid on;
% 子图6：地面系力矩
tau_ground = cross(r_p_ground,F_ground)*ones(1,length(t_eval)); 
subplot(2,3,6);
plot(t_eval,tau_ground(1,:),'r-',t_eval,tau_ground(2,:),'g-',t_eval,tau_ground(3,:),'b-','LineWidth',2);
xlabel('时间 t (s)'); ylabel('力矩 (N·m)');
legend('τx','τy','τz'); title('地面坐标系力矩(定常)'); grid on;


%% supplement 0: euler2quat,which transform euler angles to quaternion
function theta0 = euler2quat(Euler0)
    % input a array called Euler0
    phi = Euler0(1);    % roll angle (X-axis)
    theta = Euler0(2);  % pitch angle (Y-axis)
    psi = Euler0(3);    % yaw angle (Z-axis)

    w = cos(phi/2)*cos(theta/2)*cos(psi/2) + sin(phi/2)*sin(theta/2)*sin(psi/2);
    x = sin(phi/2)*cos(theta/2)*cos(psi/2) - cos(phi/2)*sin(theta/2)*sin(psi/2);
    y = cos(phi/2)*sin(theta/2)*cos(psi/2) + sin(phi/2)*cos(theta/2)*sin(psi/2);
    z = cos(phi/2)*cos(theta/2)*sin(psi/2) - sin(phi/2)*sin(theta/2)*cos(psi/2);
    
    theta0 = [w,x,y,z];
    theta0 = theta0 / norm(theta0);

end

%% supplement 1: get G matrix
function G = G_matrix(theta)
    % theta: 四元数列向量 [w,x,y,z]^T
    w = theta(1); x = theta(2); y = theta(3); z = theta(4);
    G = [-x,  w,  z, -y;
         -y, -z,  w,  x;
         -z,  y, -x,  w];
end

% %% Supplement 2: quat2rotm_quat
% function R = quat2rotm_quat(theta)
%     % theta: 四元数列向量 [w,x,y,z]^T
%     w = theta(1); x = theta(2); y = theta(3); z = theta(4);
%     % 地面系→随体系旋转矩阵
%     R = [1-2*y^2-2*z^2,  2*x*y-2*w*z,    2*x*z+2*w*y;
%          2*x*y+2*w*z,    1-2*x^2-2*z^2,  2*y*z-2*w*x;
%          2*x*z-2*w*y,    2*y*z+2*w*x,    1-2*x^2-2*y^2];
% end

%% supplement 3: the rigid body ODE function

function dqdt = rigid_body_ode_quat(t, q, m, J, F_ground, r_p_ground)

    % input: q,which means the generalized coordinates and velocities
    %        m,which means the mass of the rigid body
    %        J,which means the inertia matrix of the rigid body
    %        F_ground,which means the force in the ground frame
    %        r_p_ground,which means the position of the force in the ground frame
    
    % unzip the q
    q_7 = q(1:7);dq_7 = q(8:14);  
    theta = q_7(4:7);theta = theta / norm(theta);
    dtheta = dq_7(4:7); 
    
    % calculate the generalized mass matrix M (7x7)
    G = G_matrix(theta');                   % first calculate the G matrix
    M11 = m * eye(3);                       % the (1,1) part of the generalized mass matrix
    M22 = 4 * G' * J * G;                   % the (2,2) part of the generalized mass matrix
    M = blkdiag(M11, M22);                  % the generalized mass matrix
    
    % get the H matrix (7x6)
    H11 = eye(3);                           % the (1,1) part of the H matrix
    H12 = zeros(3,3);                       % the (1,2) part of the H matrix
    H21 = zeros(4,3);                       % the (2,1) part of the H matrix
    H22 = 2 * G';                           % the (2,2) part of the H matrix
    H = [H11, H12; H21, H22];               % the H matrix
    
    % calculate the vector of generalized force Q (7x1)
    tau_ground = cross(r_p_ground, F_ground);
    f = [F_ground; tau_ground]; 
    Q = H * f; 

    % we need to calculate the dot(M) by numerical differentiation
    h = 1e-6; 
    theta_plus = theta + h * dtheta;
    theta_plus = theta_plus / norm(theta_plus);
    G_plus = G_matrix(theta_plus');
    M22_plus = 4 * G_plus' * J * G_plus;
    
    theta_minus = theta - h * dtheta;
    theta_minus = theta_minus / norm(theta_minus);
    G_minus = G_matrix(theta_minus');
    M22_minus = 4 * G_minus' * J * G_minus;
    
    dM22dt = (M22_plus - M22_minus) / (2*h);
    dMdt = blkdiag(zeros(3), dM22dt); 
    
    % it is proven that dTdq = 0 when theta is a unit quaternion
    dTdq = zeros(7, 1); 
    
    % then we can calculate the Qq term
    inertia_term = dMdt * dq_7 - dTdq;
    
    % get the generalized acceleration q_dd (7x1)
    q_dd = M \ (Q - inertia_term); 
    dqdt = [dq_7; q_dd]; 
end

function Euler = quat2euler(quat_i)
    % 原错误行：Euler(i,:) = quat2euler(quat_i','ZYX');
    % 手动实现四元数转欧拉角（quat_i = [w,x,y,z]）
    w = quat_i(1); x = quat_i(2); y = quat_i(3); z = quat_i(4);
    % 计算ZYX欧拉角（偏航ψ、俯仰θ、滚转φ）
    psi = atan2(2*(w*z + x*y), 1 - 2*(y^2 + z^2));
    theta = asin(2*(w*y - z*x));
    phi = atan2(2*(w*x + y*z), 1 - 2*(x^2 + y^2));
    Euler = [phi, theta, psi]; % 对应roll/pitch/yaw
end