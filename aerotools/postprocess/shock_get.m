function shock_get(cp_dir, outdir, timestep_interval, camber, aoa, file_prefix)
% 激波捕捉: 扫描 cp_data 目录,在指定时间步区间内逐个检测上表面激波位置
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

shock_path = fullfile(outdir, 'shock_get.txt');
fid_out = fopen(shock_path, 'w');
fprintf(fid_out, '%-12s %-16s\n', 'timestep', 'shock_x/c');

fprintf('\n============ Shock Detection (AOA=%d) ============\n', aoa);

for k = 1:n_files
    fpath = file_list{k};
    timestep = ts_list(k);

    % 读取数据
    fid = fopen(fpath, 'r');
    if fid == -1, error('无法打开文件: %s', fpath); end
    fgetl(fid); % 跳过标题行
    data = [];
    while ~feof(fid)
        line = fgetl(fid);
        if ischar(line) && ~isempty(strtrim(line))
            line = strrep(line, ',', ' ');
            nums = sscanf(line, '%f');
            if numel(nums) >= 4, data = [data; nums(1:5)']; end %#ok<AGROW>
        end
    end
    fclose(fid);

    if isempty(data)
        warning('文件为空: %s', fpath);
        continue;
    end

    x  = data(:, 2);
    y  = data(:, 3);
    cp = data(:, 4);

    % 分离上下表面（同 plot_CP 逻辑）
    chord_len = max(x) - min(x);
    t_norm    = (x - min(x)) / chord_len;
    y_norm    = y / chord_len;
    y_th      = camber(t_norm);

    upper_mask = y_norm > y_th;
    x_upper    = x(upper_mask);
    cp_upper   = cp(upper_mask);

    if length(x_upper) < 3
        warning('上表面点数不足: %s', fpath);
        continue;
    end

    % 按 x 排序
    [x_upper, sort_idx] = sort(x_upper);
    cp_upper = cp_upper(sort_idx);
    xc_upper = (x_upper - min(x)) / chord_len;

    % 相邻点 Cp 差分的绝对值
    delta_cp = abs(diff(cp_upper));

    % 激波定位: 排除前缘区域 (x/c < 0.05) 后取最大 Cp 梯度位置
    le_exclude = 0.05;
    mask = xc_upper(2:end) > le_exclude;
    if any(mask)
        [~, imax] = max(delta_cp(mask));
        idx2 = find(mask);
        shock_xc = xc_upper(idx2(imax));
    else
        shock_xc = NaN;
    end

    % 写入结果
    if isnan(shock_xc)
        fprintf(fid_out, '%-12d %-16s\n', timestep, 'none');
        fprintf('  timestep %d: 未检测到激波\n', timestep);
    else
        fprintf(fid_out, '%-12d %-16.6f\n', timestep, shock_xc);
        fprintf('  timestep %d: shock at x/c = %.4f\n', timestep, shock_xc);
    end
end

fclose(fid_out);
fprintf('========================================\n');
fprintf('激波位置已保存至: %s\n', shock_path);
fprintf('  时间步区间: [%d, %d]\n', ts_start, ts_end);
fprintf('  快照数量: %d\n', n_files);

end
