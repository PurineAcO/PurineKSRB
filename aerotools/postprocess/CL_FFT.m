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
        if numel(nums) == 3, data = [data; nums']; end %#ok<AGROW>
    end
end
fclose(fid);
if isempty(data), error('No valid data in: %s', filepath); end

cl          = data(:, 2) * cosd(aoa);  % 修正为真实 CL
flow_time   = data(:, 3);
ts_all      = data(:, 1);             % 时间步序列

% 截断
idx_start  = flow_time >= cutoff_time;
cl         = cl(idx_start);
flow_time  = flow_time(idx_start);
ts_all     = ts_all(idx_start);

if length(cl) < 4
    error('Not enough data points after truncation (need >= 4).');
end

% 计算直流分量（保留用于输出）
dc_offset = mean(cl);
cl = cl - dc_offset;% 去除直流分量

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

% 在截断后的 CL 信号中检测波峰，取最后两个波峰之间的区间作为一个周期
peak_idx = [];
for i = 2:length(cl)-1
    if cl(i) > cl(i-1) && cl(i) > cl(i+1)
        % 简单阈值：波峰幅值至少为主频幅值的一半，排除小噪声
        if abs(cl(i)) > 0.5 * peak_amp
            peak_idx = [peak_idx; i];  %#ok<AGROW>
        end
    end
end

if length(peak_idx) < 2
    error('CL 信号中检测到的波峰不足 2 个（%d 个），无法确定周期。', length(peak_idx));
end

% 取最后两个波峰
i_prev = peak_idx(end-1);
i_last = peak_idx(end);

t_start   = flow_time(i_prev);
t_end     = flow_time(i_last);
ts_start  = round(ts_all(i_prev));
ts_end    = round(ts_all(i_last));
T_period  = t_end - t_start;
time_interval     = [t_start, t_end];
timestep_interval = [ts_start, ts_end];

fprintf('\n========== FFT Analysis ==========\n');
fprintf('  Cutoff time:              %.4f s\n', cutoff_time);
fprintf('  Samples after truncation:  %d\n', L);
fprintf('  DC component (mean CL):    %.6f\n', dc_offset);
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
fprintf('  -------- Last Cycle (peak-to-peak) --------\n');
fprintf('  Peaks detected:            %d\n', length(peak_idx));
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
