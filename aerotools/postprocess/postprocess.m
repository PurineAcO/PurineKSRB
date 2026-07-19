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

output = reynold('Re',3e6, 'Ma',0.73, 'L',0.25,'T_in',300);
AOA = 5;
FILE_PREFIX = 'OAT15A_1_2d-';

CLpath = 'tscache\cl-rfile.out';
plot_CL(CLpath, output_dir, AOA);
[main_freq, St, time_interval, timestep_interval] = ...
    CL_FFT(CLpath, output_dir, 0.01, output.U_in, 0.25, AOA);

OAT15A = @(t) (t <= 0.8) .* (0.025 .* t) + (t > 0.8) .* (0.125 - 0.125 .* t);

% CPpaths = {'tscache\OAT15A_1_2d-0410', 'tscache\OAT15A_1_2d-0560'};
% plot_CP(CPpaths, output_dir, OAT15A, 'up', {'CP1', 'CP2'}, AOA);
% plot_CF(CPpaths, output_dir, OAT15A,'up', {'CF1', 'CF2'},AOA);

CP_rms('tscache\cp_data', output_dir, timestep_interval, OAT15A, AOA, FILE_PREFIX);

% =========================================================================

%% 后随部分:非编程区域
diary off;