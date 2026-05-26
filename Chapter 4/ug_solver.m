%% ug_solver.m
% U-g method wing flutter solver — span sensitivity analysis
% Solution: Parameters → Theodorsen → Q0 → Eigenvalues → U-g scan → Flutter → Visualization

clear; close all;

%% ===== 1. Parameters (read from JSON) =====
try
    json_path = fullfile(fileparts(mfilename('fullpath')), 'input_params.json');
catch
    json_path = 'input_params.json';  % fallback if run as cell
end
fid = fopen(json_path, 'r');
raw = fread(fid, inf, 'uint8=>char')';
fclose(fid);
params = jsondecode(raw);

b       = params.b;
a       = params.a;
m       = params.m;
S       = params.S;
I_alpha = params.I_alpha;
k_w     = params.k_w;
k_alpha = params.k_alpha;
rho     = params.rho;

M = [m, S; S, I_alpha];
K = [k_w, 0; 0, k_alpha];

k_start = params.k_start;
k_end   = params.k_end;
k_step  = params.k_step;
k_array = k_start:k_step:k_end;

span_list = params.span_list;
ref_span  = params.ref_span;
ref_U     = params.ref_U;

% Build REF map
REF = containers.Map('KeyType', 'double', 'ValueType', 'double');
for i = 1:length(ref_span)
    REF(ref_span(i)) = ref_U(i);
end

%% ===== 2. Solve for each span =====
n_span = length(span_list);
all_branches = cell(n_span, 1);
all_pts      = cell(n_span, 1);

fprintf('============================================================\n');
fprintf('  U-g method flutter solver — span sensitivity analysis\n');
fprintf('  b=%.1f, a=%.1f, density=%.3f\n', b, a, rho);
fprintf('  k in [%.2f, %.2f], dk=%.4f\n', k_array(1), k_array(end), k_step);
fprintf('============================================================\n');

for idx = 1:n_span
    l_val = span_list(idx);
    fprintf('\n--- l = %.1f m ---\n', l_val);

    [branches, flutter_pts] = solve_span(l_val, k_array, b, a, M, K, rho);
    all_branches{idx} = branches;
    all_pts{idx}      = flutter_pts;

    if ~isempty(flutter_pts)
        for j = 1:size(flutter_pts, 1)
            Uf = flutter_pts(j, 1);
            kf = flutter_pts(j, 2);
            lbl_idx = flutter_pts(j, 3);
            omega_f = kf * Uf / b;
            f_f = omega_f / (2 * pi);
            labels = {'branch1(plunge)', 'branch2(pitch)'};
            fprintf('  Flutter: U_f = %.2f m/s  (k = %.4f, f = %.3f Hz, %s)\n', ...
                Uf, kf, f_f, labels{lbl_idx});
        end
    else
        fprintf('  No g=0 crossing detected\n');
    end
end

%% ===== 3. Summary table =====
fprintf('\n============================================================\n');
fprintf('  Span [m]    Calc [m/s]     Ref [m/s]     Error    f_f [Hz]\n');
fprintf('----------------------------------------------------------\n');

l_vals = nan(1, n_span);
U_vals = nan(1, n_span);
for idx = 1:n_span
    l_val = span_list(idx);
    pts = all_pts{idx};
    if ~isempty(pts)
        Uf = min(pts(:, 1));
        rows = pts(abs(pts(:, 1) - Uf) < 0.01, :);
        kf = rows(1, 2);
        omega_f = kf * Uf / b;
        f_f = omega_f / (2 * pi);
        l_vals(idx) = l_val;
        U_vals(idx) = Uf;
        err = (Uf - REF(l_val)) / REF(l_val) * 100;
        fprintf('%8.1f  %12.2f  %12.1f  %+7.1f%%  %10.3f\n', ...
            l_val, Uf, REF(l_val), err, f_f);
    end
end
% Remove NaN entries (spans without flutter points)
l_vals = l_vals(~isnan(l_vals));
U_vals = U_vals(~isnan(U_vals));
fprintf('============================================================\n');

%% ===== 4. Write data to txt =====
fout = fopen('ug_flutter_data.txt', 'w');
fprintf(fout, 'U-g method wing flutter solver — data output\n');
fprintf(fout, 'b=%.1f, a=%.1f, density=%.3f, k in [%.2f, %.2f], dk=%.4f\n', ...
    b, a, rho, k_array(1), k_array(end), k_step);
fprintf(fout, '======================================================================\n\n');

fprintf(fout, 'Part 1: U, g coordinates for each span\n');
fprintf(fout, '----------------------------------------------------------------------\n');
for idx = 1:n_span
    l_val = span_list(idx);
    branches = all_branches{idx};
    fprintf(fout, '\nSpan l = %.1f m\n', l_val);
    branch_labels = {'[plunge]', '[pitch]'};
    for bi = 1:2
        data = branches{bi};
        if ~isempty(data)
            % remove NaN rows
            valid = data(~any(isnan(data), 2), :);
            % sort by k
            [~, si] = sort(valid(:, 1));
            valid = valid(si, :);
            fprintf(fout, '  %s  k          g          U [m/s]\n', branch_labels{bi});
            for r = 1:size(valid, 1)
                fprintf(fout, '  %.5f  %+.6f  %.4f\n', valid(r, 1), valid(r, 2), valid(r, 3));
            end
        end
    end
end

fprintf(fout, '\n\nPart 2: Flutter speed & frequency for each span\n');
fprintf(fout, '----------------------------------------------------------------------\n');
fprintf(fout, '%10s  %12s  %10s  %10s  %12s  %8s\n', ...
    'Span [m]', 'U_f [m/s]', 'k_f', 'f_f [Hz]', 'Ref [m/s]', 'Error');
fprintf(fout, '----------------------------------------------------------------------\n');
for idx = 1:n_span
    l_val = span_list(idx);
    pts = all_pts{idx};
    if ~isempty(pts)
        Uf = min(pts(:, 1));
        rows = pts(abs(pts(:, 1) - Uf) < 0.01, :);
        kf = rows(1, 2);
        omega_f = kf * Uf / b;
        f_f = omega_f / (2 * pi);
        err = (Uf - REF(l_val)) / REF(l_val) * 100;
        fprintf(fout, '%10.1f  %12.3f  %10.4f  %10.3f  %12.1f  %+7.1f%%\n', ...
            l_val, Uf, kf, f_f, REF(l_val), err);
    end
end
fprintf(fout, '----------------------------------------------------------------------\n');
fclose(fout);
fprintf('Data saved: ug_flutter_data.txt\n');

%% ===== 5. Plots =====

% --- Figure 1: U_f vs span ---
figure('Name', 'Flutter speed vs span');
plot(l_vals, U_vals, 'o-', 'Color', [0.12 0.47 0.71], 'LineWidth', 2, ...
    'MarkerSize', 8, 'DisplayName', 'U-g method');
hold on;
plot(ref_span, ref_U, 's--', 'Color', [0.84 0.15 0.16], 'LineWidth', 2, ...
    'MarkerSize', 8, 'DisplayName', 'Reference');
for i = 1:length(l_vals)
    text(l_vals(i), U_vals(i), sprintf('%.1f', U_vals(i)), ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'center', ...
        'FontSize', 9, 'Color', [0.12 0.47 0.71]);
end
for i = 1:length(ref_span)
    text(ref_span(i), ref_U(i), sprintf('%.1f', ref_U(i)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
        'FontSize', 9, 'Color', [0.84 0.15 0.16]);
end
xlabel('Span l [m]', 'FontSize', 13);
ylabel('Flutter speed U_f [m/s]', 'FontSize', 13);
title(sprintf('Effect of span on flutter speed (b=%.1f m, a=%.1f, density=%.3f kg/m^3)', ...
    b, a, rho), 'FontSize', 14);
legend('Location', 'best', 'FontSize', 11);
grid on;
saveas(gcf, 'ug_flutter_span.png');
fprintf('\nFigure saved: ug_flutter_span.png\n');

% --- Figure 2: U-g curves for each span ---
figure('Name', 'U-g curves');
n_cols = 3;
n_rows = 2;
colors = {[0.12 0.47 0.71], [0.84 0.15 0.16]};
branch_names = {'plunge', 'pitch'};

for idx = 1:n_span
    subplot(n_rows, n_cols, idx);
    l_val = span_list(idx);
    branches = all_branches{idx};
    pts = all_pts{idx};
    hold on;

    for bi = 1:2
        data = branches{bi};
        if ~isempty(data)
            valid = data(~any(isnan(data), 2), :);
            [~, si] = sort(valid(:, 1));
            valid = valid(si, :);
            plot(valid(:, 3), valid(:, 2), '-', 'Color', colors{bi}, ...
                'LineWidth', 1.2, 'DisplayName', branch_names{bi});
        end
    end

    yline(0, 'k--', 'LineWidth', 0.8, 'Alpha', 0.5);
    if ~isempty(pts)
        for j = 1:size(pts, 1)
            xline(pts(j, 1), 'g:', 'LineWidth', 1, 'Alpha', 0.7);
            plot(pts(j, 1), 0, 'go', 'MarkerSize', 6, ...
                'MarkerFaceColor', 'none', 'LineWidth', 2);
        end
    end

    title(sprintf('l = %.1f m', l_val), 'FontSize', 12);
    xlabel('U_{\infty} [m/s]', 'FontSize', 10);
    ylabel('g', 'FontSize', 10);
    xlim([0, 100]);
    legend('FontSize', 8, 'Location', 'best');
    grid on;
end
sgtitle('U-g curves for each span', 'FontSize', 15);
saveas(gcf, 'ug_curves_all_spans.png');
fprintf('Figure saved: ug_curves_all_spans.png\n');

fprintf('\n===== Done =====\n');


%% ===== Local functions =====

function C = theodorsen(k)
    % Theodorsen function C(k) = F(k) + i*G(k)
    J0 = besselj(0, k);
    J1 = besselj(1, k);
    Y0 = bessely(0, k);
    Y1 = bessely(1, k);
    denom = (J1 + Y0)^2 + (J0 - Y1)^2;
    F = (J1^2 + Y1^2 + J1*Y0 - J0*Y1) / denom;
    G = -(J0*J1 + Y0*Y1) / denom;
    C = complex(F, G);
end

function Q0 = build_Q0(k, b, a, l)
    % Aerodynamic matrix Q0(k) — four-term superposition
    Ck = theodorsen(k);

    T1 = Ck * l * [
        0.0, -4*pi*b;
        0.0,  4*pi*b^2 * (a + 0.5)
    ];

    T2 = 1i * k * l * [
        0.0, -2*pi*b;
        0.0, -2*pi*b^2 * (0.5 - a)
    ];

    T3 = 1i * k * l * Ck * [
        -4*pi,              -4*pi*b * (0.5 - a);
         4*pi*b * (a + 0.5), 4*pi*b^2 * (a + 0.5) * (0.5 - a)
    ];

    T4 = k^2 * l * [
         2*pi,        -2*pi*b*a;
        -2*pi*b*a,  2*pi*b^2 * (1/8 + a^2)
    ];

    Q0 = T1 + T2 + T3 + T4;
end

function lambdas = solve_single_k(k, b, a, l, M, K, rho)
    % Eigenvalues for a single reduced frequency k
    Q0 = build_Q0(k, b, a, l);
    A = M * (k / b)^2 + (rho / 2.0) * Q0;
    B_inv_A = [A(1,1)/K(1,1), A(1,2)/K(1,1);
               A(2,1)/K(2,2), A(2,2)/K(2,2)];
    lambdas = eig(B_inv_A);
end

function branches = scan_k_with_branches(k_array, b, a, l, M, K, rho)
    % Scan reduced frequencies, track two eigenvalue branches
    branches = cell(2, 1);
    branches{1} = [];
    branches{2} = [];
    prev_lambdas = [];

    for ki = 1:length(k_array)
        k = k_array(ki);
        lambdas = solve_single_k(k, b, a, l, M, K, rho);

        if isempty(prev_lambdas)
            [~, idx] = sort(real(lambdas), 'descend');
            for bi = 1:2
                li = idx(bi);
                lam = lambdas(li);
                if real(lam) > 1e-12
                    branches{bi} = [branches{bi}; k, imag(lam)/real(lam), 1.0/sqrt(real(lam))];
                end
            end
            prev_lambdas = lambdas(idx);
        else
            assigned = [false, false];
            new_order = cell(2, 1);
            for li = 1:2
                lam_new = lambdas(li);
                dists = abs(lam_new - prev_lambdas);
                [~, cand_order] = sort(dists);
                for ci = 1:2
                    cand = cand_order(ci);
                    if ~assigned(cand)
                        assigned(cand) = true;
                        new_order{cand} = lam_new;
                        break;
                    end
                end
            end
            for bi = 1:2
                lam = new_order{bi};
                if ~isempty(lam) && real(lam) > 1e-12
                    branches{bi} = [branches{bi}; k, imag(lam)/real(lam), 1.0/sqrt(real(lam))];
                elseif ~isempty(lam)
                    branches{bi} = [branches{bi}; k, NaN, NaN];
                end
            end
            prev_lambdas = [new_order{1}; new_order{2}];
        end
    end
end

function flutter_pts = find_flutter_from_branches(branches)
    % Detect g=0 crossing → flutter points [U_f, k_f, branch_index]
    flutter_pts = [];
    for bi = 1:2
        data = branches{bi};
        if isempty(data)
            continue;
        end
        valid = data(~any(isnan(data), 2), :);
        [~, si] = sort(valid(:, 1));
        valid = valid(si, :);
        for i = 1:size(valid, 1) - 1
            k_i = valid(i, 1);   g_i = valid(i, 2);   U_i = valid(i, 3);
            k_j = valid(i+1, 1); g_j = valid(i+1, 2); U_j = valid(i+1, 3);
            if g_i * g_j < 0
                t = -g_i / (g_j - g_i);
                U_f = U_i + t * (U_j - U_i);
                k_f = k_i + t * (k_j - k_i);
                flutter_pts = [flutter_pts; U_f, k_f, bi];
            end
        end
    end
end

function [branches, flutter_pts] = solve_span(l_span, k_array, b, a, M, K, rho)
    % Solve for a single span: scan k → track branches → find flutter
    branches = scan_k_with_branches(k_array, b, a, l_span, M, K, rho);
    flutter_pts = find_flutter_from_branches(branches);
end
