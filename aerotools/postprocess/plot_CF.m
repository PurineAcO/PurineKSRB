% 支持多个file进行联合绘图,请传入filepaths组和legend_labels组.
% surface_option若选择'both'则为上下表面均绘制
function plot_CF(filepaths, outdir, camber, surface_option, legend_labels, aoa)

if nargin < 4 || isempty(surface_option)
    surface_option = 'both';
end
if nargin < 5
    legend_labels = {};
end
if nargin < 6
    aoa = [];
end

% 统一为 cell 数组
if ischar(filepaths) || isstring(filepaths)
    filepaths = {char(filepaths)};
end
n_files = numel(filepaths);

colors = lines(n_files);

% figure 部分
fig = figtool.newfig(5.0, 3.5);
hold on;

leg_str = cell(1, 0);

for k = 1:n_files
    fpath = filepaths{k};
    color = colors(k, :);

    % 自动图例标签
    if k <= numel(legend_labels) && ~isempty(legend_labels{k})
        lbl = legend_labels{k};
    else
        [~, name, ~] = fileparts(fpath);
        lbl = name;
    end

    % ==== 读取文件 ====
    fid = fopen(fpath, 'r');
    if fid == -1, error('Cannot open file: %s', fpath); end
    fgetl(fid);  % 跳列标题
    data = [];
    while ~feof(fid)
        line = fgetl(fid);
        if ischar(line) && ~isempty(strtrim(line))
            line = strrep(line, ',', ' ');
            nums = sscanf(line, '%f %f %f %f %f');
            if numel(nums) == 5, data = [data; nums']; end  %#ok<AGROW>
        end
    end
    fclose(fid);
    if isempty(data), error('No valid data in: %s', fpath); end

    x = data(:, 2);  y = data(:, 3);
    chord  = max(x) - min(x);
    t      = (x - min(x)) / chord;
    y_norm = y / chord;
    y_th   = camber(t);

    % 上下表面分离
    upper = data(y_norm > y_th, :);
    lower = data(y_norm < y_th, :);

    if strcmp(surface_option, 'both')
        % 上表面实线, 下表面同色虚线
        xu = (upper(:, 2) - min(x)) / chord;  cfu = upper(:, 5);
        [xu, idx] = sort(xu);  cfu = cfu(idx);
        plot(xu, cfu, '-', 'LineWidth', 1.2, 'Color', color);
        xl = (lower(:, 2) - min(x)) / chord;  cfl = lower(:, 5);
        [xl, idx] = sort(xl);  cfl = cfl(idx);
        plot(xl, cfl, '--', 'LineWidth', 1.2, 'Color', color);
        leg_str = [leg_str, {[lbl ' upper']}, {[lbl ' lower']}];  %#ok<AGROW>
    else  % 仅上表面
        xu = (upper(:, 2) - min(x)) / chord;  cfu = upper(:, 5);
        [xu, idx] = sort(xu);  cfu = cfu(idx);
        plot(xu, cfu, '-', 'LineWidth', 1.2, 'Color', color);
        leg_str = [leg_str, {lbl}];  %#ok<AGROW>
    end
end

hold off;

set(gca, 'YDir', 'normal');
if ~isempty(aoa)
    title_str = sprintf('AOA= %d', aoa);
else
    title_str = 'Skin Friction Coefficient Distribution';
end
figtool.lbl2axis('$x/c$', '$C_F$', title_str);

if ~isempty(leg_str)
    legend(leg_str, 'Interpreter', 'latex', 'FontSize', 8, ...
        'Location', 'northeast');
end

    figtool.savepng(fig, outdir, 'CF_xc.png');

end