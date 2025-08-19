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
        self.r0=2.86                                   # 龙头长度
        self.r1=1.65                                   # 龙身长度
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
        # self.solvedh()
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
    

