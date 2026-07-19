function lbl2axis(xlab, ylab, titlestr)
% 设置坐标轴标签 (ylabel 旋转 0°)
set(gca, 'FontSize', 10, 'FontName', 'Times New Roman');
grid off; box on;
xlabel(xlab, 'Interpreter', 'latex', 'FontSize', 11);
ylabel(ylab, 'Interpreter', 'latex', 'FontSize', 11, 'Rotation', 0);
title(titlestr, 'FontSize', 12, 'FontWeight', 'normal');
end