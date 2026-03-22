import numpy as np

class solver:
    def __init__(self,dt,x0,v0,m,kp,ki,kd,ummax,xc):
        """initialize the solver,you should define the `dt`,`x0`,`v0`,`m`\n
        also you should define the PID parameters `kp`,`ki`,`kd`,`ummax` and\n
        `xc` which means the target distance between two magnets"""

        self.dt=dt
        self.x0=x0
        self.v0=v0
        self.t=0
        self.m=m
        self.x=self.x0
        self.v=self.v0
        self.solvercnt=0
        self.resultable=[]
        self.kp=kp
        self.ki=ki
        self.kd=kd
        self.xc=xc
        self.ummax=ummax
        self.eold=0
        self.eint=0
        self.xm=0
        self.um=0

    def defF(self,deltax):
        """define the magi force,use the `deltax`,and will return the `F`"""

        if deltax>=0.062 and deltax<=0.3:
            F=-8012848.8557 * (deltax*1000)**(-3.0107)
        elif deltax<0.062:
            F=-32
        elif deltax>0.3:
            F=-0.27915
        else:
            F=0
        
        if 0<self.x<self.x0:return -F
        else:return F

    def newton(self,F):
        """use newton equation to solve the problem,please don't use this function directly,or give `F`"""

        self.solvercnt+=1
        self.a=F/self.m
        self.t=self.dt+self.t
        self.v=self.v+self.a*self.dt
        self.x=self.x+self.v*self.dt
        # print("time:",self.t,"x:",self.x,"v:",self.v)
    
    def PID(self,kp,ki,kd,ummax):
        """use the PID controller to control the `self.xm`"""

        self.e=self.xc-self.x-self.xm
        
        self.um=kp*self.e+ki*self.eint+kd*(self.e-self.eold)/self.dt
        if abs(self.um)>ummax:self.um=np.sign(self.um)*ummax
        self.um=max(0,self.um)

        self.xm=max(self.xm+self.um*self.dt,0)

        self.eint+=self.e   
        self.eold=self.e

    def process(self,ifx=True,ifnan=True,xlim=0,nanlim=1e4,printtime=2,maxcnt=100):
        """use the `self.newton` to process the solution,you should define\n
        whether the program should stop when the `self.x` is out of the range\n
        use `ifnan` to define whether the program should stop when the `self.x` is over `nanlim`\n
        use  `ifx` to define whether the program should stop when the `self.x` is lower than `xlim`\n
        use `printtime` to define the time interval to print the solution(*has been disabled*)\n
        use `maxcnt` to define the maximum count of the solver"""

        if ifx and self.x<xlim:
            print(self.resultable)
            return 
        if ifnan and self.x>nanlim:
            print(self.resultable)
            return
        if self.solvercnt>maxcnt:
            print(self.resultable)
            return
        self.newton(self.defF(self.x+self.xm))
        self.PID(self.kp,self.ki,self.kd,self.ummax)
        self.result()
        # if self.solvercnt%printtime==0:print("time:",self.t,"x:",self.x,"v:",self.v)
        self.process(ifx,ifnan,xlim,nanlim,printtime)

    def result(self):
        """record the `t`,`x`,`v`,`a` to the `self.resultable`"""
        self.resultable.append([self.t,self.a,self.v,self.x,self.um,self.xm])