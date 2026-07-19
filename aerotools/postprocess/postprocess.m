% 对Transonic Buffet的CFD仿真结果进行后处理流程
clear;clc;

%% 前导部分

% 本部分用于建立输出部分文件夹,默认的输出位置是脚本所在文件夹的.\output位置,
% 如果没有则会创建.由于Fluent CFD的求解文件过多,
% 不必一定将文件复制到本脚本所在文件夹下,但是需要给出所用文件的正确位置.
script_dir = fileparts(mfilename('fullpath'));
output_dir = fullfile(script_dir, 'output');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
fprintf("当前的输出目录为:%s\n",output_dir);

%% 主工作区
% 主工作区请使用Function Hook或者顺序执行.不要在命令行执行.
% ===========================下面是编程区域================================

CLpath = 'tscache\cl-rfile.out';
plot_CL(CLpath,output_dir);

OAT15A = @(t) (t <= 0.8) .* (0.025 .* t) + (t > 0.8) .* (0.125 - 0.125 .* t);
CPpaths = {'tscache\OAT15A_1_2d-0410', 'tscache\OAT15A_1_2d-0560'};
plot_CP(CPpaths, output_dir, OAT15A,'up', {'CP1', 'CP2'});
% plot_CF(CPpaths, output_dir, OAT15A,'up', {'CF1', 'CF2'});

% =========================================================================
