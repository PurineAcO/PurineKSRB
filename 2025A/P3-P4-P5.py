import supple
import numpy as np

sov=supple.sol(1,(17800,0,1800)) # 这是一个实例
for t1 in np.arange(0, 60, 1):#粗搜
    for t2 in np.arange(0,10,1):
        for theta in np.arange(0*np.pi/180,10*np.pi/180,1*np.pi/180):
            for v in np.arange(70,140,10):
                if sov.dt(theta, v, t1, t2) is not None:
                    print(float(theta*180/np.pi), v, t1, t2,sov.dt(theta, v, t1, t2))

for t1 in np.arange(0, 8, 0.1):#细搜
    for t2 in np.arange(0,10,0.1):
        for theta in np.arange(0*np.pi/180,1*np.pi/180,0.1*np.pi/180):
            for v in np.arange(135,140,0.1):
                if sov.dt(theta, v, t1, t2) is not None:
                    print(float(theta*180/np.pi), v, t1, t2,sov.dt(theta, v, t1, t2))