function shock_get(filepaths, outdir, camber, file_prefix)
% 激波捕捉: 通过上表面 Cp 相邻点差分突增识别激波位置
%   filepaths   - 数据文件路径列表（cell 数组）或单个路径
%   outdir      - 输出文件夹
%   camber      - 弯度函数句柄
%   file_prefix - 文件名前缀,用于从文件路径提取时间步号

if ischar(filepaths) || isstring(filepaths)
    filepaths = {char(filepaths)};
end
n_files = numel(filepaths);

shock_path = fullfile(outdir, 'shock_get.txt');
fid_out = fopen(shock_path, 'w');
fprintf(fid_out, '%-12s %-16s\n', 'timestep', 'shock_x/c');

fprintf('\n======= Shock Detection =======\n');

for k = 1:n_files
    fpath = filepaths{k};

    % 从文件名提取时间步号
    [~, fname, ~] = fileparts(fpath);
    if nargin >= 4 && ~isempty(file_prefix)
        num_str = fname(length(file_prefix)+1:end);
    else
        % 尝试提取末尾数字
        num_str = regexp(fname, '\d+$', 'match');
        if isempty(num_str), num_str = fname; end
    end
    timestep = str2double(num_str);

    % 读取数据
    fid = fopen(fpath, 'r');
    if fid == -1, error('无法打开文件: %s', fpath); end
    fgetl(fid); % 跳过标题行
    data = [];
    while ~feof(fid)
        line = fgetl(fid);
        if ischar(line) && ~isempty(strtrim(line))
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
    le_exclude = 0.05;  % 排除前缘干扰
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
        fprintf('  %s: 未检测到激波\n', fname);
    else
        fprintf(fid_out, '%-12d %-16.6f\n', timestep, shock_xc);
        fprintf('  %s: shock at x/c = %.4f\n', fname, shock_xc);
    end
end

fclose(fid_out);
fprintf('==============================\n');
fprintf('激波位置已保存至: %s\n', shock_path);

end
