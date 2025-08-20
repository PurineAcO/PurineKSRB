import numpy as np
import math 
from scipy.optimize import brentq

class solver:
    """get 2 arguments, first p second t """
    def __init__(self,p,t_global):
        self.p=p                                      # 螺距
        self.kp=p/(2*math.pi)                         # 等效螺距
        self.max_theta=1000*math.pi
        self.t=t_global                               # 输入时间
        self.totallength=self.length(32*math.pi,0)    # 总长度
        self.r0=2.86                                  # 龙头长度
        self.r1=1.65                                  # 龙身长度
        self.extend_length=0.275                      # 前延长区间长度
        self.vertical_distance=0.15                   # 板凳宽度
        self.ifcrash=False                            # 碰撞标记
        self.crashplace='NULL'                        # 碰撞位置
        self.ccha=[]                                  # 碰撞残差记录
        self.thetatable=[]
        self.x=[]
        self.y=[]

    def length(self,up,down):
        lup=(self.kp/2)*(up*math.sqrt(up**2+1)+math.log(up+math.sqrt(up**2+1)))
        ldown=(self.kp/2)*(down*math.sqrt(down**2+1)+math.log(down+math.sqrt(down**2+1)))
        return lup-ldown
    
    def getxy(self,theta):
        x=self.kp*theta*math.cos(theta)
        y=self.kp*theta*math.sin(theta)
        return x,y
    
    def getrt(self,theta):
        r=self.kp*theta
        t=theta
        return r,t
    
    def dragonhead(self,theta0):
        ls1=self.totallength-self.t
        rs1=self.length(theta0,0)
        return ls1-rs1
    
    def solvedh(self):
        theta_0=brentq(self.dragonhead,a=0,
               b=self.max_theta, xtol=1e-8)
        self.thetatable.append(theta_0)
        x,y=self.getxy(theta_0)
        self.x.append(x)
        self.y.append(y)
    
    def solvedg(self):
        """need solvedh before, otherwise solvedg dont have `self.thetatable[0]` """
        for i in range(1,224):
            def dragonbody(theta_next):
                ls2=(self.getrt(self.thetatable[i-1])[0])**2+(self.getrt(theta_next)[0])**2-2*(self.getrt(self.thetatable[i-1])[0])*(self.getrt(theta_next)[0])*math.cos(self.thetatable[i-1]-theta_next)
                rs2=self.r1**2 if i!=1 else self.r0**2
                return ls2-rs2
            # print(dragonbody(self.thetatable[i-1]))
            # print(dragonbody(self.max_theta))
            theta_next=brentq(dragonbody,a=self.thetatable[i-1],b=self.max_theta,xtol=1e-8)
            self.thetatable.append(theta_next)
            x,y=self.getxy(theta_next)
            self.x.append(x)
            self.y.append(y)
    
    def solvecrash(self,ccha=1e-4):
        """input ccha, default 1e-4"""
        for i in range(0,25):
            if (self.thetatable[0]+(7*math.pi)/4 < self.thetatable[i] < self.thetatable[0]+2*math.pi or i==0 
                or self.thetatable[1]+(7*math.pi)/4 < self.thetatable[i] < self.thetatable[1]+2*math.pi ):
                xA, yA = self.x[i], self.y[i]
                xB, yB = self.x[i+1], self.y[i+1]
                dx = xB - xA
                dy = yB - yA
                segment_length = np.sqrt(dx**2 + dy**2)
                ux = dx / segment_length  
                uy = dy / segment_length  
                xA_extend = xA - ux * self.extend_length
                yA_extend = yA - uy * self.extend_length
                xB_extend = xB + ux * self.extend_length
                yB_extend = yB + uy * self.extend_length
                
                vx1, vy1 = -uy, ux   
                vx2, vy2 = uy, -ux   
                p1 = (xA_extend + self.vertical_distance * vx1, yA_extend + self.vertical_distance * vy1)
                p2 = (xB_extend + self.vertical_distance * vx1, yB_extend + self.vertical_distance * vy1)
                p3 = (xB_extend + self.vertical_distance * vx2, yB_extend + self.vertical_distance * vy2)
                p4 = (xA_extend + self.vertical_distance * vx2, yA_extend + self.vertical_distance * vy2)
                
                x1, y1 = p1
                x2, y2 = p2
                if i == 0:
                    x01, y01 = p4[0], p4[1]
                    x02, y02 = p3[0], p3[1]
                else:
                    distance1 = ((y2 - y1) * x01 - (x2 - x1) * y01 + x2 * y1 - y2 * x1)/(np.sqrt((y2 - y1)** 2 + (x2 - x1)**2))
                    if abs(distance1)<ccha: # 前缘碰撞
                        self.ifcrash=True
                        self.crashplace='front'
                        self.ccha.append(abs(distance1))
                    distance2 = ((y2 - y1) * x02 - (x2 - x1) * y02 + x2 * y1 - y2 * x1)/(np.sqrt((y2 - y1)** 2 + (x2 - x1)**2))
                    if abs(distance2)<ccha: # 后缘碰撞
                        self.ifcrash=True  
                        self.crashplace='behind'
                        self.ccha.append(abs(distance2))
        if len(self.ccha)>0:
            return self.ifcrash,min(self.ccha),self.crashplace
        else:
            return False,0,"NULL"
