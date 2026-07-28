% 对Transonic Buffet的CFD仿真结果进行后处理流程
% 先建立输出部分文件夹,默认的输出位置是脚本所在文件夹的.\output位置,如果没有则会创建.
% 由于Fluent CFD的求解文件过多,不必一定将文件复制到本脚本所在文件夹下,但是需要给出所用文件的正确位置.
% 请不要使用命令行执行这个脚本.
% 本脚本不会对任何量进行滤波.

%% 前导部分:非编程区域
clear;clc;

script_dir = fileparts(mfilename('fullpath'));
output_dir = fullfile(script_dir, 'output');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

diary_file = fullfile(output_dir, 'output.txt');
if exist(diary_file, 'file'), delete(diary_file); end
diary(diary_file);

fprintf("当前的输出目录为:%s\n",output_dir);

%% 主工作区:可编程区域
% ===========================下面是编程区域================================

% 以下为实例,工况为Re=3e6,Ma=0.73的OAT15A的Buffet数据,由于OAT15A的中弧线未知,故使用基于估计的直线替代.
output = reynold('Re',3e6, 'Ma',0.73, 'L',1,'T_in',300);
disp(output);

FILE_PREFIX = '1-20-';
OAT15A = @(t) (t <= 0.8) .* (0.025 .* t) + (t > 0.8) .* (0.125 - 0.125 .* t);

% 定义要处理的 AOA 列表及其数据路径
aoa_list = [
    struct('AOA', 3.0, 'cl_path', 'tscache_3deg\cl-rfile.out', 'cp_path', 'tscache_3deg\cpdata');
    struct('AOA', 3.1, 'cl_path', 'tscache_3.1deg\cl-rfile.out', 'cp_path', 'tscache_3.1deg\cpdata');
    struct('AOA', 3.5, 'cl_path', 'tscache_3.5deg\cl-rfile.out', 'cp_path', 'tscache_3.5deg\cpdata');
    struct('AOA', 3.9, 'cl_path', 'tscache_3.9deg\cl-rfile.out', 'cp_path', 'tscache_3.9deg\cpdata');
];

for idx = 1:numel(aoa_list)
    AOA = aoa_list(idx).AOA;
    CLpath = aoa_list(idx).cl_path;
    CPpath = aoa_list(idx).cp_path;
    
    % 为每个 AOA 创建独立的输出子目录
    aoa_label = sprintf('aoa_%.1f', AOA);
    aoa_output_dir = fullfile(output_dir, aoa_label);
    if ~exist(aoa_output_dir, 'dir')
        mkdir(aoa_output_dir);
    end
    
    fprintf('\n========== Processing AOA = %.1f deg ==========\n', AOA);
    
    try
        plot_CL(CLpath, aoa_output_dir, AOA);
        [main_freq, St, time_interval, timestep_interval] = ...
            CL_FFT(CLpath, aoa_output_dir, 2, output.U_in, output.L, AOA);
        [main_freq_psd, St_psd, ~, ~] = ...
            CL_PSD(CLpath, aoa_output_dir, 2, output.U_in, output.L, AOA);
        
        shock_get(CPpath, aoa_output_dir, timestep_interval, OAT15A, AOA, FILE_PREFIX);
        CP_rms(CPpath, aoa_output_dir, timestep_interval, OAT15A, AOA, FILE_PREFIX);
        rmsave(aoa_output_dir);
        plot_CP_phase(CPpath, aoa_output_dir, timestep_interval, OAT15A, AOA, FILE_PREFIX);
        
        fprintf('========== Finished AOA = %.1f deg ==========\n\n', AOA);
    catch ME
        fprintf('********** ERROR processing AOA = %.1f deg **********\n', AOA);
        fprintf('Error message: %s\n', ME.message);
        fprintf('Skipping to next AOA.\n\n');
    end
end

% =========================================================================

%% 后随部分:非编程区域
fprintf("脚本运行到这里结束了.");
diary off;