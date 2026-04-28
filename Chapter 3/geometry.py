import numpy as np
import classconfig as cc

def calc_cell_vol():
    """calculate the cell volume and push it into the **class list** `CellList`.\n
    if the mesh is circle, it will be **open**,
    and if the mesh isn't cicle, it will be closed.\n
    *it seemed that we should change the way to read the meshdata*"""
    for i in range(1,cc.i_total,1):
        circlecell = [[]]
        for j in range(1,cc.j_total,1):
            vec1 = np.array([cc.NodeList[i+1][j+1].x -cc.NodeList[i][j].x
                             ,cc.NodeList[i+1][j+1].y -cc.NodeList[i][j].y])
            vec2 = np.array([cc.NodeList[i+1][j].x -cc.NodeList[i][j+1].x
                             ,cc.NodeList[i+1][j].y -cc.NodeList[i][j+1].y])
            thisindex = (i-1)*cc.j_total+j
            tempcell = cc.cell_class(thisindex)
            tempcell.vol = 0.5 * np.abs(np.cross(vec1,vec2))
            circlecell.append(tempcell)
        cc.CellList.append(circlecell)

def calc_cell_center():
    """calculate the cell center and push it into the **class list** `CellList`.\n"""
    for i in range(1,cc.i_total,1):
        for j in range(1,cc.j_total,1):
            x1,y1= cc.NodeList[i][j].x, cc.NodeList[i][j].y
            x2,y2= cc.NodeList[i+1][j].x, cc.NodeList[i+1][j].y
            x3,y3= cc.NodeList[i+1][j+1].x, cc.NodeList[i+1][j+1].y
            x4,y4= cc.NodeList[i][j+1].x, cc.NodeList[i][j+1].y
            a = (x1+x2)*(x1*y2-x2*y1)+(x2+x3)*(x2*y3-x3*y2)+(x3+x4)*(x3*y4-x4*y3)+(x4+x1)*(x4*y1-x1*y4)
            b = (y1+y2)*(x1*x2-x2*x1)+(y2+y3)*(x2*x3-x3*x2)+(y3+y4)*(x3*x4-x4*x3)+(y4+y1)*(x4*x1-x1*x4)
            cc.CellList[i][j].x = a/(6*cc.CellList[i][j].vol)  
            cc.CellList[i][j].y = b/(6*cc.CellList[i][j].vol)  

def calc_face_direction():
    """calculate the face direction and push it into the **class list** `FaceList`.\n
    the facelist_tau's normal direction is **out**(which is n-direction)\n
    the facelist_n's normal direction is **clockwise**(which is tau-direction)"""
    for i in range(1,cc.i_total+1,1):
        circleface=[[]]
        for j in range(1,cc.j_total,1):
            tempface_tau = cc.face_class((i-1)*cc.j_total+j)    
            tempface_tau.ni = cc.NodeList[i][j].y - cc.NodeList[i][j+1].y
            tempface_tau.nj = cc.NodeList[i][j+1].x - cc.NodeList[i][j].x
            circleface.append(tempface_tau)
        cc.Facelist_tau.append(circleface)
    
    for j in range(1,cc.j_total+1,1):
        circleface=[[]]
        for i in range(1,cc.i_total,1):
            tempface_n = cc.face_class((i-1)*cc.j_total+j)    
            tempface_n.ni = cc.NodeList[i][j+1].y - cc.NodeList[i][j].y
            tempface_n.nj = cc.NodeList[i][j].x - cc.NodeList[i][j+1].x
            circleface.append(tempface_n)
        cc.FaceList_n.append(circleface)

def geometry_debug():
    with open("1.txt",'a') as f:
        for i in range(1,cc.i_total,1):
            for j in range(1,cc.j_total,1):
                cell = cc.CellList[i][j]
                f.write(f"cell index: {cell.index}, cell volume: {cell.vol}\n")
                f.write(f"cell center: ({cell.x}, {cell.y})\n")
                f.write("-------------------------------------\n")

            
