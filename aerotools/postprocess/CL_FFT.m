function [main_freq, St, time_interval, timestep_interval] = CL_FFT(filepath, outdir, cutoff_time, U_inf, chord, aoa)
% 对升力系数进行快速傅里叶变换分析
%   filepath    - CL文件路径
%   outdir      - 输出文件夹(默认位于.\output)
%   cutoff_time - 截断非收敛时段的仿真结果
%   U_inf       - 远场来流速度
%   chord       - 弦长
%   aoa         - 迎角[deg],用于图标题
% 返回值:
%   main_freq          - 主频 [Hz]
%   St                 - Strouhal 数
%   time_interval      - 最后一个物理周期的时间区间 [t_start, t_end] [s]
%   timestep_interval  - 对应的时间步区间 [ts_start, ts_end]

fid = fopen(filepath, 'r');
if fid == -1, error('Cannot open file: %s', filepath); end
for i = 1:3, fgetl(fid); end
data = [];
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line) && ~isempty(strtrim(line))
        nums = sscanf(line, '%f %f %f');
        if numel(nums) == 3, data = [data; nums']; end
    end
end
fclose(fid);
if isempty(data), error('No valid data in: %s', filepath); end

% 保留原始完整数据（用于后面提取 timestep 区间）
original_data = data;
cl          = data(:, 2);
flow_time   = data(:, 3);

% 截断
idx_start  = flow_time >= cutoff_time;
cl         = cl(idx_start);
flow_time  = flow_time(idx_start);

if length(cl) < 4
    error('Not enough data points after truncation (need >= 4).');
end

cl = cl - mean(cl);% 去除直流分量

% FFT
Fs = 1 / mean(diff(flow_time));
L  = length(cl);

Y  = fft(cl);
P2 = abs(Y / L);
P1 = P2(1:floor(L/2) + 1);
P1(2:end-1) = 2 * P1(2:end-1);
f = Fs * (0:floor(L/2)) / L;

% 定位主频
[peak_amp, idx] = max(P1(2:end));
main_freq = f(idx + 1);

% 计算主频对应 Strouhal number
St = main_freq * chord / U_inf;

% 从原始数据提取最后一个物理周期的 timestep 区间
T_period = 1 / main_freq;
t_end    = original_data(end, 3);
t_start  = t_end - T_period;
[~, i_start] = min(abs(original_data(:, 3) - t_start));
i_end = size(original_data, 1);
ts_start = original_data(i_start, 1);
ts_end   = original_data(i_end, 1);
time_interval     = [t_start, t_end];
timestep_interval = [ts_start, ts_end];

fprintf('\n========== FFT Analysis ==========\n');
fprintf('  Cutoff time:              %.4f s\n', cutoff_time);
fprintf('  Samples after truncation:  %d\n', L);
fprintf('  Sampling frequency:        %.2f Hz\n', Fs);
fprintf('  Frequency resolution:      %.4f Hz\n', f(2));
fprintf('  Main frequency:            %.4f Hz\n', main_freq);
fprintf('  Peak amplitude:            %.6f\n', peak_amp);
fprintf('  U_inf:                     %.2f m/s\n', U_inf);
fprintf('  Chord:                     %.4f m\n', chord);
fprintf('  Strouhal number (St):      %.4f\n', St);
fprintf('  ======== Top 5 Frequencies ========\n');
[~, idx_sort] = sort(P1(2:end), 'descend');
for k = 1:min(5, length(idx_sort))
    fi = idx_sort(k) + 1;
    fprintf('  %d.  %.4f Hz  (%.6f)\n', k, f(fi), P1(fi));
end
fprintf('  -------- Last Cycle (original data) --------\n');
fprintf('  Physical period:           %.6f s\n', T_period);
fprintf('  Time range:                [%.6f, %.6f] s\n', t_start, t_end);
fprintf('  Time-step range:           [%d, %d]\n', ts_start, ts_end);
fprintf('==================================\n\n');

fig = figtool.newfig(5.0, 3.5);
f_max = 6 * main_freq;
idx_plot = f <= f_max;
plot(f(idx_plot), P1(idx_plot), 'b-', 'LineWidth', 1.2);
ylim([0,peak_amp*1.1]);
hold on;
plot(main_freq, peak_amp, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
text(main_freq, peak_amp, sprintf('  %.4f Hz', main_freq), ...
    'FontSize', 9, 'Color', 'r');
hold off;
figtool.lbl2axis('$f$ (Hz)', '$|C_L(f)|$', sprintf('AOA = %d', aoa));
figtool.savepng(fig, outdir, 'CL_fft.png');

end
