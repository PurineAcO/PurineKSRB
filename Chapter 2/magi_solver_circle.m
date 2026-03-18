clear; clc; close all;
%% 0. Define some constants
Br = 1.22;                              % Residual magnetic flux density (T)
mu_r = 1.03;                            % Relative permeability
mu_0 = 4*pi*1e-7;                       % Permeability of free space

before = (Br^2)*(mu_r+3)^2/((4*pi*mu_0)*(mu_r+1)^4); 

% the params of magi
D1 = 0.006;     h1 = 0.006;     pos1 = [0, 0, 0];
D2 = 0.010;     h2 = 0.030;     pos2 = [0, 0, 0.001+0.003+0.015];  % 间距1mm

%% 2. Meshing

% mesh density
dr = 0.001;        
dtheta = pi/20;

function [mesh_points, dS_array] = cylinder_fan_mesh(D, h, pos, dr, dtheta, bt)
    x0 = pos(1); y0 = pos(2); z0 = pos(3);
    R = D/2;
    r_list = 0:dr:R;       
    theta_list = 0:dtheta:2*pi; 
    
    points = [];
    areas = [];
    
    for i = 1:length(r_list)-1
        r_start = r_list(i);
        r_end   = r_list(i+1);
        r_mid   = (r_start + r_end)/2;   
        
        for j = 1:length(theta_list)-1
            th_start = theta_list(j);
            th_end   = theta_list(j+1);
            th_mid   = (th_start + th_end)/2; 
            
            x = x0 + r_mid * cos(th_mid);
            y = y0 + r_mid * sin(th_mid);

            if strcmp(bt,'top')
                z = z0 + h/2;
            else
                z = z0 - h/2;
            end

            dS = r_mid * dr * dtheta; 
            points = [points; x, y, z];
            areas  = [areas; dS];
        end
    end
    mesh_points = points;
    dS_array = areas;
end

[mesh_A_top, dS_A_top] = cylinder_fan_mesh(D1, h1, pos1, dr, dtheta, 'top');
[mesh_A_bottom, dS_A_bottom] = cylinder_fan_mesh(D1, h1, pos1, dr, dtheta, 'bottom');
[mesh_B_top, dS_B_top] = cylinder_fan_mesh(D2, h2, pos2, dr, dtheta, 'top');
[mesh_B_bottom, dS_B_bottom] = cylinder_fan_mesh(D2, h2, pos2, dr, dtheta, 'bottom');

%% 2. Calc the force and torque

function [Fx, Fy, Fz, Mx, My, Mz] = CFT_cylinder(mesh1, mesh2, dS1, dS2, center1, C, sign)
    dx = mesh1(:,1) - mesh2(:,1)';
    dy = mesh1(:,2) - mesh2(:,2)';
    dz = mesh1(:,3) - mesh2(:,3)';
    r  = sqrt(dx.^2 + dy.^2 + dz.^2);

    dS_matrix = dS1 * dS2';

    Fx_mat = C * sign * dS_matrix .* dx ./ r.^3;
    Fy_mat = C * sign * dS_matrix .* dy ./ r.^3;
    Fz_mat = C * sign * dS_matrix .* dz ./ r.^3;

    Fx = sum(Fx_mat(:));
    Fy = sum(Fy_mat(:));
    Fz = sum(Fz_mat(:));

    arm_x = mesh1(:,1) - center1(1);
    arm_y = mesh1(:,2) - center1(2);
    arm_z = mesh1(:,3) - center1(3);
    arm_x = arm_x(:, ones(1, size(mesh2,1)));
    arm_y = arm_y(:, ones(1, size(mesh2,1)));
    arm_z = arm_z(:, ones(1, size(mesh2,1)));

    Mx_mat = arm_y.*Fz_mat - arm_z.*Fy_mat;
    My_mat = arm_z.*Fx_mat - arm_x.*Fz_mat;
    Mz_mat = arm_x.*Fy_mat - arm_y.*Fx_mat;

    Mx = sum(Mx_mat(:));
    My = sum(My_mat(:));
    Mz = sum(Mz_mat(:));
end

total_FT = zeros(1,6);

[Fx,Fy,Fz,Mx,My,Mz] = CFT_cylinder(mesh_A_top, mesh_B_bottom, dS_A_top, dS_B_bottom, pos1, before, 1);
total_FT = total_FT + [Fx,Fy,Fz,Mx,My,Mz];

[Fx,Fy,Fz,Mx,My,Mz] = CFT_cylinder(mesh_A_bottom, mesh_B_top, dS_A_bottom, dS_B_top, pos1, before, 1);
total_FT = total_FT + [Fx,Fy,Fz,Mx,My,Mz];

[Fx,Fy,Fz,Mx,My,Mz] = CFT_cylinder(mesh_A_top, mesh_B_top, dS_A_top, dS_B_top, pos1, before, -1);
total_FT = total_FT + [Fx,Fy,Fz,Mx,My,Mz];

[Fx,Fy,Fz,Mx,My,Mz] = CFT_cylinder(mesh_A_bottom, mesh_B_bottom, dS_A_bottom, dS_B_bottom, pos1, before, -1);
total_FT = total_FT + [Fx,Fy,Fz,Mx,My,Mz];

%% 3. Output the result
fprintf('===== 圆柱体扇环面元 精准计算结果 =====\n');
fprintf('总力 (N):     Fx=%.4f, Fy=%.4f, Fz=%.4f\n', total_FT(1),total_FT(2),total_FT(3));
fprintf('总力矩 (N·m): Mx=%.4f, My=%.4f, Mz=%.4f\n', total_FT(4),total_FT(5),total_FT(6));