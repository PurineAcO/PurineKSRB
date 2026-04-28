import meshreading as mr
import geometry as geo
import classconfig as cc

mr.read_mesh("yuanzhudata.txt")

geo.calc_cell_vol()

geo.calc_cell_center()

geo.geometry_debug()
