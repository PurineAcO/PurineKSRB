clear; clc; close all;

%% 0. Define constants
Br = 1;                       % Residual magnetic flux density (T)
mu_r = 1;                     % Relative permeability
mu_0 = 4*pi*1e-7;             % Permeability of free space

before = (Br^2)*(mu_r+3)^2/((4*pi*mu_0)*(mu_r+1)^4);

mag_shape_a = [1,1,1];        % Volume parameters [L, W, H]
mag_shape_b = [1,1,1];        % Volume parameters [L, W, H]

mag_place_a = [0,0,0];        % Centroid position [x, y, z]
mag_place_b = [3,3,3];        % Centroid position [x, y, z]

% mag_euler_a = [0,0,0];      % Euler angles (attitude) of magnet A
% mag_euler_b = [0,0,0];      % Euler angles (attitude) of magnet B

step = 0.1;                   % Mesh density

%% 1. Generate surface mesh - CELL CENTROIDS (grid center points)

% Generate Grid of A
x_A = mag_place_a(1)-mag_shape_a(1)/2+step/2 : step : mag_place_a(1)+mag_shape_a(1)/2-step/2;
y_A = mag_place_a(2)-mag_shape_a(2)/2+step/2 : step : mag_place_a(2)+mag_shape_a(2)/2-step/2;
[X_AF, Y_AF] = meshgrid(x_A, y_A);

Zc_bottom_A = zeros(size(X_AF)) + mag_place_a(3) - mag_shape_a(3)/2;
Zc_top_A = Zc_bottom_A + mag_shape_a(3);

mesh_A_top = [X_AF(:), Y_AF(:), Zc_top_A(:)];
mesh_A_bottom = [X_AF(:), Y_AF(:), Zc_bottom_A(:)];

% Generate Grid of B
x_B = mag_place_b(1)-mag_shape_b(1)/2+step/2 : step : mag_place_b(1)+mag_shape_b(1)/2-step/2;
y_B = mag_place_b(2)-mag_shape_b(2)/2+step/2 : step : mag_place_b(2)+mag_shape_b(2)/2-step/2;
[X_BF, Y_BF] = meshgrid(x_B, y_B);

Zc_bottom_B = zeros(size(X_BF)) + mag_place_b(3) - mag_shape_b(3)/2;
Zc_top_B = Zc_bottom_B + mag_shape_b(3);

mesh_B_top = [X_BF(:), Y_BF(:), Zc_top_B(:)];
mesh_B_bottom = [X_BF(:), Y_BF(:), Zc_bottom_B(:)];

%% 2. Calculate the force and torque between A and B

dS = step*step;

function [total_Fx, total_Fy, total_Fz,total_Mx, total_My, total_Mz]=CFT(mesh1,mesh2,center1,params)

    % which is used to calculate the force between two meshes,params is a vector which contains
    % the sign of the force,the square of the mesh,and the 'before' constant
    % this function calculate the force and torque which mesh1 feels.
    dx = mesh1(:,1) - mesh2(:,1)';
    dy = mesh1(:,2) - mesh2(:,2)';
    dz = mesh1(:,3) - mesh2(:,3)';
    r = sqrt(dx.^2 + dy.^2 + dz.^2);

    Fx = params(1)*params(2)*params(3).*dx./r.^3;
    Fy = params(1)*params(2)*params(3).*dy./r.^3;
    Fz = params(1)*params(2)*params(3).*dz./r.^3;

    total_Fx = sum(Fx(:));
    total_Fy = sum(Fy(:));
    total_Fz = sum(Fz(:));

    arm_x = mesh1(:,1) - center1(1);
    arm_y = mesh1(:,2) - center1(2);
    arm_z = mesh1(:,3) - center1(3);

    arm_x = arm_x(:, ones(1, size(mesh2,1)));
    arm_y = arm_y(:, ones(1, size(mesh2,1)));
    arm_z = arm_z(:, ones(1, size(mesh2,1)));

    Mx = arm_y.*Fz - arm_z.*Fy;
    My = arm_z.*Fx - arm_x.*Fz;
    Mz = arm_x.*Fy - arm_y.*Fx;

    total_Mx = sum(Mx(:));
    total_My = sum(My(:));
    total_Mz = sum(Mz(:));

end

total_FT = zeros(1,6);

[Fx,Fy,Fz,Mx,My,Mz] = CFT(mesh_A_top,mesh_B_bottom,mag_place_a,[1,dS,before]);
total_FT = total_FT + [Fx,Fy,Fz,Mx,My,Mz];

[Fx,Fy,Fz,Mx,My,Mz] = CFT(mesh_A_bottom,mesh_B_top,mag_place_a,[1,dS,before]);
total_FT = total_FT + [Fx,Fy,Fz,Mx,My,Mz];

[Fx,Fy,Fz,Mx,My,Mz] = CFT(mesh_A_top,mesh_B_top,mag_place_a,[-1,dS,before]);
total_FT = total_FT + [Fx,Fy,Fz,Mx,My,Mz];

[Fx,Fy,Fz,Mx,My,Mz] = CFT(mesh_A_bottom,mesh_B_bottom,mag_place_a,[-1,dS,before]);
total_FT = total_FT + [Fx,Fy,Fz,Mx,My,Mz];

disp(total_FT);