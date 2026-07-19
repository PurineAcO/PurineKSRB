function savepng(fig, outdir, filename)
% 保存为 300 dpi PNG 并报告路径
p = fullfile(outdir, filename);
print(fig, p, '-dpng', '-r300');
fprintf('图片已保存至PNG:%s\n', p);
end