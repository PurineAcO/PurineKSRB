function [output] = reynold(varargin)
    % 解析输入参数（支持Ma/U_in双输入）
    p = inputParser;
    addParameter(p, 'Re', NaN);
    addParameter(p, 'Ma', NaN);
    addParameter(p, 'U_in', NaN);
    addParameter(p, 'T_in', NaN);
    addParameter(p, 'p_inf', NaN);
    addParameter(p, 'L', NaN);
    parse(p, varargin{:});

    % 提取参数并检查输入冲突
    Re = p.Results.Re;
    Ma_input = p.Results.Ma;
    U_in_input = p.Results.U_in;
    T_in = p.Results.T_in;
    p_inf = p.Results.p_inf;
    L = p.Results.L;

    % 验证输入互斥性
    if ~isnan(Ma_input) && ~isnan(U_in_input)
        error('不能同时输入Ma和U_in！');
    end

    % 常量定义
    kappa = 1.4;
    R_s = 287.7;
    
    % 萨特兰公式参数
    mu0 = 1.716e-5;   % 参考粘度@273.15K [kg/(m·s)]
    T0 = 273.15;      % 参考温度 [K]
    S = 110.4;        % Sutherland常数 [K]
    calcMu = @(T) mu0 * (T/T0).^(3/2) * (T0 + S) ./ (T + S);

    % 初始化过程数据结构
    processData = struct();
    processData.iterations = 0;
    processData.T_history = [];
    processData.mu_history = [];

    % 确定缺失变量
    missing_vars = {};
    vars = {'Re', 'T_in', 'p_inf', 'L'};
    for i = 1:length(vars)
        if isnan(eval(vars{i}))
            missing_vars{end+1} = vars{i};
        end
    end

    % 验证缺失变量数量
    if numel(missing_vars) ~= 1
        error('必须且只能缺失一个变量。当前缺失: %s', strjoin(missing_vars, ', '));
    end

    % 处理T_in缺失的情况（需要迭代）
    if strcmp(missing_vars{1}, 'T_in')
        T_guess = 300;  % 初始温度猜测值[K]
        maxIter = 100;  % 最大迭代次数
        tol = 1e-6;     % 收敛容差
        w = 0.5;        % 松弛因子
        
        % 记录初始猜测值
        processData.T_history(1) = T_guess;
        processData.mu_history(1) = calcMu(T_guess);
        
        for iter = 1:maxIter
            % 用当前温度计算粘度
            mu_guess = calcMu(T_guess);
            
            % 根据输入类型选择计算公式
            if ~isnan(Ma_input)
                T_calc = (Ma_input^2 * L^2 * p_inf^2 * kappa) / ...
                         (Re^2 * mu_guess^2 * R_s);
            else
                T_calc = (U_in_input * L * p_inf) / ...
                         (Re * mu_guess * R_s);
            end
            
            % 应用松弛因子更新温度
            T_new = w * T_calc + (1 - w) * T_guess;
            
            % 记录当前迭代结果
            processData.T_history(end+1) = T_new;
            processData.mu_history(end+1) = calcMu(T_new);
            
            % 检查收敛（使用相对变化量）
            rel_change = abs(T_new - T_guess) / T_guess;
            if rel_change < tol
                processData.iterations = iter;
                break;
            end
            
            % 准备下一次迭代
            T_guess = T_new;
            
            % 防止超过最大迭代次数
            if iter == maxIter
                processData.iterations = iter;
                warning('达到最大迭代次数(%d)，未收敛。最后相对变化: %e', maxIter, rel_change);
            end
        end
        T_in = T_new;
        mu = calcMu(T_in);
        output.T_in = T_in;  % 存储计算结果
    else
        % T_in已知时直接计算粘度
        mu = calcMu(T_in);
        
        % 记录计算值
        processData.T_history = T_in;
        processData.mu_history = mu;
    end

    % 计算统一的速度参数
    if ~isnan(Ma_input)
        c = sqrt(kappa * R_s * T_in);
        U_in_value = Ma_input * c;
    else
        U_in_value = U_in_input;
    end

    % 计算其他缺失变量
    switch missing_vars{1}
        case 'Re'
            rho = p_inf / (R_s * T_in);
            output.Re = (rho * U_in_value * L) / mu;
            
        case 'p_inf'
            output.p_inf = (Re * mu * R_s * T_in) / (U_in_value * L);
            
        case 'L'
            rho = p_inf / (R_s * T_in);
            output.L = (Re * mu) / (rho * U_in_value);
    end

    % 把算出来的缺失值赋值回原变量
    if isfield(output, 'Re')
        Re = output.Re;
    end
    if isfield(output, 'p_inf')
        p_inf = output.p_inf;
    end
    if isfield(output, 'L')
        L = output.L;
    end
    if isfield(output, 'T_in')
        T_in = output.T_in;
    end

    % 后处理：计算并存储U_in和Ma
    output.U_in = U_in_value;
    output.Ma = U_in_value / sqrt(kappa * R_s * T_in);
    output.mu = mu;
    output.density = p_inf / (R_s * T_in);
    
    % 保存过程数据到输出结构
    output.process = processData;
end