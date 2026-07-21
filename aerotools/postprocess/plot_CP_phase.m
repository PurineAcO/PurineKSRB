function plot_CP_phase(cp_dir, outdir, timestep_interval, camber, aoa, file_prefix)
% 将一个周期8等分，绘制对应时间步的上表面 Cp 分布
%   cp_dir             - cp_data 文件夹路径
%   outdir             - 输出文件夹
%   timestep_interval  - 时间步区间 [ts_start, ts_end]
%   camber             - 弯度函数句柄
%   aoa                - 迎角 [deg]
%   file_prefix        - 文件名前缀,如 'OAT15A_1_2d-'

n_div = 8;
ts_start = timestep_interval(1);
ts_end   = timestep_interval(2);

% 生成 8 个等分点的理论 timestep 值
div_ts = round(linspace(ts_start, ts_end, n_div));

% 扫描 cp-data 目录
pattern = [file_prefix, '*'];
all_files = dir(fullfile(cp_dir, pattern));
all_ts = [];
all_paths = {};
for k = 1:numel(all_files)
    fname = all_files(k).name;
    num_str = fname(length(file_prefix)+1:end);
    ts_val = str2double(num_str);
    if ~isnan(ts_val)
        all_ts = [all_ts; ts_val];             %#ok<AGROW>
        all_paths = [all_paths; fullfile(cp_dir, fname)];  %#ok<AGROW>
    end
end

% 筛选 timestep 区间内的文件
in_range = all_ts >= ts_start & all_ts <= ts_end;
all_ts = all_ts(in_range);
all_paths = all_paths(in_range);

if numel(all_ts) < n_div
    error('周期内可用文件数(%d)少于等分数(%d)', numel(all_ts), n_div);
end

% 为每个等分点匹配最近的实际 timestep
selected_paths = cell(n_div, 1);
selected_labels = cell(n_div, 1);
for k = 1:n_div
    [~, idx] = min(abs(all_ts - div_ts(k)));
    selected_paths{k} = all_paths{idx};
    selected_labels{k} = sprintf('%d/8T', k);
    fprintf('  等分点 %d/8: 理论 ts=%d, 实际 ts=%d\n', k, div_ts(k), all_ts(idx));
end

% 前 4 个等分点绘图
fprintf('\n  绘图 Group 1: 等分点 1-4\n');
plot_CP(selected_paths(1:4), outdir, camber, 'up', selected_labels(1:4), aoa);
movefile(fullfile(outdir, 'CP_xc.png'), fullfile(outdir, 'CP_phase_1-4.png'));

% 后 4 个等分点绘图
fprintf('\n  绘图 Group 2: 等分点 5-8\n');
plot_CP(selected_paths(5:8), outdir, camber, 'up', selected_labels(5:8), aoa);
movefile(fullfile(outdir, 'CP_xc.png'), fullfile(outdir, 'CP_phase_5-8.png'));

fprintf('========================================\n');

end
