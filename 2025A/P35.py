import math
import numpy as np

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
    else:
        return (0,0,0)

def GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6):
    if num == 1:
        if 0 <= t < t1:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 )
        elif t1 <= t < t1 + t2:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t-t1)*(t-t1))
        elif t1 + t2 <= t:
            return (17800 - v * (t1 + t2) * math.cos(th), v * (t1 + t2) * math.sin(th), 
                   1800 - 0.5 * g * t2*t2 - 3*(t - t1 - t2))
    elif num == 2:
        if 0 <= t < t3:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800)
        elif t3 <= t < t3 + t4:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t-t3)*(t-t3))
        elif t3 + t4 <= t:
            return (17800 - v * (t3 + t4) * math.cos(th), v * (t3 + t4) * math.sin(th), 
                   1800 - 0.5 * g * t4*t4 - 3*(t - t3 - t4))
    elif num == 3:
        if 0 <= t < t5:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800)
        elif t5 <= t < t5 + t6:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t-t5)*(t-t5))
        elif t5 + t6 <= t:
            return (17800 - v * (t5 + t6) * math.cos(th), v * (t5 + t6) * math.sin(th), 
                   1800 - 0.5 * g * t6*t6 - 3*(t - t5 - t6))

def solvek(t, mesh, v, th, num, t1, t2, t3, t4, t5, t6):
    M1, M2, M3 = MissilePlace(t)
    G1, G2, G3 = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6)
    for point in mesh:
        P1, P2, P3 = point
        a = (M1 - P1)**2 + (M2 - P2)** 2 + (M3 - P3)**2
        b = (-2) * ((M1 - P1) * (G1 - P1) + (M2 - P2) * (G2 - P2) + (M3 - P3) * (G3 - P3))
        c = (G1 - P1)** 2 + (G2 - P2)**2 + (G3 - P3)** 2 - 10**2  
        sol = s2e(a, b, c)
        if sol is not None and 0 <= sol[1] <= 1:
            return True
    return False

def dt(th, v, t1, t2, t3, t4, t5, t6):
    t_start = 0
    t_end = 20
    t_step = 0.01
    cnttinf = np.zeros(int((t_end - t_start) / t_step) + 1)
    cntt = 0
    
    for t in np.arange(t_start, t_end, t_step):
        idx = round((t - t_start) / t_step)
        if 20 + t1 + t2 >= t >= t1 + t2:
            if solvek(t, mesh, v, th, 1, t1, t2, t3, t4, t5, t6):
                cnttinf[idx] += 1
                print(t)
        if 20 + t3 + t4 >= t >= t3 + t4:
            if solvek(t, mesh, v, th, 2, t1, t2, t3, t4, t5, t6):
                cnttinf[idx] += 1
                print(t)
        if 20 + t5 + t6 >= t >= t5 + t6:
            if solvek(t, mesh, v, th, 3, t1, t2, t3, t4, t5, t6):
                cnttinf[idx] += 1
                print(t)

    for cnt in cnttinf:
        if cnt >= 1:
            cntt += 1
    return cntt

print(dt(8.273*np.pi/180,108.22,0.001,0.140,1.004,0.005,9.900,0.027))