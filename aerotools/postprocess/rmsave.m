function rmsave(outdir)
% 可视化 rmsave.txt 中的 Cp 数据
%   outdir  - 输出文件夹（默认: 脚本目录下的 output）

if nargin < 1
    script_dir = fileparts(mfilename('fullpath'));
    outdir = fullfile(script_dir, 'output');
end

rmsave_path = fullfile(outdir, 'rmsave.txt');
if ~exist(rmsave_path, 'file')
    error('未找到 %s，请先运行 postprocess.m', rmsave_path);
end

% 读取数据（跳过标题行）
fid = fopen(rmsave_path, 'r');
fgetl(fid); % 跳过标题行
data = [];
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line) && ~isempty(strtrim(line))
        nums = sscanf(line, '%f %f %f');
        if numel(nums) == 3, data = [data; nums']; end
    end
end
fclose(fid);

x_over_c = data(:, 1);
cp_mean  = data(:, 2);
cp_rms   = data(:, 3);

% 子图1: Cp_mean vs x/c
fig = figtool.newfig(5.0, 6.0);

subplot(2, 1, 1);
plot(x_over_c, cp_mean, 'b-', 'LineWidth', 1.2);
ylabel('$\bar{C}_p$', 'Interpreter', 'latex', 'FontSize', 11, 'Rotation', 0);
title('Mean $C_p$ on Upper Surface', 'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'normal');
set(gca, 'FontSize', 10, 'FontName', 'Times New Roman');
grid off; box on;
xlabel('$x/c$', 'Interpreter', 'latex', 'FontSize', 11);
set(gca, 'YDir', 'reverse');

% 子图2: Cp_rms vs x/c
subplot(2, 1, 2);
plot(x_over_c, cp_rms, 'r-', 'LineWidth', 1.2);
ylabel('$C_{p,rms}$', 'Interpreter', 'latex', 'FontSize', 11, 'Rotation', 0);
title('RMS $C_p$ on Upper Surface', 'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'normal');
set(gca, 'FontSize', 10, 'FontName', 'Times New Roman');
grid off; box on;
xlabel('$x/c$', 'Interpreter', 'latex', 'FontSize', 11);

figtool.savepng(fig, outdir, 'rmsave_viz.png');

fprintf('可视化已保存至: %s\n', fullfile(outdir, 'rmsave_viz.png'));
end
