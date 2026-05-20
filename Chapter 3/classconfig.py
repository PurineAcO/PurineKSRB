import numpy as np

# define some constants
gamma = 1.4      # gamma = Cp/Cv
R = 287.06       # gas constant,which is for air
T0 = 288.16      # referrence temperature,入口静温
Ts = 110         # Sutherland costant
mu0 = 1.7894e-5  # μ for T0,动力粘度
P0 = 101325.0    # referrence pressure,入口静压
c0 = 340.28      # referrence sound velocity,海平面参考声速

#define the simulation state
AOA = 0          # attack angle(which unit is deg)
Ma = 0.2         # Mach Number

# area for the global variables 
i_total = 0
j_total = 0
meshcnt = 0
NodeList = [[]]
CellList = [[]]
FaceList_n = [[]]
Facelist_tau = [[]]

# output file
outputfile = "output.txt"


#area for the class definition
class node_class:
    def __init__(self,index):
        self.index = index
        self.x = 0       # node x
        self.y = 0       # node y

class cell_class:
    def __init__(self,index):
        self.index = index  # cell index (i,j)
        self.x = 0          # cell center x
        self.y = 0          # cell center y   
        self.vol = 0        # cell volume(for 2D,it iterally means area)
        self.sad = 0        # cell to wall distance
        self.rho = 0
        self.p = 0
        self.T = 0
        self.u = 0
        self.v = 0
        self.E = 0
        self.H = 0
        self.c = 0
        self.ma = 0
        self.miu = 0
        self.miubl = 0
        self.U = [0,0,0,0,0,0] # conservative variables
        self.U_former = [0,0,0,0,0,0] # former conservative variables

class face_class:
    def __init__(self,index):
        self.index = index
        self.ni = 0        # normal direction n
        self.nj = 0        # normal direction tau
        self.mx = 0        # middle point x
        self.my = 0        # middle point y

# some temp variables

density_table = np.zeros((i_total+1,j_total+1))