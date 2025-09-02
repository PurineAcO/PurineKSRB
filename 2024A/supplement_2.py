import numpy as np
import math
from scipy.optimize import brentq,fsolve

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
        self.max_theta=500*math.pi              #最大极角

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

        # self.theta=[]
        self.posi=[]
        self.v=[]

        self.solved=0                                                                      # 求解完的龙
        self.road=[]                                                                       # 走过的距离

    def getxy(self,theta=None):
        if self.road[self.solved]<=0:
            x=self.p/(2*math.pi)*theta*math.cos(theta)
            y=self.p/(2*math.pi)*theta*math.sin(theta)
            return x,y
        
        elif 0<self.road[self.solved]<=self.CR1:
            delta_x = self.A[0] - self.O1[0]
            delta_y = self.A[1] - self.O1[1]
            alpha = math.atan2(delta_y, delta_x)
            total_theta = alpha - (self.road[self.solved]/self.r1)
            return self.O1[0] + self.r1 * math.cos(total_theta),self.O1[1] + self.r1 * math.sin(total_theta)
        
        elif self.CR1<self.road[self.solved]<=self.CR1+self.CR2:
            delta_x = self.C[0] - self.O2[0]
            delta_y = self.C[1] - self.O2[1]
            alpha = math.atan2(delta_y, delta_x)
            total_theta = alpha + ((self.road[self.solved]-self.CR1)/self.r2)
            return self.O2[0] + self.r2 * math.cos(total_theta),self.O2[1] + self.r2 * math.sin(total_theta)
        
        elif self.road[self.solved]>self.CR1+self.CR2:
            x=-self.p/(2*math.pi)*theta*math.cos(theta)
            y=-self.p/(2*math.pi)*theta*math.sin(theta)
            return x,y
        
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
        self.road.append(self.t)

        if self.t<=0 or self.t>self.CR1+self.CR2:
            theta_0=brentq(self.dragonhead,a=0,
                b=self.max_theta, xtol=1e-8)
            # self.theta.append(theta_0)
            self.posi.append(self.getxy(theta_0))
        elif 0<self.t<=self.CR1+self.CR2:
            self.posi.append(self.getxy())
        
        self.solved+=1


    def solved1(self):
        """need solvedh before, otherwise solvedg dont have `self.thetatable[0]` """
        if self.road[self.solved-1]>=self.CR1+self.CR2+2.908677539354322 or self.road[self.solved-1]<=0:
            x_i,y_i=self.posi[self.solved-1]
            theta_i=2*math.pi*math.sqrt(x_i**2+y_i**2)/self.p
            def f1(theta):
                ls=theta_i**2+theta**2-2*theta_i*theta*math.cos(theta-theta_i)
                rs=(self.lenh*2*math.pi/self.p)**2
                return ls-rs
            
            if self.road[self.solved-1]>=self.CR1+self.CR2+2.908677539354322:
                theta=brentq(f1,a=-self.max_theta,b=theta_i,xtol=1e-8)
                self.road.append(self.CR1+self.CR2+self.length1(theta,2*math.pi*self.r0/self.p))
            else:
                theta=brentq(f1,a=theta_i,b=self.max_theta,xtol=1e-8)
                self.road.append(-self.length1(theta,2*math.pi*self.r0/self.p))
            self.posi.append(self.getxy(theta))

        elif self.CR1+3.782164337609935<=self.road[self.solved-1]<self.CR1+self.CR2+2.908677539354322:

            x1, y1 = self.posi[self.solved - 1]  
            xB, yB = self.O2                     
            r2_sq = self.r2 ** 2                 
            r1_sq = self.lenh ** 2               
            
            A = 2 * (x1 - xB)          
            B = 2 * (y1 - yB)          
            C = (xB**2 + yB**2 - r2_sq) - (x1**2 + y1**2 - r1_sq)  
            intersections = []
            a = A**2 + B**2
            b = 2 * (A * C + A * B * y1 - B**2 * x1)
            c = C**2 + 2 * B * C * y1 + B**2 * (x1**2 + y1**2 - r1_sq)
            delta=math.sqrt(b**2 - 4 * a * c)

            x2_1 = (-b - delta) / (2 * a)
            x2_2 = (-b + delta) / (2 * a)
            y2_1 = (-A * x2_1 - C) / B
            y2_2 = (-A * x2_2 - C) / B
            intersections.append((x2_1, y2_1))
            intersections.append((x2_2, y2_2))
           
            k1 = (self.B[1] - self.A[1]) / (self.B[0] - self.A[0]) if abs(self.B[0] - self.A[0]) > 1e-9 else 0
            b1 = self.A[1] - k1 * self.A[0]
            for point in intersections:
                xer, yer = point
                if k1 * xer + b1 > yer:
                    self.posi.append((xer, yer))
                    break
            dtheta=math.acos(((xer-xB)*(self.C[0]-xB)+(yer-yB)*(self.C[1]-yB))/(self.r2**2))
            # print(dtheta*180/math.pi)
            self.road.append(self.CR1+self.r2*dtheta)

        elif 2.980663764159109<=self.road[self.solved-1]<self.CR1+3.782164337609935:

            x1, y1 = self.posi[self.solved - 1]  
            xB, yB = self.O1                     
            r2_sq = self.r1** 2                 
            r1_sq = self.lenh ** 2               
            
            A = 2 * (x1 - xB)          
            B = 2 * (y1 - yB)          
            C = (xB**2 + yB**2 - r2_sq) - (x1**2 + y1**2 - r1_sq)  
            intersections = []
            a = A**2 + B**2
            b = 2 * (A * C + A * B * y1 - B**2 * x1)
            c = C**2 + 2 * B * C * y1 + B**2 * (x1**2 + y1**2 - r1_sq)
            delta=math.sqrt(b**2 - 4 * a * c)

            x2_1 = (-b - delta) / (2 * a)
            x2_2 = (-b + delta) / (2 * a)
            y2_1 = (-A * x2_1 - C) / B
            y2_2 = (-A * x2_2 - C) / B
            intersections.append((x2_1, y2_1))
            intersections.append((x2_2, y2_2))
           
            k1 = (self.B[1] - self.A[1]) / (self.B[0] - self.A[0]) if abs(self.B[0] - self.A[0]) > 1e-9 else 0
            b1 = self.A[1] - k1 * self.A[0]
            for point in intersections:
                xer, yer = point
                if k1 * xer + b1 < yer:
                    self.posi.append((xer, yer))
                    break
            dtheta=math.acos(((xer-xB)*(self.A[0]-xB)+(yer-yB)*(self.A[1]-yB))/(self.r1**2))
            # print(dtheta*180/math.pi)
            self.road.append(self.r1*dtheta)
        
        elif 0< self.road[self.solved-1] < 2.980663764159109:
            x_i,y_i=self.posi[self.solved-1]
            l_i=math.sqrt(x_i**2+y_i**2)
            theta_i=math.atan2(y_i,x_i)
            k=self.p/(2*math.pi)
            def f2(theta):
                x_s=k*theta*math.cos(theta)
                y_s=k*theta*math.sin(theta)
                k*theta*math.cos(theta)
                # l_s=math.sqrt(x_s**2+y_s**2)
                # ls=l_i**2+l_s**2-2*l_s*l_i*math.cos(theta-theta_i)
                ls=(x_i-x_s)**2+(y_i-y_s)**2
                rs=self.lenh**2
                return ls-rs

            theta=brentq(f2,a=(2*math.pi*self.r0/self.p),b=self.max_theta,xtol=1e-8)
            self.road.append(-self.length1(theta,2*math.pi*self.r0/self.p))
            self.posi.append(self.getxy(theta))
                
                   
        self.solved += 1