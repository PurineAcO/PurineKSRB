import math
import numpy as np

g = 9.8
alpha = 3000 / math.sqrt(101)
beta = 300 / math.sqrt(101)

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

def lengther(v,th,num,t,t1,t2,t3,t4,t5,t6):

    M=MissilePlace(t)
    G=GRDPlace(v,th,num,t,t1,t2,t3,t4,t5,t6)
    P=(0,200,0)

    vector_PM = np.array([M[0] - P[0], M[1] - P[1], M[2] - P[2]])
    vector_PG = np.array([G[0] - P[0], G[1] - P[1], G[2] - P[2]])
    
    cross_product = np.cross(vector_PG, vector_PM)
    distance = np.linalg.norm(cross_product) / np.linalg.norm(vector_PM)
    
    if distance >= 10:
        return t,False
    else:
        return t,True
    
def ccnt(v,th,t1,t2,t3,t4,t5,t6):
    t_start = 0
    t_end = 20
    t_step = 0.01
    cnttinf = np.zeros(4000)
    cntt=0
    for t in np.arange(t_start, t_end, t_step):
        if 20+t1+t2>=t>=t1+t2:
            if lengther(v,th,1,t,t1,t2,t3,t4,t5,t6)[1]==True: 
                cnttinf[round(t/t_step)] += 1
                # print(t,round(t/t_step)) 
        if 20+t3+t4>=t>=t3+t4:
            if lengther(v,th,2,t,t1,t2,t3,t4,t5,t6)[1]==True: 
                cnttinf[round(t/t_step)] += 1
        if 20+t5+t6>=t>=t5+t6:
            if lengther(v,th,3,t,t1,t2,t3,t4,t5,t6)[1]==True: 
                cnttinf[round(t/t_step)] += 1

    for cnt in cnttinf:
        if cnt >= 1:
            cntt+=1
    # print(cnttinf)
    return cntt

# print(ccnt(71.162,2.9829,0,0,1,0.358,3.635,2.117))