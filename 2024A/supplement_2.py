import numpy as np
import math
from scipy.optimize import brentq

class dragon():
    def __init__(self,t,v0=1):
        self.total_num=223                      #总节点数
        self.wide=0.3                           #板凳宽度
        self.lenh=2.86                          #头部长度   
        self.lenb=1.65                          #身体长度
        self.p=1.7                              #螺距
        self.r0=4.5                             #掉头区域半径
        self.v0=v0                              #初始速度
        self.t=t                                #总时间
        self.max_theta=100*math.pi              #最大极角

        self.cplace=2*math.pi*self.r0/self.p    #掉头区域极角
        self.calpha=math.atan(self.cplace)      #双弧角度

        self.r1=3/math.sin(self.calpha)         #大弧半径
        self.r2=self.r1/2                       #小弧半径

        self.O1=(self.r0*math.cos(self.cplace)-self.r1*math.sin(self.cplace+self.calpha),
                 self.r0*math.sin(self.cplace)+self.r1*math.cos(self.cplace+self.calpha))   #大弧圆心
        self.O2=(-self.r0*math.cos(self.cplace)+self.r2*math.sin(self.cplace+self.calpha),
                 -self.r0*math.sin(self.cplace)-self.r2*math.cos(self.cplace+self.calpha))  #小弧圆心
        self.A=((self.p/(2*math.pi))*self.cplace*math.cos(self.cplace),
                (self.p/(2*math.pi))*self.cplace*math.sin(self.cplace))                     #大弧起点       
        self.B=(-self.A[0],-self.A[1])                                                      #小弧终点
        self.C=(self.A[0]/3+self.B[0]*2/3,self.A[1]/3+self.B[1]*2/3)                        #大弧终点
        self.phi=2*math.asin(math.sqrt((self.A[0]-self.C[0])**2
                                       +(self.A[1]-self.C[1])**2)/(2*self.r1))              # 圆心角
        self.CR1=self.r1*self.phi                                                           #大弧弧长
        self.CR2=self.r2*self.phi                                                           #小弧弧长

        self.theta=[]
        self.posi=[]
        self.v=[]

    def getxy(self,theta=None):
        if self.t<=0 or self.t>self.CR1+self.CR2:
            x=self.p/(2*math.pi)*theta*math.cos(theta)
            y=self.p/(2*math.pi)*theta*math.sin(theta)
            return x,y
        
        elif 0<self.t<=self.CR1:
            delta_x = self.A[0] - self.O1[0]
            delta_y = self.A[1] - self.O1[1]
            alpha = math.atan2(delta_y, delta_x)
            total_theta = alpha - (self.t/self.r1)
            return self.O1[0] + self.r1 * math.cos(total_theta),self.O1[1] + self.r1 * math.sin(total_theta)
        
        elif self.CR1<self.t<=self.CR1+self.CR2:
            delta_x = self.C[0] - self.O2[0]
            delta_y = self.C[1] - self.O2[1]
            alpha = math.atan2(delta_y, delta_x)
            total_theta = alpha + ((self.t-self.CR1)/self.r2)
            return self.O2[0] + self.r2 * math.cos(total_theta),self.O2[1] + self.r2 * math.sin(total_theta)
        
    def length1(self,up,down):
        lup=(self.p/(4*math.pi))*(up*math.sqrt(up**2+1)+math.log(up+math.sqrt(up**2+1)))
        ldown=(self.p/(4*math.pi))*(down*math.sqrt(down**2+1)+math.log(down+math.sqrt(down**2+1)))
        return lup-ldown
    
    def dragonhead(self,theta0):
        if self.t<=0:
            ls1=self.length1(self.cplace,0)-self.t
            rs1=self.length1(theta0,0)
        
        elif self.t>=self.CR1+self.CR2:
            ls1=self.length1(self.cplace,0)+self.t-self.CR1-self.CR2
            rs1=self.length1(theta0,0)

        return ls1-rs1
    
    def solvedh(self):
        if self.t<=0 or self.t>self.CR1+self.CR2:
            theta_0=brentq(self.dragonhead,a=0,
                b=self.max_theta, xtol=1e-8)
            # self.theta.append(theta_0)
            if self.t<0:
                self.posi.append(self.getxy(theta_0))
            else:
                self.posi.append((-self.getxy(theta_0)[0],-self.getxy(theta_0)[1]))
        elif 0<self.t<=self.CR1+self.CR2:
            self.posi.append(self.getxy())
        

