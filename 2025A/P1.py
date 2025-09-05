import math
import numpy as np

# 常数
g = 9.8
alpha = 3000 / math.sqrt(101)
beta = 300 / math.sqrt(101)
M = (20000 - 5.1 * alpha, 0, 2000 - 5.1 * beta)
GRD = (17620 - 120 * 3.6, 0, 1800 - 0.5 * g * 3.6 * 3.6)
print(GRD)

# 画网格
mesh=[]
for theta in np.arange(0, 2 * math.pi, 0.1):
    for r in np.arange(0,7,0.1):
        mesh.append((r * math.cos(theta), 200 + r * math.sin(theta), 10))
for theta in np.arange(0, 2 * math.pi, 0.1):
    for z in np.arange(0, 10, 0.1):
        mesh.append((7 * math.cos(theta), 200 + 7 * math.sin(theta), z))

# 检测
def s2e(a,b,c):
    if a==0 or b**2-4*a*c<0:
        return None
    else:
        delta=math.sqrt(b**2-4*a*c)
        x1=(-b+delta)/(2*a)
        x2=(-b-delta)/(2*a)
        return x1,x2
    
def solvek(t):
    ifclose=False
    M1,M2,M3=(M[0]-alpha*t,0,M[2]-beta*t)
    G1,G2,G3=(GRD[0],0,GRD[2]-3*t)
    for point in mesh:
        P1,P2,P3=point
        a = (M1-P1)**2 + (M2-P2)** 2 + (M3-P3)**2
        b = -2 * ((M1-P1)*(G1-P1) + (M2-P2)*(G2-P2) + (M3-P3)*(G3-P3))
        c = (G1-P1)** 2 + (G2-P2)**2 + (G3-P3)** 2 - 10**2  
        sol=s2e(a,b,c)
        if sol is not None and 0<=sol[1]<=1:
            ifclose=True
        else: 
            return (t,False)
    return (t,ifclose)

# 时间遍历
cntt=0
for t in np.arange(0, 10, 0.01):
    if solvek(t)[1]:
        cntt+=1
print((cntt-1)*0.01)

