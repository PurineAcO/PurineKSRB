import math
import numpy as np

class sol:
    """输入导弹编号和飞机坐标"""
    def __init(self,num,GRD):
        self.num = num
        self.GG1,self.GG2,self.GG3=GRD

    def s2e(self,a, b, c):
        if a == 0 or b**2 - 4*a*c < 0:
            return None
        else:
            delta = math.sqrt(b**2 - 4*a*c)
            x1 = (-b + delta) / (2*a)
            x2 = (-b - delta) / (2*a)
            return x1, x2

    def dt(self,th, v, t1, t2):
        # 常数
        g = 9.8
        alpha = 3000 / math.sqrt(101)
        beta = 300 / math.sqrt(101)

        alpha2=300*(190/math.sqrt(190**2+6**2+21**2))
        beta2= 300*(21/math.sqrt(190**2+6**2+21**2))
        gamma2= 300*(6/math.sqrt(190**2+6**2+21**2))

        alpha3=300*(180/math.sqrt(180**2+6**2+19**2))
        beta3=300*(19/math.sqrt(180**2+6**2+19**2))
        gamma3=-300*(6/math.sqrt(180**2+6**2+19**2))

        if self.num==1:M = (20000 - (t1 + t2) * alpha, 0, 2000 - (t1 + t2) * beta)
        elif self.num==2: M = (19000 - (t1 + t2) * alpha2, 600-(t1+t2)*gamma2, 2100 - (t1 + t2) * beta2)
        else: M = (18000 - (t1 + t2) * alpha3, -600-(t1+t2)*gamma3, 1900 - (t1 + t2) * beta3)
        
        GRD = (self.GG1 - v * (t1 + t2) * math.cos(th), 
            self.GG2 + v * (t1 + t2) * math.sin(th), 
            self.GG3- 0.5 * g * t2 * t2)

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
            if self.num==1:M1, M2, M3 = (M[0] - alpha* t, M[1], M[2] - beta* t)#1
            elif self.num==2: M1, M2, M3 = (M[0] - alpha2* t, M[1]-gamma2*t, M[2] - beta2* t)#2
            elif self.num==3: M1, M2, M3 = (M[0] - alpha3* t, M[1]-gamma3*t, M[2] - beta3* t)#3
            G1, G2, G3 = (GRD[0], GRD[1], GRD[2] - 3 * t)
            for point in mesh:
                P1, P2, P3 = point
                a = (M1 - P1)**2 + (M2 - P2)** 2 + (M3 - P3)**2
                b = (-2) * ((M1 - P1) * (G1 - P1) + (M2 - P2) * (G2 - P2) + (M3 - P3) * (G3 - P3))
                c = (G1 - P1)** 2 + (G2 - P2)**2 + (G3 - P3)** 2 - 10**2  
                sol = self.s2e(a, b, c)
                if sol is not None and 0 <= sol[1] <= 1:
                    ifclose = True
                else: 
                    return (t, False)
            return (t, ifclose)

        # 时间遍历
        cntt = 0
        t_start = 0
        t_end = 20
        t_step = 0.01
        cnttable=[]
        for t in np.arange(t_start, t_end, t_step):
            
            if solvek(t)[1]:
                cntt += 1
                cnttable.append(t)
        
        if cnttable :return (cntt - 1) * t_step,float(cnttable[0]),float(cnttable[-1])
        else:return None

    def run(self):
        for t1 in np.arange(11, 13, 0.1):
            for t2 in np.arange(12,14,0.1):
                # for theta in np.arange(-135*np.pi/180,-45*np.pi/180,1*np.pi/180):
                #for theta in np.arange(-45*np.pi/180,-135*np.pi/180,-2*np.pi/180):
                    #for v in np.arange(85, 95, 1):
                    for v in np.arange(95,105,1):
                        #print(theta,v,t1,t2)
                        # v=90

                        theta=-53.0*np.pi/180
                        if self.dt(theta, v, t1, t2) is not None:
                            print(float(theta*180/np.pi), v, t1, t2,self.dt(theta, v, t1, t2))
