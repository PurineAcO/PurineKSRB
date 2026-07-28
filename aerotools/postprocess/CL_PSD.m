function [main_freq, St, time_interval, timestep_interval] = CL_PSD(filepath, outdir, cutoff_time, U_inf, chord, aoa)
% 对升力系数进行功率谱密度(Power Spectral Density)分析
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

% 计算直流分量
dc_offset = mean(cl);
cl = cl - dc_offset;  % 去除直流分量

% 采样参数
Fs = 1 / mean(diff(flow_time));
L  = length(cl);

% ---------- PSD 计算 ----------
if exist('pwelch', 'file') == 2
    % Welch 方法（推荐，方差更小）
    win_len = min(round(L / 4), 512);
    window  = hamming(win_len);
    noverlap = round(win_len * 0.5);
    nfft    = max(256, 2^nextpow2(win_len));
    [psd, f] = pwelch(cl, window, noverlap, nfft, Fs);
    method = 'Welch';
else
    % 周期图法（fallback）
    Y  = fft(cl);
    psd = (abs(Y).^2) / (Fs * L);
    psd = psd(1:floor(L/2) + 1);
    psd(2:end-1) = 2 * psd(2:end-1);
    f = Fs * (0:floor(L/2)) / L;
    method = 'Periodogram';
end

% 定位主频
[peak_psd, idx] = max(psd(2:end));
main_freq = f(idx + 1);

% Strouhal 数
St = main_freq * chord / U_inf;

% 计算 FFT 幅值谱（用于时域峰值检测阈值，与 CL_FFT 一致）
Y_fft       = fft(cl);
P2          = abs(Y_fft / L);
P1          = P2(1:floor(L/2) + 1);
P1(2:end-1) = 2 * P1(2:end-1);
peak_amp    = max(P1(2:end));

% 在截断后的 CL 信号中检测波峰，取最后两个波峰之间的区间作为一个周期
peak_idx = [];
for i = 2:length(cl)-1
    if cl(i) > cl(i-1) && cl(i) > cl(i+1)
        if abs(cl(i)) > 0.5 * peak_amp
            peak_idx = [peak_idx; i]; %#ok<AGROW>
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

fprintf('\n========== PSD Analysis ==========\n');
fprintf('  Cutoff time:              %.4f s\n', cutoff_time);
fprintf('  Samples after truncation:  %d\n', L);
fprintf('  DC component (mean CL):    %.6f\n', dc_offset);
fprintf('  Sampling frequency:        %.2f Hz\n', Fs);
fprintf('  Frequency resolution:      %.4f Hz\n', f(2));
fprintf('  PSD method:                %s\n', method);
fprintf('  Main frequency:            %.4f Hz\n', main_freq);
fprintf('  Peak PSD:                  %.6f CL^2/Hz\n', peak_psd);
fprintf('  U_inf:                     %.2f m/s\n', U_inf);
fprintf('  Chord:                     %.4f m\n', chord);
fprintf('  Strouhal number (St):      %.4f\n', St);
fprintf('  ======== Top 5 Frequencies ========\n');
[~, idx_sort] = sort(psd(2:end), 'descend');
for k = 1:min(5, length(idx_sort))
    fi = idx_sort(k) + 1;
    fprintf('  %d.  %.4f Hz  (%.6f CL^2/Hz)\n', k, f(fi), psd(fi));
end
fprintf('  -------- Last Cycle (peak-to-peak) --------\n');
fprintf('  Peaks detected:            %d\n', length(peak_idx));
fprintf('  Physical period:           %.6f s\n', T_period);
fprintf('  Time range:                [%.6f, %.6f] s\n', t_start, t_end);
fprintf('  Time-step range:           [%d, %d]\n', ts_start, ts_end);
fprintf('==================================\n\n');

% 绘图（双对数坐标，横轴至 10^3 Hz）
fig = figtool.newfig(5.0, 3.5);
idx_plot = f >= f(2) & psd > 0;  % 排除 f=0 的直流和零值
loglog(f(idx_plot), psd(idx_plot), 'b-', 'LineWidth', 1.2);
xlim([f(2), 1000]);
hold on;
loglog(main_freq, peak_psd, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
text(main_freq, peak_psd, sprintf('  %.4f Hz', main_freq), ...
    'FontSize', 9, 'Color', 'r');
hold off;
figtool.lbl2axis('$f$ (Hz)', '$G_{CL}(f)$ (CL$^2$/Hz)', sprintf('AOA = %d', aoa));
figtool.savepng(fig, outdir, 'CL_psd.png');

end
