clc;clear;
disp("Main MATLAB Code is ready:");

%% Testing the functions
% 导弹位置 A，烟雾弹位置 B，遮蔽半径 R
A = [0, 0, 100];      % 导弹悬停在 (0,0,100)
B = [60, 40, 80];     % 烟雾弹在 (60,40,80)
R = 30;               % 遮蔽半径 30m

[e, alpha] = form_cone_face(A, B, R);
f = form_shade_area(e, A, alpha);

% 待测点 P(200, 200)
P_test = [200, 200];
in = point_is_in_shade_area(P_test, A, e, alpha);
if in
    fprintf('点 (%.0f, %.0f) 在阴影区域内.\n', P_test(1), P_test(2));
    marker = 'g*';  % 绿色星号
else
    fprintf('点 (%.0f, %.0f) 不在阴影区域内.\n', P_test(1), P_test(2));
    marker = 'mx';  % 紫色叉号
end

figure;
fimplicit(f, [-50, 250, -50, 250], 'LineWidth', 1.5);
hold on;
plot(A(1), A(2), 'r^', 'MarkerSize', 10, 'MarkerFaceColor', 'r');   % 导弹投影
plot(B(1), B(2), 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');   % 烟雾弹投影
plot(P_test(1), P_test(2), marker, 'MarkerSize', 12, 'LineWidth', 2); % 待测点
hold off;
axis equal; grid on;
xlabel('x (m)'); ylabel('y (m)');
title('烟雾弹阴影区域 & 待测点 P(200,200)');
legend('阴影边界', '导弹投影', '烟雾弹投影', '待测点 P(200,200)', 'Location', 'best');


%% Tool Functions

function [length,res] = if_in_smoke(A,B,R)
% A表示导弹位置,B表示烟雾弹位置,R表示遮蔽区域半径,判断是否满足距离限制
% 当满足这一条件时,在主求解程序中可以直接跳出

length = norm(A-B); % 待测点和烟雾弹的空间距离

if length < R-1e-6
    res = true;
else 
    res = false;
end

end

function res = if_higher(A,B)
% A表示导弹位置,B表示烟雾弹位置,判断是否烟雾弹高于待测点
% 如果烟雾弹高于待测点,主程序直接结束运行(不只是跳出),因为再无可能满足要求

res = A(3) < B(3);

end

function [e,alpha] = form_cone_face(A,B,R)
% A表示导弹位置,B表示烟雾弹位置,R表示遮蔽区域半径,用于输出圆锥截面参数

d = norm(B-A);
e = (B-A)/d;
alpha = asin(R/d); % 此处角度以弧度为单位

end

function f = form_shade_area(e, A, alpha)
% e表示轴线上单位向量,A表示导弹位置,alpha为圆锥顶角大小.
% (弃用的函数)返回一个函数句柄f,用于表示在地面上的投影边界的隐式方程

l = e(1);  m = e(2);  n = e(3);
xA = A(1); yA = A(2); zA = A(3);
c = cos(alpha);

f = @(x, y) (l^2 - c^2)*(x - xA).^2 ...
          + (m^2 - c^2)*(y - yA).^2 ...
          + 2*l*m*(x - xA).*(y - yA) ...
          - 2*l*n*zA*(x - xA) ...
          - 2*m*n*zA*(y - yA) ...
          + (n^2 - c^2)*zA^2;

fprintf("the shade area is computed over,right")

end

function res = point_is_in_shade_area(P, A, e, alpha)
% P为地面待测点坐标,A为导弹位置,e为圆锥轴线方向,alpha为圆锥顶角大小
% 函数用于判断待测点是否位于遮蔽区域内部.

v = [P(1)-A(1), P(2)-A(2), -A(3)];  % 从导弹指向地面待测点
d = norm(v);

% 先检查是否位于正下方或者反向圆锥面
if d < 1e-12
    res = true;
    return;
end

if dot(v, e) <= 0
    res = false;
    return;
end

% 基于和圆锥轴线的夹角进行判断
res = dot(v, e) >= d * cos(alpha);

end

function res = circle_is_in_shade(C, r_c, A, e, alpha)
% C表示待测圆心,r_c表示待测半径,A,e,alpha含义同上.
% 使用不基于有限元的方法来进行圆形区域是否位于遮蔽区的判断.

c_alpha = cos(alpha);
l = e(1);  m = e(2);  n = e(3);  
v0 = [C(1)-A(1), C(2)-A(2), -A(3)];
v0x = v0(1);  v0y = v0(2);

% 先检查圆心是否位于正下方或者反向圆锥面
d0 = dot(v0, e);
n0 = norm(v0);
if d0 <= 0 || d0 < c_alpha * n0 - 1e-12
    res = false;  return;
end
if r_c < 1e-12
    res = true;   return;
end

% 构造 g'(θ)=0 对应的四次多项式 P(t) 的系数
n02 = n0^2;  r2 = r_c^2;
A_c   = (n02 + r2)*m - d0*v0y;
A_s   = -(n02 + r2)*l + d0*v0x;
A_cs  = r_c * (m*v0y - l*v0x);
A_c2  = r_c * (2*m*v0x - l*v0y);
A_s2  = r_c * (m*v0x - 2*l*v0y);

% P(t) = a4*t^4 + a3*t^3 + a2*t^2 + a1*t + a0
a4 = A_c2 - A_c;
a3 = 2*(A_s - A_cs);
a2 = 4*A_s2 - 2*A_c2;
a1 = 2*(A_s + A_cs);
a0 = A_c + A_c2;

coeff = [a4, a3, a2, a1, a0];

% 找到全部临界角度(既包含最大值,也包含最小值,后者无意义)
t_roots = roots(coeff);
real_t = t_roots(abs(imag(t_roots)) < 1e-10);
theta_crit = 2 * atan(real_t);

% 补充 θ = π（对应 t→∞），仅当四次项退化时可能遗漏
theta_crit = [theta_crit; pi];

% 检查所有候选点的阴影条件
for i = 1:length(theta_crit)
    th = theta_crit(i);
    P = [C(1) + r_c*cos(th), C(2) + r_c*sin(th)];
    if ~point_is_in_shade_area(P, A, e, alpha)
        res = false;
        return;
    end
end

res = true;

end

