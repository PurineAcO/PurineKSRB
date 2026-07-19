function fig = newfig(w, h)
% 创建 IEEE 风格图窗
fig = figure('Visible', 'on', 'Units', 'inches', ...
    'Position', [1, 1, w, h], 'PaperPositionMode', 'auto', 'Color', 'w');
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
end
