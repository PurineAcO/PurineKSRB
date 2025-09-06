import math
import numpy as np

# 定义原始函数
def s2e(a, b, c):
    if a == 0 or b**2 - 4*a*c < 0:
        return None
    else:
        delta = math.sqrt(b**2 - 4*a*c)
        x1 = (-b + delta) / (2*a)
        x2 = (-b - delta) / (2*a)
        return x1, x2

def dt(th, v, t1, t2):
    # 常数
    g = 9.8
    alpha = 3000 / math.sqrt(101)
    beta = 300 / math.sqrt(101)
    M = (20000 - (t1 + t2) * alpha, 0, 2000 - (t1 + t2) * beta)
    GRD = (17800 - v * (t1 + t2) * math.cos(th), 
           v * (t1 + t2) * math.sin(th), 
           1800 - 0.5 * g * t2 * t2)

    # 画网格
    mesh = []
    for theta in np.arange(0, 2 * math.pi, 0.2*math.pi):
        for r in np.arange(0, 7, 0.5):
            mesh.append((r * math.cos(theta), 200 + r * math.sin(theta), 10))
    for theta in np.arange(0, 2 * math.pi, 0.2*math.pi):
        for z in np.arange(0, 10, 0.5):
            mesh.append((7 * math.cos(theta), 200 + 7 * math.sin(theta), z))

    # 检测函数
    def solvek(t):
        ifclose = False
        M1, M2, M3 = (M[0] - alpha * t, M[1], M[2] - beta * t)
        G1, G2, G3 = (GRD[0], GRD[1], GRD[2] - 3 * t)
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

    # 时间遍历
    cntt = 0
    t_start = 0
    t_end = 10
    t_step = 0.01
    cnttable=[]
    for t in np.arange(t_start, t_end, t_step):
        
        if solvek(t)[1]:
            cntt += 1
            cnttable.append(t)
    
    if cnttable :return (cntt - 1) * t_step,float(cnttable[0]),float(cnttable[-1])
    else:return None

for t1 in np.arange(0, 5, 1):
    for t2 in np.arange(0, 5, 1):
        for theta in np.arange(0,10*np.pi/180, np.pi/180):
            for v in np.arange(70, 140, 10):
                if dt(theta, v, t1, t2) is not None:
                    print(dt(theta, v, t1, t2))