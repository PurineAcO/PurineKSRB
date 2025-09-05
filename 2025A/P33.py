import math
import numpy as np
import random

# 原代码中的常量和函数
g = 9.8
alpha = 3000 / math.sqrt(101)
beta = 300 / math.sqrt(101)

# 画网格
mesh = []
for theta in np.arange(0, 2 * math.pi, 0.1):
    mesh.append((7 * math.cos(theta), 200 + 7 * math.sin(theta), 10))
for theta in np.arange(0, 2 * math.pi, 0.1):
    for z in np.arange(0, 10, 0.1):
        mesh.append((7 * math.cos(theta), 200 + 7 * math.sin(theta), z))

# 定义原始函数
def s2e(a, b, c):
    if a == 0 or b**2 - 4*a*c < 0:
        return None
    else:
        delta = math.sqrt(b**2 - 4*a*c)
        x1 = (-b + delta) / (2*a)
        x2 = (-b - delta) / (2*a)
        return x1, x2
    
def MissilePlace(t):
    if 2000-beta*t>=0:
        return (20000 - alpha * t, 0, 2000 - beta * t)
    else:return (0,0,0)

def GRDPlace(v,th,num,t,t1,t2,t3,t4,t5,t6):
    if num == 1:
        if 0<=t<t1:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 )
        elif t1<=t<t1+t2:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t-t1)*(t-t1))
        elif t1+t2<=t:
            return (17800 - v * (t1+t2) * math.cos(th), v * (t1+t2) * math.sin(th), 1800 - 0.5 * g * t2*t2-3*(t-t1-t2))
    elif num == 2:
        if 0<=t<t3:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800)
        elif t3<=t<t3+t4:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t-t3)*(t-t3))
        elif t3+t4<=t:
            return (17800 - v * (t3+t4) * math.cos(th), v * (t3+t4) * math.sin(th), 1800 - 0.5 * g * t4*t4-3*(t-t3-t4))
    elif num == 3:
        if 0<=t<t5:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800)
        elif t5<=t<t5+t6:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t-t5)*(t-t5))
        elif t5+t6<=t:
            return (17800 - v * (t5+t6) * math.cos(th), v * (t5+t6) * math.sin(th), 1800 - 0.5 * g * t6*t6-3*(t-t5-t6))

def solvek(t,mesh,v,th,num,t1,t2,t3,t4,t5,t6):
    ifclose = False
    M1, M2, M3 = MissilePlace(t)
    G1, G2, G3 = GRDPlace(v,th,num,t,t1,t2,t3,t4,t5,t6)
    for point in mesh:
        P1, P2, P3 = point
        a = (M1 - P1)**2 + (M2 - P2)** 2 + (M3 - P3)**2
        b = (-2) * ((M1 - P1) * (G1 - P1) + (M2 - P2) * (G2 - P2) + (M3 - P3) * (G3 - P3))
        c = (G1 - P1)** 2 + (G2 - P2)**2 + (G3 - P3)** 2 - 10**2  
        sol = s2e(a, b, c)
        if sol is not None and 0 <= sol[1] <= 1:
            ifclose = True
        else: 
            return (t, False)
    return (t, ifclose)

def dt(th, v, t1, t2,t3,t4,t5,t6):
    t_start = 0
    t_end = 20
    t_step = 0.01
    cnttinf = np.zeros(4000)
    cntt=0
    for t in np.arange(t_start, t_end, t_step):
        if 20+t1+t2>=t>=t1+t2:
            if solvek(t,mesh,v,th,1,t1,t2,t3,t4,t5,t6)[1]==True: 
                cnttinf[round(t/t_step)] += 1
        if 20+t3+t4>=t>=t3+t4:
            if solvek(t,mesh,v,th,2,t1,t2,t3,t4,t5,t6)[1]==True: 
                cnttinf[round(t/t_step)] += 1
        if 20+t5+t6>=t>=t5+t6:
            if solvek(t,mesh,v,th,3,t1,t2,t3,t4,t5,t6)[1]==True: 
                cnttinf[round(t/t_step)] += 1

    for cnt in cnttinf:
        if cnt >= 1:
            cntt+=1
    return cntt

# 模拟退火算法实现
def simulate_annealing(initial_temp, cooling_rate, num_iterations):
    # 随机生成初始解
    def generate_initial_solution():
        v = random.uniform(70, 140)
        th = random.uniform(7*math.pi/8, math.pi)
        t1 = random.uniform(0, 20)
        t2 = random.uniform(0, 20 - t1)
        t3 = random.uniform(t1 + 1, 20)
        t4 = random.uniform(0, 20 - t3)
        t5 = random.uniform(t3 + 1, 20)
        t6 = random.uniform(0, 20 - t5)
        return (v, th, t1, t2, t3, t4, t5, t6)
    
    # 生成邻域解
    def generate_neighbor(solution, step_size=0.1):
        v, th, t1, t2, t3, t4, t5, t6 = solution
        
        # 对每个参数添加随机扰动
        v_new = v + random.normalvariate(0, step_size)
        th_new = th + random.normalvariate(0, step_size/10)  # 角度变化较小
        t1_new = t1 + random.normalvariate(0, step_size)
        t2_new = t2 + random.normalvariate(0, step_size)
        t3_new = t3 + random.normalvariate(0, step_size)
        t4_new = t4 + random.normalvariate(0, step_size)
        t5_new = t5 + random.normalvariate(0, step_size)
        t6_new = t6 + random.normalvariate(0, step_size)
        
        # 确保参数在约束范围内
        v_new = max(70, min(140, v_new))
        th_new = max(7*math.pi/8, min(math.pi, th_new))
        
        t1_new = max(0, min(20, t1_new))
        t2_new = max(0, min(20 - t1_new, t2_new))
        
        t3_new = max(t1_new + 1, min(20, t3_new))
        t4_new = max(0, min(20 - t3_new, t4_new))
        
        t5_new = max(t3_new + 1, min(20, t5_new))
        t6_new = max(0, min(20 - t5_new, t6_new))
        
        return (v_new, th_new, t1_new, t2_new, t3_new, t4_new, t5_new, t6_new)
    
    # 初始化
    current_solution = generate_initial_solution()
    current_value = dt(*current_solution)
    best_solution = current_solution
    best_value = current_value
    temperature = initial_temp
    
    # 迭代搜索
    for i in range(num_iterations):
        # 生成邻域解
        neighbor_solution = generate_neighbor(current_solution)
        neighbor_value = dt(*neighbor_solution)
        
        # 计算接受概率
        if neighbor_value > current_value:
            accept_prob = 1.0
        else:
            # 较差解也有一定概率被接受，有助于跳出局部最优
            accept_prob = math.exp((neighbor_value - current_value) / temperature)
        
        # 接受或拒绝新解
        if random.random() < accept_prob:
            current_solution = neighbor_solution
            current_value = neighbor_value
            
            # 更新最优解
            if current_value > best_value:
                best_solution = current_solution
                best_value = current_value
        
        # 降低温度
        temperature *= cooling_rate
        
        # 定期输出进度
        if i % 100 == 0:
            print(f"Iteration {i}: Best Value = {best_value}, Temp = {temperature:.4f}")
    
    return best_solution, best_value

# 运行优化
if __name__ == "__main__":
    # 算法参数
    initial_temperature = 100.0
    cooling_rate = 0.995
    num_iterations = 5000
    
    # 执行模拟退火
    best_params, best_dt = simulate_annealing(initial_temperature, cooling_rate, num_iterations)
    
    # 输出结果
    print("\n优化完成!")
    print(f"最佳dt值: {best_dt}")
    print("最佳参数:")
    v, th, t1, t2, t3, t4, t5, t6 = best_params
    print(f"v = {v:.4f}")
    print(f"th = {th:.4f} 弧度 ({math.degrees(th):.2f} 度)")
    print(f"t1 = {t1:.4f}, t2 = {t2:.4f}")
    print(f"t3 = {t3:.4f}, t4 = {t4:.4f}")
    print(f"t5 = {t5:.4f}, t6 = {t6:.4f}")
