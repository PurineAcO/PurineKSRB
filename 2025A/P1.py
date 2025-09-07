import math
import numpy as np
import supple

sol=supple.sol(1,(17800,0,1800))

if sol.dt(0,120,1.5,3.6) is not None:
    print(sol.dt(0,120,1.5,3.6))[0]
else:
    print("无解")
