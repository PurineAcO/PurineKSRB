clear; clc; close all;

%% 0. Define constants

% All the parameters are defined in the SI unit.
Br = 1.22;                              % Residual magnetic flux density (T)
mu_r = 1.03;                            % Relative permeability
mu_0 = 4*pi*1e-7;                       % Permeability of free space

before = (Br^2)*(mu_r+3)^2/((4*pi*mu_0)*(mu_r+1)^4);

mag_shape_a = [0.01,0.01,0.01];         % Volume parameters [L, W, H]
mag_shape_b = [0.02,0.02,0.02];         % Volume parameters [L, W, H]

mag_place_a = [0,0,0];                  % Centroid position [x, y, z]
mag_place_b = [0.005+0.01+0.001,0,0];   % Centroid position [x, y, z]

% mag_euler_a = [0,0,0];                % Euler angles (attitude) of magnet A
% mag_euler_b = [0,0,0];                % Euler angles (attitude) of magnet B

step = (min(mag_shape_a(1),mag_shape_b(1)))/10;   % Mesh density

%% 1. Generate surface mesh - CELL CENTROIDS (grid center points)

function mesh=mesher(shape,place,step,bt)
    % this function is used to generate the mesh of a cube
    % shape is a vector which contains the length,width and height of the cube
    % place is a vector which contains the centroid position of the cube
    % step is the mesh density
    % bt is a string which is used to determine whether the mesh is top or bottom

    x = place(1)-shape(1)/2+step/2 : step : place(1)+shape(1)/2-step/2;
    y = place(2)-shape(2)/2+step/2 : step : place(2)+shape(2)/2-step/2;
    [X, Y] = meshgrid(x, y);

    if strcmp(bt,'top')
        Z = zeros(size(X)) + place(3) + shape(3)/2;
    elseif strcmp(bt,'bottom')
        Z = zeros(size(X)) + place(3) - shape(3)/2;
    end
    mesh = [X(:), Y(:), Z(:)];

end

mesh_A_top = mesher(mag_shape_a,mag_place_a,step,'top');
mesh_A_bottom = mesher(mag_shape_a,mag_place_a,step,'bottom');
mesh_B_top = mesher(mag_shape_b,mag_place_b,step,'top');
mesh_B_bottom = mesher(mag_shape_b,mag_place_b,step,'bottom');

%% 2. Calculate the force and torque between A and B

dS = step*step;

function [total_Fx, total_Fy, total_Fz,total_Mx, total_My, total_Mz]=CFT(mesh1,mesh2,center1,params)

    % which is used to calculate the force between two meshes,params is a vector which contains
    % the sign of the force,the square of the mesh,and the 'before' constant
    % this function calculate the force and torque which mesh1 feels.
    % if you want the mesh2's force,you need to change the sign of params(1)
    % if you want the mesh2's torque,you need to change the sign of params(1) and 'center1'

    dx = mesh1(:,1) - mesh2(:,1)';
    dy = mesh1(:,2) - mesh2(:,2)';
    dz = mesh1(:,3) - mesh2(:,3)';
    r = sqrt(dx.^2 + dy.^2 + dz.^2);

    Fx = params(1)*(params(2)^2)*params(3).*dx./r.^3;
    Fy = params(1)*(params(2)^2)*params(3).*dy./r.^3;
    Fz = params(1)*(params(2)^2)*params(3).*dz./r.^3;

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