import numpy as np

# area for the global variables 
i_total = 0
j_total = 0
meshcnt = 0
NodeList = [[]]
CellList = [[]]
FaceList_n = [[]]
Facelist_tau = [[]]

#area for the class definition
class node_class:
    def __init__(self,index):
        self.index = index
        self.x = 0       # node x
        self.y = 0       # node y

class cell_class:
    def __init__(self,index):
        self.index = index
        self.x = 0        # cell center x
        self.y = 0        # cell center y   
        self.vol = 0      # cell volume(for 2D,it iterally means area)

class face_class:
    def __init__(self,index):
        self.index = index
        self.ni = 0        # normal direction n
        self.nj = 0        # normal direction tau   