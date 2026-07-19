function plot_CL(filepath, outdir, aoa)

fid = fopen(filepath, 'r');
if fid == -1, error('Cannot open file: %s', filepath); end
for i = 1:3, fgetl(fid); end

data = [];
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line) && ~isempty(strtrim(line))
        nums = sscanf(line, '%f %f %f');
        if numel(nums) == 3, data = [data; nums']; end  %#ok<AGROW>
    end
end
fclose(fid);
if isempty(data), error('No valid data in: %s', filepath); end

cl = data(:, 2);  flow_time = data(:, 3);

fig = figtool.newfig(5.0, 3.5);
plot(flow_time, cl, 'b-', 'LineWidth', 1.2);
figtool.lbl2axis('$t$ (s)', '$C_L$', sprintf('AOA= %d', aoa));
legend({'$C_L$'}, 'Interpreter', 'latex', 'FontSize', 9, 'Location', 'southeast');
figtool.savepng(fig, outdir, 'CL_t.png');

end