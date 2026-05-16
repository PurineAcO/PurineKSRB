import classconfig as cc
import math

def initialization(T0=cc.T0,AOA=cc.AOA,Ma=cc.Ma,P0=cc.P0):
    """init the whole fluid field,you should give the Ma"""
    for i in range(1,cc.i_total,1):
        for j in range(1,cc.j_total,1):
            cc.CellList[i][j].ma = Ma
            cc.CellList[i][j].T = T0/(1 + (cc.gamma-1)/2 * (Ma**2))
            cc.CellList[i][j].p = P0 * (cc.CellList[i][j].T-T0)**(cc.gamma/(cc.gamma-1))
            cc.CellList[i][j].c = math.sqrt(cc.gamma*cc.R*cc.CellList[i][j].T)
            cc.CellList[i][j].rho = cc.CellList[i][j].p/(cc.R*cc.CellList[i][j].T)
            cc.CellList[i][j].u = cc.CellList[i][j].c * Ma * math.cos(AOA*180/math.pi)
            cc.CellList[i][j].v = cc.CellList[i][j].c * Ma * math.sin(AOA*180/math.pi)
            cc.CellList[i][j].E = cc.CellList[i][j].p/(cc.CellList[i][j].rho*(cc.gamma-1))+(cc.CellList[i][j].u**2+cc.CellList[i][j].v**2)/2
            cc.CellList[i][j].H = cc.CellList[i][j].E + cc.CellList[i][j].p/cc.CellList[i][j].rho
            cc.CellList[i][j].miu = cc.mu0 * (cc.CellList[i][j].T/T0)**1.5 * (T0+cc.Ts)/(cc.CellList[i][j].T+cc.Ts)
            cc.CellList[i][j].miubl = cc.CellList[i][j].miu *0.1/cc.CellList[i][j].rho