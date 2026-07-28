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
AOA = 3.9;
fprintf("AOA is %f",AOA);
FILE_PREFIX = '1-20-';

CLpath = "tscache\cl-rfile.out";
CPpath = 'tscache\cpdata';
plot_CL(CLpath, output_dir, AOA);
[main_freq, St, time_interval, timestep_interval] = ...
    CL_FFT(CLpath, output_dir,2, output.U_in, output.L, AOA);
[main_freq_psd, St_psd, ~, ~] = ...
    CL_PSD(CLpath, output_dir,2, output.U_in, output.L, AOA);

OAT15A = @(t) (t <= 0.8) .* (0.025 .* t) + (t > 0.8) .* (0.125 - 0.125 .* t);

% CPpaths = {'tscache\OAT15A_1_2d-0410', 'tscache\OAT15A_1_2d-0560'};
% plot_CP(CPpaths, output_dir, OAT15A, 'up', {'CP1', 'CP2'}, AOA);
% plot_CF(CPpaths, output_dir, OAT15A,'up', {'CF1', 'CF2'},AOA);

shock_get(CPpath, output_dir, timestep_interval, OAT15A, AOA, FILE_PREFIX);

CP_rms(CPpath, output_dir, timestep_interval, OAT15A, AOA, FILE_PREFIX);
rmsave(output_dir);

plot_CP_phase(CPpath, output_dir, timestep_interval, OAT15A, AOA, FILE_PREFIX);

% =========================================================================

%% 后随部分:非编程区域
fprintf("脚本运行到这里结束了.");
diary off;