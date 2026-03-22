class solver:
    def __init__(self,dt,x0,v0,m):
        """initialize the solver,you should define the `dt`,`x0`,`v0`,`m`"""

        self.dt = dt
        self.x0 = x0
        self.v0 = v0
        self.t=0
        self.m = m
        self.x=self.x0
        self.v=self.v0
        self.solvercnt=0
        self.resultable=[]

    def defF(self):
        """define the magi force,use the inside `self.x`,and will return the `F`"""

        if self.x>=0.062 and self.x<=0.3:
            return -8012848.8557 * (self.x*1000)**(-3.0107)
        elif self.x<0.062:
            return -32
        elif self.x>0.3:
            return -0.27915
        else:
            return 0

    def newton(self,F):
        """use newton equation to solve the problem,please don't use this function directly,or give `F`"""

        self.solvercnt+=1
        self.a=F/self.m
        self.t=self.dt+self.t
        self.v=self.v+self.a*self.dt
        self.x=self.x+self.v*self.dt
        # print("time:",self.t,"x:",self.x,"v:",self.v)

    def process(self,ifx=True,ifnan=True,xlim=0,nanlim=1e4,printtime=2):
        """use the `self.newton` to process the solution,you should define\n
        whether the program should stop when the `self.x` is out of the range\n
        use `ifnan` to define whether the program should stop when the `self.x` is over `nanlim`\n
        use  `ifx` to define whether the program should stop when the `self.x` is lower than `xlim`\n
        use `printtime` to define the time interval to print the solution"""

        if ifx and self.x<xlim:
            print(self.resultable)
            return 
        if ifnan and self.x>nanlim:
            print(self.resultable)
            return
        self.newton(self.defF())
        self.result()
        # if self.solvercnt%printtime==0:print("time:",self.t,"x:",self.x,"v:",self.v)
        self.process(ifx,ifnan,xlim,nanlim,printtime)

    def result(self):
        """record the `t`,`x`,`v`,`a` to the `self.resultable`"""
        self.resultable.append([self.t,self.a,self.v,self.x])