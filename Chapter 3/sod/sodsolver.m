%% 0. define some consts

% 0.1 physics consts and ques consts
gamma = 1.4;
x_range = [-0.5,0.5];
t_range = [0,0.2];
grid_num = [1000,1000];

% 0.2 process the consts
x_left_bond = x_range(1);  x_right_bond = x_range(2);
t_left_bond = t_range(1);  t_right_bond = t_range(2);
x_length = (x_right_bond-x_left_bond)/grid_num(1);
t_length = (t_right_bond-t_left_bond)/grid_num(2);
CFL = t_length/x_length; % CFL number, this is Delta t/Delta x.

% 0.3 mesh and grid partition
x_arr = linspace(x_left_bond, x_right_bond, grid_num(1)+1);
t_arr = linspace(t_left_bond, t_right_bond, grid_num(2)+1);
u = zeros(grid_num(1)+1, grid_num(2)+1);
p = zeros(grid_num(1)+1, grid_num(2)+1);
rho = zeros(grid_num(1)+1, grid_num(2)+1);
U = zeros(3,grid_num(1)+1, grid_num(2)+1);
F = zeros(3,grid_num(1)+1, grid_num(2)+1);

%% 1. Initialization
u(:, 1) = (x_arr <= 0) * 0.75;                     
p(:, 1) = (x_arr <= 0) * 1 + (x_arr > 0) * 0.1;     
rho(:, 1) = (x_arr <= 0) * 1 + (x_arr > 0) * 0.125;

% conserved variables U = [rho, rho*u, E]  (3 x Nx x Nt)
U(1, :, 1) = rho(:, 1).';
U(2, :, 1) = (rho(:, 1) .* u(:, 1)).';
U(3, :, 1) = (p(:, 1)/(gamma - 1) + 0.5 * rho(:, 1) .* u(:, 1).^2).';

% flux F = [rho*u, rho*u^2 + p, u*(E + p)]  (3 x Nx x Nt)
F(1, :, 1) = (rho(:, 1) .* u(:, 1)).';
F(2, :, 1) = (rho(:, 1) .* u(:, 1).^2 + p(:, 1)).';
F(3, :, 1) = (u(:, 1) .* (U(3, :, 1).' + p(:, 1))).';

%% 2. Time marching
a = CFL / 2;  
Nx = grid_num(1) + 1;

for n = 1:grid_num(2)
    [U(:, :, n+1), rho(:, n+1), u(:, n+1), p(:, n+1), F(:, :, n+1)] = ...
        lax_freidrichs(U(:, :, n), F(:, :, n), gamma, a, Nx);
end

%% 3. plot the results

% 3.1 heatmaps
figure('Name', 'Heatmap of Velocity');
imagesc(t_arr, x_arr, u);
colormap(hot);  colorbar;  axis xy;
title('Heat map of Velocity $u$ in Lax-Friedrichs format', 'Interpreter', 'latex');
xlabel('Mesh points of $t$ (Time distribution)', 'Interpreter', 'latex');
ylabel('Mesh points of $x$ (Space distribution)', 'Interpreter', 'latex');

figure('Name', 'Heatmap of Density');
imagesc(t_arr, x_arr, rho);
colormap(hot);  colorbar;  axis xy;
title('Heat map of Density $\rho$ in Lax-Friedrichs format', 'Interpreter', 'latex');
xlabel('Mesh points of $t$ (Time distribution)', 'Interpreter', 'latex');
ylabel('Mesh points of $x$ (Space distribution)', 'Interpreter', 'latex');

figure('Name', 'Heatmap of Pressure');
imagesc(t_arr, x_arr, p);
colormap(hot);  colorbar;  axis xy;
title('Heat map of Pressure $p$ in Lax-Friedrichs format', 'Interpreter', 'latex');
xlabel('Mesh points of $t$ (Time distribution)', 'Interpreter', 'latex');
ylabel('Mesh points of $x$ (Space distribution)', 'Interpreter', 'latex');

% 3.2 final time snapshot (numerical results only)
figure('Name', 'Final snapshot');
sgtitle('1D Sod shock tube in Lax-Friedrichs format ($t = 0.2$)', 'Interpreter', 'latex');

subplot(2,2,1);
plot(x_arr, u(:, end), 'Color', [0.39, 0.58, 0.93], 'LineWidth', 1.5);
xlabel('$x$ (Spatial distribution)', 'Interpreter', 'latex');
ylabel('$u$ (Velocity)', 'Interpreter', 'latex');
legend('Velocity', 'Location', 'best');

subplot(2,2,2);
plot(x_arr, rho(:, end), 'Color', [0.56, 0.93, 0.56], 'LineWidth', 1.5);
xlabel('$x$ (Spatial distribution)', 'Interpreter', 'latex');
ylabel('$\rho$ (Density)', 'Interpreter', 'latex');
legend('Density', 'Location', 'best');

subplot(2,2,3);
plot(x_arr, p(:, end), 'Color', [1, 0.75, 0.80], 'LineWidth', 1.5);
xlabel('$x$ (Spatial distribution)', 'Interpreter', 'latex');
ylabel('$p$ (Pressure)', 'Interpreter', 'latex');
legend('Pressure', 'Location', 'best');

subplot(2,2,4);
internal_energy = p(:, end) ./ ((gamma - 1) * rho(:, end));
plot(x_arr, internal_energy, 'Color', [1, 0.70, 0.50], 'LineWidth', 1.5);
xlabel('$x$ (Spatial distribution)', 'Interpreter', 'latex');
ylabel('$e$ (Internal energy)', 'Interpreter', 'latex');
legend('Internal energy', 'Location', 'best');

% 3.3 animation
figure('Name', 'Animation');
anim_frames = 1:20:size(u,2);

for k = 1:length(anim_frames)
    idx = anim_frames(k);

    subplot(3,1,1);
    plot(x_arr, u(:, idx), 'Color', [0.39, 0.58, 0.93], 'LineWidth', 1.5);
    ylim([-0.1, 1.5]);
    ylabel('Velocity ($u$)', 'Interpreter', 'latex');
    title(sprintf('1D Sod shock tube in Lax-Friedrichs format ($t = %.3f$)', t_arr(idx)), ...
          'Interpreter', 'latex');
    legend('Velocity', 'Location', 'best');

    subplot(3,1,2);
    plot(x_arr, rho(:, idx), 'Color', [0.56, 0.93, 0.56], 'LineWidth', 1.5);
    ylabel('Density ($\rho$)', 'Interpreter', 'latex');
    legend('Density', 'Location', 'best');

    subplot(3,1,3);
    plot(x_arr, p(:, idx), 'Color', [1, 0.75, 0.80], 'LineWidth', 1.5);
    xlabel('Space ($x$)', 'Interpreter', 'latex');
    ylabel('Pressure ($p$)', 'Interpreter', 'latex');
    legend('Pressure', 'Location', 'best');

    drawnow;

    % capture frame and save as GIF
    frame = getframe(gcf);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    if k == 1
        imwrite(imind, cm, 'animation.gif', 'gif', 'Loopcount', inf, 'DelayTime', 0.01);
    else
        imwrite(imind, cm, 'animation.gif', 'gif', 'WriteMode', 'append', 'DelayTime', 0.01);
    end
end



%% supplement 1: Lax-Friedrichs step function
function [U_next, rho_next, u_next, p_next, F_next] = lax_freidrichs(U_curr, F_curr, gamma, a, Nx)
    %   LAX_FREIDRICHS  Performs one Lax-Friedrichs time step.
    %   Input : U_curr(3xNx), F_curr(3xNx) at current time
    %   Output: U_next(3xNx), rho_next/u_next/p_next(Nx x 1), F_next(3xNx)

    % constant boundary conditions
    U_next = zeros(3, Nx);
    U_next(:, 1)  = U_curr(:, 1);
    U_next(:, Nx) = U_curr(:, Nx);

    % Lax-Friedrichs interior update
    for j = 2:Nx-1
        U_next(:, j) = 0.5 * (U_curr(:, j-1) + U_curr(:, j+1)) ...
                     - a * (F_curr(:, j+1) - F_curr(:, j-1));
    end

    % update flow function from conserved variables
    rho_next = U_next(1, :).';
    u_next   = U_next(2, :).' ./ rho_next;
    p_next   = (U_next(3, :).' - 0.5 * rho_next .* u_next.^2) * (gamma - 1);

    % update flux for next time step
    F_next = zeros(3, Nx);
    F_next(1, :) = (rho_next .* u_next).';
    F_next(2, :) = (rho_next .* u_next.^2 + p_next).';
    F_next(3, :) = (u_next .* (U_next(3, :).' + p_next)).';
end

