import meshreading as mr
import geometry as geo
import classconfig as cc

mr.read_mesh("fangdata.txt")

geo.geometry_main("1.txt", ifrender=True)
