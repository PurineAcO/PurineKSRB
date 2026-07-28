function CP_rms(cp_dir, outdir, timestep_interval, camber, aoa, file_prefix)
% 计算一个周期内上表面 Cp 的 RMS 并绘图
%   cp_dir             - cp_data 文件夹路径
%   outdir             - 输出文件夹
%   timestep_interval  - 时间步区间 [ts_start, ts_end]
%   camber             - 弯度函数句柄
%   aoa                - 迎角 [deg]
%   file_prefix        - 文件名前缀,如 'OAT15A_1_2d-'

ts_start = timestep_interval(1);
ts_end   = timestep_interval(2);

% 列出所有 cp_data 文件
pattern = [file_prefix, '*'];
files = dir(fullfile(cp_dir, pattern));
if isempty(files)
    error('在 %s 中未找到 cp_data 文件', cp_dir);
end

% 提取文件名的数字后缀并筛选时间步区间内的文件
ts_list = [];
file_list = {};
for k = 1:numel(files)
    fname = files(k).name;
    % 提取文件名的数字后缀
    num_str = fname(length(file_prefix)+1:end);
    ts_val = str2double(num_str);
    if ts_val >= ts_start && ts_val <= ts_end
        ts_list = [ts_list; ts_val];     %#ok<AGROW>
        file_list = [file_list; fullfile(cp_dir, fname)];  %#ok<AGROW>
    end
end

if isempty(file_list)
    error('在 timestep [%d, %d] 区间内未找到 cp_data 文件', ts_start, ts_end);
end

n_files = numel(file_list);
fprintf('找到 %d 个 cp_data 文件 (timestep: %d ~ %d)\n', n_files, ts_list(1), ts_list(end));

% 读取第一个文件获取参考坐标
fid = fopen(file_list{1}, 'r');
if fid == -1, error('无法打开文件: %s', file_list{1}); end
fgetl(fid); % 跳过标题行
ref_data = [];
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line) && ~isempty(strtrim(line))
        line = strrep(line, ',', ' ');
        nums = sscanf(line, '%f');
        if numel(nums) >= 4, ref_data = [ref_data; nums(1:min(end,5))']; end %#ok<AGROW>
    end
end
fclose(fid);

x_ref = ref_data(:, 2);
y_ref = ref_data(:, 3);

% 用弯度函数判断上下表面
chord_len = max(x_ref) - min(x_ref);
t_norm    = (x_ref - min(x_ref)) / chord_len;
y_norm    = y_ref / chord_len;
y_th      = camber(t_norm);

upper_mask = y_norm > y_th;
n_upper   = sum(upper_mask);

if n_upper == 0
    error('未找到上表面节点');
end

% 提取上表面节点的 x
x_upper = x_ref(upper_mask);
% 归一化为 x/c
x_over_c = (x_upper - min(x_ref)) / chord_len;

% 收集所有时间步的 Cp 值（只保留上表面节点）
cp_all = zeros(n_upper, n_files);

for k = 1:n_files
    fid = fopen(file_list{k}, 'r');
    if fid == -1, error('无法打开文件: %s', file_list{k}); end
    fgetl(fid); % 跳过标题行
    data_k = [];
    while ~feof(fid)
        line = fgetl(fid);
        if ischar(line) && ~isempty(strtrim(line))
            line = strrep(line, ',', ' ');
            nums = sscanf(line, '%f');
            if numel(nums) >= 4, data_k = [data_k; nums(4)]; end %#ok<AGROW>
        end
    end
    fclose(fid);
    % 只取上表面节点
    cp_all(:, k) = data_k(upper_mask);
end

% 计算每个 x/c 位置的 Cp RMS（相对于时均值的脉动）
cp_mean = mean(cp_all, 2);
cp_rms  = sqrt(mean((cp_all - cp_mean).^2, 2));

% 排序 x_over_c（理论上已经有序，保险起见）
[x_over_c, sort_idx] = sort(x_over_c);
cp_mean = cp_mean(sort_idx);
cp_rms  = cp_rms(sort_idx);

% 绘图
fig = figtool.newfig(5.0, 3.5);
plot(x_over_c, cp_rms, 'b-', 'LineWidth', 1.2);
figtool.lbl2axis('$x/c$', '$C_{p,rms}$', ...
    sprintf('AOA=%d', aoa));
figtool.savepng(fig, outdir, 'CPrms_xc.png');

% 控制台输出
fprintf('\n===== Cp RMS (Upper Surface, 1 period) =====\n');
fprintf('  Time-step range: [%d, %d]\n', ts_start, ts_end);
fprintf('  Number of snapshots: %d\n', n_files);
fprintf('  Upper surface nodes: %d\n', n_upper);
fprintf('  Max Cp_rms: %.6f at x/c = %.4f\n', max(cp_rms), x_over_c(cp_rms == max(cp_rms)));
fprintf('==========================================\n\n');

% 保存 x/c, Cp_mean, Cp_rms 到文件
rmsave_path = fullfile(outdir, 'rmsave.txt');
fid = fopen(rmsave_path, 'w');
fprintf(fid, '%-12s %-16s %-16s\n', 'x/c', 'Cp_mean', 'Cp_rms');
for k = 1:length(x_over_c)
    fprintf(fid, '%-12.6f %-16.6f %-16.6f\n', x_over_c(k), cp_mean(k), cp_rms(k));
end
fclose(fid);
fprintf('已保存 Cp RMS 数据至: %s\n', rmsave_path);

end
