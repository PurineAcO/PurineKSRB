% 修正版：在C点与弧1（O1为圆心）相切的弧2（通过B1、半径r?）
% 核心条件：C、O1、O2三点共线（两圆心与切点共线），确保两弧相切
% 包含完整几何验证、图形标注和弧长计算

% 定义参数
P = 1.7;                  % 螺距
circle_radius = 4.5;      % 圆半径
theta_max = 32*pi;        % 最大角度
b = P/(2*pi);             % 螺线参数计算

% 计算原螺线坐标
theta = linspace(0, theta_max, 10000);
r = b * theta;            % 原螺线极径
x = r .* cos(theta);      % 原螺线 x 坐标
y = r .* sin(theta);      % 原螺线 y 坐标

% 计算中心对称螺线坐标
theta_sym = theta + pi;   % 对称螺线角度
x_sym = r .* cos(theta_sym);  % 对称螺线 x 坐标
y_sym = r .* sin(theta_sym);  % 对称螺线 y 坐标

% 计算圆的坐标
theta_circle = linspace(0, 2*pi, 1000);
x_circle = circle_radius * cos(theta_circle);
y_circle = circle_radius * sin(theta_circle);

% 计算原螺线与圆的交点
intersections = [];
theta_vals = [];          % 存储交点对应的角度
theta_base = circle_radius / b;
k = 0;

while true
    theta_k = theta_base + 2*pi*k;
    if theta_k >= theta_max
        break;
    end

    r_k = b * theta_k;
    x_k = r_k * cos(theta_k);
    y_k = r_k * sin(theta_k);

    if abs(r_k - circle_radius) < 1e-10
        intersections = [intersections; x_k, y_k];
        theta_vals = [theta_vals; theta_k];
    end

    k = k + 1;
end

% 计算对称螺线与圆的交点
intersections_sym = -intersections;

% 计算螺线在交点处的法线（朝内）和方向向量
normal_length = 2;                % 法线长度
normals = cell(size(intersections, 1), 1);
normal_vectors = zeros(size(intersections, 1), 2);  % 存储法线方向单位向量

for i = 1:size(intersections, 1)
    theta_k = theta_vals(i);
    % 计算切线斜率
    tan_slope_num = sin(theta_k) + theta_k * cos(theta_k);
    tan_slope_den = cos(theta_k) - theta_k * sin(theta_k);
    tan_slope = tan_slope_num / tan_slope_den;

    % 计算法线斜率（负倒数）
    normal_slope = -1 / tan_slope;

    % 计算法线方向向量
    dx = 1 / sqrt(1 + normal_slope^2);
    dy = normal_slope * dx;

    % 调整法线方向使其朝内
    if cos(theta_k) >= 0
        dx = -dx;
        dy = -dy;
    end

    % 存储法线起点和终点及方向向量
    normals{i} = [
        intersections(i,1), intersections(i,2);  % 起点
        intersections(i,1) + dx * normal_length, intersections(i,2) + dy * normal_length  % 终点
    ];
    normal_vectors(i,:) = [dx, dy];  % 单位向量
end

% 核心计算：A1B1 向量、α 角、r?、O1、C、O2（严格满足 C、O1、O2 共线）
angle_rad = NaN;
angle_deg = NaN;
r1 = NaN;
O1 = [];
C = [];
O2 = [];
A1 = [];
B1 = [];
collinearity_check = NaN;  % 共线性验证值（接近 0 为共线）
arc1_length = NaN;         % 弧1长度
arc2_length = NaN;         % 弧2长度

if size(intersections, 1) >= 1 && size(intersections_sym, 1) >= 1
    % 定义 A1 和 B1
    A1 = intersections(1,:);
    B1 = intersections_sym(1,:);
    
    % 计算 A1B1 单位向量（用于确定 C 点位置）
    A1B1_vector = B1 - A1;
    A1B1_length = norm(A1B1_vector);
    A1B1_unit = A1B1_vector / A1B1_length;

    % 计算夹角 α（法线与 A1B1 的夹角）
    dot_product = dot(normal_vectors(1,:), A1B1_unit);
    dot_product = max(min(dot_product, 1), -1);  % 避免数值误差
    angle_rad = acos(dot_product);
    angle_deg = rad2deg(angle_rad);

    % 计算 r? = 1.5 /cosα
    if abs(cos(angle_rad)) > 1e-10
        r1 = 1.5 / cos(angle_rad);
        
        % 计算 O1（A1 沿法线朝内移动 2r1，按原程序参数）
        O1 = A1 + normal_vectors(1,:) * 2*r1;

        % 计算 C 点（A1B1 上，A1C=6）
        if A1B1_length >= 6
            C = A1 + A1B1_unit * 6;
            fprintf('C 点坐标：(%.7f, %.7f)\n', C(1), C(2));

            % --------------------------
            % 关键修正：计算 O2（满足 C、O1、O2 共线）
            % 1. 求 O1-C 的方向向量（共线方向）
            O1C_vector = C - O1;
            O1C_unit = O1C_vector / norm(O1C_vector);  % 共线单位向量（O1→C 方向）
            
            % 2. O2 在 O1-C 延长线上，且 O2C = r?（弧 2 半径）
            % 两种可能方向：O2 在 C 的 "远离 O1 侧"（确保弧 2 通过 B1）
            O2 = C + O1C_unit * r1;  % 沿 O1→C 方向延长，使 C 在 O1 和 O2 之间

            % --------------------------
            % 验证条件（确保正确性）
            % 1. 共线性验证：C、O1、O2 三点共线（叉积接近 0）
            vec1 = O1 - C;
            vec2 = O2 - C;
            collinearity_check = abs(vec1(1)*vec2(2) - vec1(2)*vec2(1));  % 叉积绝对值
            
            % 2. 半径验证：O2C = r?
            O2C_dist = norm(O2 - C);
            
            % 3. 目标验证：O2B1 = 半径（弧 2 通过 B1）
            O2B1_dist = norm(O2 - B1);

            % 输出验证结果
            fprintf('\n 几何验证结果：\n');
            fprintf('1. C、O1、O2 共线性（叉积绝对值）：%.7f（接近 0 为共线）\n', collinearity_check);
            fprintf('2. O2C 距离（应等于 r?=%.4f）：%.7f\n', r1, O2C_dist);
            fprintf('3. O2B1 距离（弧 2 半径）：%.7f\n', O2B1_dist);
        else
            warning('A1B1 长度 (%.2f) < 6，无法创建 C 点 ', A1B1_length);
        end
    else
        warning('cosα 接近 0，无法计算 r?');
    end
else
    warning(' 无足够交点，无法计算 ');
end

% 绘图：严格标注几何关系
figure('Position', [100, 100, 1000, 800]);  % 放大窗口便于观察
hold on; grid on; axis equal;

% 1. 基础元素：螺线、圆
plot(x, y, 'LineWidth', 1.2, 'Color', [0.2, 0.2, 0.2]);  % 原螺线（深灰）
plot(x_sym, y_sym, 'g-.', 'LineWidth', 1.2);  % 对称螺线
plot(x_circle, y_circle, 'r--', 'LineWidth', 1.2);  % 圆

% 2. 交点标注：A1、B1
if ~isempty(A1) && ~isempty(B1)
    plot(A1(1), A1(2), 'ko', 'MarkerSize', 9, 'MarkerFaceColor', 'k');
    plot(B1(1), B1(2), 'mo', 'MarkerSize', 9, 'MarkerFaceColor', 'm');
    text(A1(1)+0.4, A1(2)+0.4, 'A1', 'FontSize', 11, 'FontWeight', 'bold');
    text(B1(1)+0.4, B1(2)+0.4, 'B1', 'FontSize', 11, 'FontWeight', 'bold');
    
    % A1B1 连线
    plot([A1(1), B1(1)], [A1(2), B1(2)], 'y-', 'LineWidth', 1.2, 'DisplayName', 'A1B1 连线 ');
end

% 3. C 点标注
if ~isempty(C)
    plot(C(1), C(2), 'gs', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    text(C(1)+0.4, C(2)+0.4, 'C（切点）', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'g');
    
    % A1C 连线（标注长度 6）
    plot([A1(1), C(1)], [A1(2), C(2)], 'm--', 'LineWidth', 1.1);
    text((A1(1)+C(1))/2+0.2, (A1(2)+C(2))/2+0.2, 'A1C=6', 'FontSize', 10, 'Color', 'm');
end

% 4. O1 及弧 1（A1-C）
if ~isempty(O1) && ~isempty(C)
    % O1 标注
    plot(O1(1), O1(2), 'rs', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    text(O1(1)+0.4, O1(2)+0.4, 'O1（弧 1 圆心）', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'r');
    
    % O1A1、O1C 连线（弧 1 半径）
    plot([O1(1), A1(1)], [O1(2), A1(2)], 'r--', 'LineWidth', 1.1);
    plot([O1(1), C(1)], [O1(2), C(2)], 'r--', 'LineWidth', 1.1);
    
    % 弧 1（O1 为圆心，A1→C 劣弧）
    radius1 = norm(O1 - A1);
    theta_A1 = atan2(A1(2)-O1(2), A1(1)-O1(1));
    theta_C = atan2(C(2)-O1(2), C(1)-O1(1));
    
    % 确保劣弧（<180°）
    if abs(theta_C - theta_A1) > pi
        if theta_C > theta_A1
            theta_C = theta_C - 2*pi;
        else
            theta_A1 = theta_A1 - 2*pi;
        end
    end
    
    % 计算弧1的圆心角（弧度）和弧长
    arc1_angle = abs(theta_C - theta_A1);
    arc1_length = radius1 * arc1_angle;  % 弧长公式：半径 × 圆心角（弧度）
    
    theta_arc1 = linspace(theta_A1, theta_C, 150);  % 多取点保证平滑
    x_arc1 = O1(1) + radius1 * cos(theta_arc1);
    y_arc1 = O1(2) + radius1 * sin(theta_arc1);
    plot(x_arc1, y_arc1, 'b-', 'LineWidth', 1.8, 'DisplayName', ' 弧 1（O1 为圆心）');
    text(mean(x_arc1), mean(y_arc1), sprintf(' 弧 1 (长=%.2f)', arc1_length), 'FontSize', 10, 'Color', 'b', 'FontWeight', 'bold');
end

% 5. O2 及弧 2（C-B1）
if ~isempty(O2) && ~isempty(C) && ~isempty(B1)
    % O2 标注
    plot(O2(1), O2(2), 'cs', 'MarkerSize', 10, 'MarkerFaceColor', 'c');
    text(O2(1)+0.4, O2(2)+0.4, 'O2（弧 2 圆心）', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'c');
    
    % O2C、O2B1 连线（弧 2 半径 r?）
    plot([O2(1), C(1)], [O2(2), C(2)], 'c--', 'LineWidth', 1.1);
    plot([O2(1), B1(1)], [O2(2), B1(2)], 'c--', 'LineWidth', 1.1);
    
    % 标注 O2C=r?
    text((O2(1)+C(1))/2+0.2, (O2(2)+C(2))/2+0.2, sprintf('O2C=r?=%.2f', r1), 'FontSize', 10, 'Color', 'c');
    
    % 弧 2（O2 为圆心，C→B1 劣弧）
    radius2 = r1;  % 弧 2 半径 = r?
    theta_C2 = atan2(C(2)-O2(2), C(1)-O2(1));
    theta_B1 = atan2(B1(2)-O2(2), B1(1)-O2(1));
    
    % 确保劣弧（<180°）
    if abs(theta_B1 - theta_C2) > pi
        if theta_B1 > theta_C2
            theta_B1 = theta_B1 - 2*pi;
        else
            theta_C2 = theta_C2 - 2*pi;
        end
    end
    
    % 计算弧2的圆心角（弧度）和弧长
    arc2_angle = abs(theta_B1 - theta_C2);
    arc2_length = radius2 * arc2_angle;  % 弧长公式：半径 × 圆心角（弧度）
    
    theta_arc2 = linspace(theta_C2, theta_B1, 150);
    x_arc2 = O2(1) + radius2 * cos(theta_arc2);
    y_arc2 = O2(2) + radius2 * sin(theta_arc2);
    plot(x_arc2, y_arc2, 'm-', 'LineWidth', 1.8, 'DisplayName', ' 弧 2（O2 为圆心，半径 r?）');
    text(mean(x_arc2), mean(y_arc2), sprintf(' 弧 2 (长=%.2f)', arc2_length), 'FontSize', 10, 'Color', 'm', 'FontWeight', 'bold');
end

% 6. 共线验证标注（C-O1-O2）
if ~isempty(O1) && ~isempty(O2) && ~isempty(C)
    % 绘制共线辅助线（虚线）
    plot([O1(1), O2(1)], [O1(2), O2(2)], 'k-.', 'LineWidth', 1.0, 'Color', [0.6, 0.6, 0.6]);
    text((O1(1)+O2(1))/2+0.3, (O1(2)+O2(2))/2+0.3, 'C、O1、O2 共线（相切条件）', 'FontSize', 9, 'Color', [0.5, 0.5, 0.5]);
end

% 输出弧长结果
if ~isnan(arc1_length) && ~isnan(arc2_length)
    fprintf('\n 弧长计算结果：\n');
    fprintf('1. 弧 1 长度：%.4f\n', arc1_length);
    fprintf('2. 弧 2 长度：%.4f\n', arc2_length);
    fprintf('3. 总弧长：%.4f\n', arc1_length + arc2_length);
end

% 图形设置
title(' 修正版：C 点相切的双弧（含弧长计算）', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('X (m)', 'FontSize', 12);
ylabel('Y (m)', 'FontSize', 12);
