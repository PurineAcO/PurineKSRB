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
theta0 = euler2quat(Euler0(3),Euler0(2),Euler0(1)); 
theta0 = theta0 / norm(theta0); 
q0 = [r0; theta0'];

% form initial generalized coordinate derivatives
G0 = G_matrix(theta0'); 
dq0_theta = pinv(2*G0) * omega0; 
dq0 = [velocity0; dq0_theta];

% %% 2. 求解四元数核心的动力学微分方程
% options = odeset('RelTol',1e-6,'AbsTol',1e-9);
% [~,q_sol] = ode45(@(t,q) rigid_body_ode_quat(t,q,m,J,F_ground,r_p_ground), ...
%     t_span, [q0; dq0], options); % 输入维度：q(7)+dq(7)=14维

% %% 3. 结果解析(仅此处四元数转欧拉角用于可视化)
% % 提取质心位置
% x = q_sol(:,1); y = q_sol(:,2); z = q_sol(:,3);
% % 提取四元数并转换为欧拉角(仅可视化用)
% quat = q_sol(:,4:7);
% Euler = zeros(size(quat,1),3);
% omega = zeros(size(quat,1),3);
% for i = 1:size(quat,1)
%     % 四元数归一化(防止数值误差)
%     quat_i = quat(i,:) / norm(quat(i,:));
%     % 四元数转欧拉角(Z-Y-X)
%     Euler(i,:) = quat2euler(quat_i','ZYX');
%     % 四元数导数转随体角速度(核心：ω=2G*θ_dot)
%     dq_theta = q_sol(i,11:14)'; % 提取四元数导数
%     G = G_matrix(quat_i');
%     omega(i,:) = (2 * G * dq_theta)';
% end

% %% 4. 结果可视化(与原逻辑一致)
% figure('Color','w','Position',[100,100,1200,800]);
% % 子图1：质心3D轨迹
% subplot(2,3,1);
% plot3(x,y,z,'LineWidth',2);
% xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
% title('质心3D平动轨迹'); grid on; view(3);
% % 子图2：位置随时间变化
% subplot(2,3,2);
% plot(t_eval,x,'r-',t_eval,y,'g-',t_eval,z,'b-','LineWidth',2);
% xlabel('时间 t (s)'); ylabel('位置 (m)');
% legend('X','Y','Z'); title('质心位置随时间变化'); grid on;
% % 子图3：欧拉角(仅可视化)
% subplot(2,3,3);
% plot(t_eval,Euler(:,1),'r-',t_eval,Euler(:,2),'g-',t_eval,Euler(:,3),'b-','LineWidth',2);
% xlabel('时间 t (s)'); ylabel('欧拉角 (rad)');
% legend('滚转φ','俯仰θ','偏航ψ'); title('姿态角(四元数转换)'); grid on;
% % 子图4：随体角速度
% subplot(2,3,4);
% plot(t_eval,omega(:,1),'r-',t_eval,omega(:,2),'g-',t_eval,omega(:,3),'b-','LineWidth',2);
% xlabel('时间 t (s)'); ylabel('角速度 (rad/s)');
% legend('wx','wy','wz'); title('随体坐标系角速度'); grid on;
% % 子图5：X位置-欧拉角关联
% subplot(2,3,5);
% plot(x,Euler(:,1),'r-',x,Euler(:,2),'g-',x,Euler(:,3),'b-','LineWidth',2);
% xlabel('X位置 (m)'); ylabel('欧拉角 (rad)');
% legend('滚转φ','俯仰θ','偏航ψ'); title('X位置-姿态角关联'); grid on;
% % 子图6：地面系力矩
% tau_ground = cross(r_p_ground,F_ground)*ones(1,length(t_eval)); 
% subplot(2,3,6);
% plot(t_eval,tau_ground(1,:),'r-',t_eval,tau_ground(2,:),'g-',t_eval,tau_ground(3,:),'b-','LineWidth',2);
% xlabel('时间 t (s)'); ylabel('力矩 (N·m)');
% legend('τx','τy','τz'); title('地面坐标系力矩(定常)'); grid on;

% %% ===================== 核心函数定义(全程四元数,无欧拉角)=====================
% % 函数1：计算G矩阵(四元数→角速度转换核心)
% function G = G_matrix(theta)
%     % theta: 四元数列向量 [w,x,y,z]^T
%     w = theta(1); x = theta(2); y = theta(3); z = theta(4);
%     G = [-x,  w,  z, -y;
%          -y, -z,  w,  x;
%          -z,  y, -x,  w];
% end

% % 函数2：四元数转旋转矩阵(地面→随体)
% function R = quat2rotm_quat(theta)
%     % theta: 四元数列向量 [w,x,y,z]^T
%     w = theta(1); x = theta(2); y = theta(3); z = theta(4);
%     % 地面系→随体系旋转矩阵
%     R = [1-2*y^2-2*z^2,  2*x*y-2*w*z,    2*x*z+2*w*y;
%          2*x*y+2*w*z,    1-2*x^2-2*z^2,  2*y*z-2*w*x;
%          2*x*z-2*w*y,    2*y*z+2*w*x,    1-2*x^2-2*y^2];
% end

% % 函数3：ODE核心函数(全程四元数计算,无欧拉角)
% function dqdt = rigid_body_ode_quat(t,q,m,J,F_ground,r_p_ground)
%     % 输入q维度：14维 = 广义坐标q(7) + 广义速度dq(7)
%     % q(1-3): 质心位置 r (地面系)
%     % q(4-7): 四元数 theta [w,x,y,z] (单位四元数)
%     % q(8-10): 质心速度 dr (地面系)
%     % q(11-14): 四元数导数 dtheta
    
%     % 1. 提取并归一化四元数(核心：保证单位四元数)
%     r = q(1:3);
%     theta = q(4:7);
%     theta = theta / norm(theta); % 强制归一化,避免数值漂移
%     dr = q(8:10);
%     dtheta = q(11:14);
    
%     % 2. 计算核心矩阵(全程四元数推导)
%     G = G_matrix(theta');       % 3×4 G矩阵
%     Gt = G';                    % 4×3 G转置矩阵
%     R = quat2rotm_quat(theta'); % 地面→随体旋转矩阵(四元数直接计算)
    
%     % 3. 构造广义质量矩阵M(7×7,分块对角)
%     M11 = m * eye(3);           % 平动质量矩阵
%     M22 = 4 * Gt * J * G;       % 转动等效质量矩阵
%     M = blkdiag(M11, M22);      % 广义质量矩阵
    
%     % 4. 计算地面系外力/力矩(无欧拉角,直接四元数转旋转矩阵)
%     tau_ground = cross(r_p_ground, F_ground); % 地面系力矩
%     % 随体系力矩(用于广义力计算)
%     tau_body = R * tau_ground;
    
%     % 5. 构造广义力Q(7×1)
%     Q = [F_ground; 2 * Gt * tau_body];
    
%     % 6. 计算惯性项(离心力/哥氏力,数值求导避免解析复杂度)
%     h = 1e-6;
%     theta_plus = theta + h*dtheta;
%     theta_plus = theta_plus / norm(theta_plus);
%     G_plus = G_matrix(theta_plus');
%     M22_plus = 4 * G_plus' * J * G_plus;
    
%     theta_minus = theta - h*dtheta;
%     theta_minus = theta_minus / norm(theta_minus);
%     G_minus = G_matrix(theta_minus');
%     M22_minus = 4 * G_minus' * J * G_minus;
    
%     dM22dt = (M22_plus - M22_minus) / (2*h);
%     dMdt = blkdiag(zeros(3), dM22dt); % 平动质量矩阵导数为0
    
%     dTdq = zeros(7,1); % 动能对q的偏导(四元数归一化后可忽略)
%     inertia_term = dMdt * [dr; dtheta] - dTdq;
    
%     % 7. 求解广义加速度(核心动力学方程：M*ddq = Q - inertia_term)
%     M_inv = inv(M);
%     ddq = M_inv * (Q - inertia_term);
    
%     % 8. 构造ODE输出(dqdt = [dr; dtheta; ddq])
%     dqdt = [dr; dtheta; ddq];
% end