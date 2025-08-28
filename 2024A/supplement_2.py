import numpy as np
import math

class dragon():
    def __init__(self,v0=1):
        self.total_num=223                      #总节点数
        self.wide=0.3                           #板凳宽度
        self.lenh=2.86                          #头部长度   
        self.lenb=1.65                          #身体长度
        self.p=1.7                              #螺距
        self.r0=0.45                            #掉头区域半径
        self.v0=v0                              #初始速度

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

        self.theta=[]
        self.posi=[]
        self.v=[]

    def solveh():
        ...


