import numpy as np
import classconfig as cc

def calc_cell_vol():
    """新建网格类,计算每个单元的体积,并存储在`CellList` 中.\n"""
    for i in range(1,cc.i_total,1):
        circlecell = [[]]
        for j in range(1,cc.j_total,1):
            vec1 = np.array([cc.NodeList[i+1][j+1].x -cc.NodeList[i][j].x
                             ,cc.NodeList[i+1][j+1].y -cc.NodeList[i][j].y])
            vec2 = np.array([cc.NodeList[i+1][j].x -cc.NodeList[i][j+1].x
                             ,cc.NodeList[i+1][j].y -cc.NodeList[i][j+1].y])
            thisindex = (i,j)
            tempcell = cc.cell_class(thisindex)
            tempcell.vol = 0.5 * np.abs(np.cross(vec1,vec2))
            circlecell.append(tempcell)

        # wrap-around cell: j = j_total
        vec1 = np.array([cc.NodeList[i+1][1].x -cc.NodeList[i][cc.j_total].x
                         ,cc.NodeList[i+1][1].y -cc.NodeList[i][cc.j_total].y])
        vec2 = np.array([cc.NodeList[i+1][cc.j_total].x -cc.NodeList[i][1].x
                         ,cc.NodeList[i+1][cc.j_total].y -cc.NodeList[i][1].y])
        thisindex = (i,cc.j_total)
        tempcell = cc.cell_class(thisindex)
        tempcell.vol = 0.5 * np.abs(np.cross(vec1,vec2))
        circlecell.append(tempcell)

        cc.CellList.append(circlecell)

def calc_cell_center():
    """计算每个单元的中心,并存储在`CellList` 中."""
    for i in range(1, cc.i_total):
        for j in range(1, cc.j_total):
            x1,y1 = cc.NodeList[i][j].x, cc.NodeList[i][j].y
            x2,y2 = cc.NodeList[i+1][j].x, cc.NodeList[i+1][j].y
            x3,y3 = cc.NodeList[i+1][j+1].x, cc.NodeList[i+1][j+1].y
            x4,y4 = cc.NodeList[i][j+1].x, cc.NodeList[i][j+1].y
            c1 = x1*y2 - x2*y1
            c2 = x2*y3 - x3*y2
            c3 = x3*y4 - x4*y3
            c4 = x4*y1 - x1*y4
            signed_area = 0.5 * (c1 + c2 + c3 + c4)
            a = (x1+x2)*c1 + (x2+x3)*c2 + (x3+x4)*c3 + (x4+x1)*c4
            b = (y1+y2)*c1 + (y2+y3)*c2 + (y3+y4)*c3 + (y4+y1)*c4
            if abs(signed_area) > 1e-30:
                cc.CellList[i][j].x = a / (6 * signed_area)
                cc.CellList[i][j].y = b / (6 * signed_area)

        # wrap-around cell: j = j_total
        j = cc.j_total
        x1,y1 = cc.NodeList[i][j].x, cc.NodeList[i][j].y
        x2,y2 = cc.NodeList[i+1][j].x, cc.NodeList[i+1][j].y
        x3,y3 = cc.NodeList[i+1][1].x, cc.NodeList[i+1][1].y
        x4,y4 = cc.NodeList[i][1].x, cc.NodeList[i][1].y
        c1 = x1*y2 - x2*y1
        c2 = x2*y3 - x3*y2
        c3 = x3*y4 - x4*y3
        c4 = x4*y1 - x1*y4
        signed_area = 0.5 * (c1 + c2 + c3 + c4)
        a = (x1+x2)*c1 + (x2+x3)*c2 + (x3+x4)*c3 + (x4+x1)*c4
        b = (y1+y2)*c1 + (y2+y3)*c2 + (y3+y4)*c3 + (y4+y1)*c4
        if abs(signed_area) > 1e-30:
            cc.CellList[i][j].x = a / (6 * signed_area)
            cc.CellList[i][j].y = b / (6 * signed_area)

def calc_face_direction_tau():
    """计算周向网格的边的法向量(外法向,单位化),存储在`Facelist_tau` 中."""
    for i in range(1, cc.i_total + 1):
        circleface = [[]]
        for j in range(1, cc.j_total):
            dx = cc.NodeList[i][j+1].x - cc.NodeList[i][j].x
            dy = cc.NodeList[i][j+1].y - cc.NodeList[i][j].y
            mag = np.sqrt(dx**2 + dy**2)
            tempface_tau = cc.face_class((i, j))
            if mag > 1e-30:
                tempface_tau.ni = dy / mag
                tempface_tau.nj = -dx / mag
                tempface_tau.mx = (cc.NodeList[i][j].x + cc.NodeList[i][j+1].x) / 2
                tempface_tau.my = (cc.NodeList[i][j].y + cc.NodeList[i][j+1].y) / 2
            circleface.append(tempface_tau)

        # wrap-around: j = j_total → j+1 = 1
        dx = cc.NodeList[i][1].x - cc.NodeList[i][cc.j_total].x
        dy = cc.NodeList[i][1].y - cc.NodeList[i][cc.j_total].y
        mag = np.sqrt(dx**2 + dy**2)
        tempface_tau = cc.face_class((i, cc.j_total))
        if mag > 1e-30:
            tempface_tau.ni = dy / mag
            tempface_tau.nj = -dx / mag
            tempface_tau.mx = (cc.NodeList[i][cc.j_total].x + cc.NodeList[i][1].x) / 2
            tempface_tau.my = (cc.NodeList[i][cc.j_total].y + cc.NodeList[i][1].y) / 2
        circleface.append(tempface_tau)

        cc.Facelist_tau.append(circleface)

def calc_face_direction_n():
    """计算径向网格的边的法向量(外法向,单位化),存储在`FaceList_n` 中."""
    for j in range(1, cc.j_total + 1):
        circleface = [[]]
        for i in range(1, cc.i_total):
            dx = cc.NodeList[i+1][j].x - cc.NodeList[i][j].x
            dy = cc.NodeList[i+1][j].y - cc.NodeList[i][j].y
            mag = np.sqrt(dx**2 + dy**2)
            tempface_n = cc.face_class((i, j))
            if mag > 1e-30:
                tempface_n.ni = -dy / mag
                tempface_n.nj = dx / mag
                tempface_n.mx = (cc.NodeList[i][j].x + cc.NodeList[i+1][j].x) / 2
                tempface_n.my = (cc.NodeList[i][j].y + cc.NodeList[i+1][j].y) / 2
            circleface.append(tempface_n)

        cc.FaceList_n.append(circleface)

def calc_most_near_walldistance():
    """计算每个单元中心到壁面的最近距离, 存储在 `cell.sad` 中.\n
    优化: 仅搜索周向 `w=max(5,j_total//20)` 范围内的壁面, 而非全局遍历.
    """
    # window: ~20% of circumference, at least 15
    window = max(15, cc.j_total // 5)
    j_total = cc.j_total
    wall_faces = cc.Facelist_tau[1]  # first ring = wall

    for i in range(1, cc.i_total):
        for j in range(1, j_total + 1):
            cell = cc.CellList[i][j]
            min_dist = float('inf')
            # search k in [j-window, j+window] with wrap-around
            for dk in range(-window, window + 1):
                k = (j - 1 + dk) % j_total + 1  # 1-indexed wrap
                face = wall_faces[k]
                dist = np.sqrt((cell.x - face.mx) ** 2 + (cell.y - face.my) ** 2)
                if dist < min_dist:
                    min_dist = dist
            cell.sad = min_dist

def geometry_debug(debugoutput):
    with open(debugoutput,'w') as f:
        for i in range(1,cc.i_total,1):
            for j in range(1,cc.j_total+1,1):
                cell = cc.CellList[i][j]
                f.write(f"cell index: ({i},{j}), cell volume: {cell.vol}\n")
                f.write(f"cell center: ({cell.x}, {cell.y})\n")
                f.write(f"most near wall distance: {cell.sad}\n")
                f.write("-------------------------------------\n")

        for i in range(1,cc.i_total+1,1):
            for j in range(1,cc.j_total+1,1):
                face_tau = cc.Facelist_tau[i][j]
                f.write(f"face_tau index: ({i},{j}), normal vector: ({face_tau.ni}, {face_tau.nj})\n")
                f.write(f"face_tau middle point: ({face_tau.mx}, {face_tau.my})\n")
                f.write("-------------------------------------\n")

        for j in range(1, cc.j_total + 1):
            for i in range(1, cc.i_total):
                face_n = cc.FaceList_n[j][i]
                f.write(f"face_n index: ({i},{j}), normal vector: ({face_n.ni}, {face_n.nj})\n")
                f.write(f"face_n middle point: ({face_n.mx}, {face_n.my})\n")
                f.write("-------------------------------------\n")

def mesh_visualization(savepath=None, show_centers=True, show_tau=True, show_n=True):
    """可视化网格,如果不指定保存路径`savepath`则直接显示图像.\n
    用参数`show_centers`控制是否显示单元中心.用参数`show_tau`和`show_n`控制显示周向/径向法向."""
    import matplotlib.pyplot as plt
    import os

    fig, ax = plt.subplots(figsize=(10, 10), dpi=120)

    # circumferential lines (constant i)
    for i in range(1, cc.i_total + 1):
        xs, ys = [], []
        for j in range(1, cc.j_total + 1):
            xs.append(cc.NodeList[i][j].x)
            ys.append(cc.NodeList[i][j].y)
        xs.append(cc.NodeList[i][1].x)
        ys.append(cc.NodeList[i][1].y)
        ax.plot(xs, ys, color='steelblue', linewidth=0.8, alpha=0.8)

    # radial lines (constant j)
    for j in range(1, cc.j_total + 1):
        xs, ys = [], []
        for i in range(1, cc.i_total + 1):
            xs.append(cc.NodeList[i][j].x)
            ys.append(cc.NodeList[i][j].y)
        ax.plot(xs, ys, color='steelblue', linewidth=0.8, alpha=0.8)

    # domain extent for auto-scaling arrows
    outer = cc.i_total
    xs_outer = [cc.NodeList[outer][j].x for j in range(1, cc.j_total + 1)]
    ys_outer = [cc.NodeList[outer][j].y for j in range(1, cc.j_total + 1)]
    domain_size = max(max(xs_outer) - min(xs_outer), max(ys_outer) - min(ys_outer))
    arrow_scale = domain_size * 0.03
    arrow_width = domain_size * 0.0003

    # subsample target: ~15 arrows per direction
    skip_i = max(1, (cc.i_total + 14) // 15)
    skip_j = max(1, (cc.j_total + 14) // 15)

    # cell centers
    if show_centers:
        cx, cy = [], []
        for i in range(1, cc.i_total):
            for j in range(1, cc.j_total + 1):
                cx.append(cc.CellList[i][j].x)
                cy.append(cc.CellList[i][j].y)
        ax.scatter(cx, cy, c='crimson', s=18, zorder=5, label='cell center')

    # face_tau normals (circumferential edge → radial outward)
    if show_tau:
        tx, ty, tni, tnj = [], [], [], []
        for i in range(1, cc.i_total + 1, skip_i):
            for j in range(1, cc.j_total + 1, skip_j):
                jn = j + 1 if j < cc.j_total else 1
                mx = (cc.NodeList[i][j].x + cc.NodeList[i][jn].x) * 0.5
                my = (cc.NodeList[i][j].y + cc.NodeList[i][jn].y) * 0.5
                tx.append(mx); ty.append(my)
                tni.append(cc.Facelist_tau[i][j].ni)
                tnj.append(cc.Facelist_tau[i][j].nj)
        ax.quiver(tx, ty, tni, tnj, color='darkcyan', scale=1/arrow_scale,
                  scale_units='xy', width=arrow_width, zorder=6, label='face_tau normal')

    # face_n normals (radial edge → circumferential)
    if show_n:
        nx, ny, nni, nnj = [], [], [], []
        for j in range(1, cc.j_total + 1, skip_j):
            for i in range(1, cc.i_total, skip_i):
                mx = (cc.NodeList[i][j].x + cc.NodeList[i+1][j].x) * 0.5
                my = (cc.NodeList[i][j].y + cc.NodeList[i+1][j].y) * 0.5
                nx.append(mx); ny.append(my)
                nni.append(cc.FaceList_n[j][i].ni)
                nnj.append(cc.FaceList_n[j][i].nj)
        ax.quiver(nx, ny, nni, nnj, color='darkorange', scale=1/arrow_scale,
                  scale_units='xy', width=arrow_width, zorder=6, label='face_n normal')

    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_title(f'O mesh — {cc.i_total} rings x {cc.j_total} radial points')
    ax.set_aspect('equal')
    if ax.get_legend_handles_labels()[0]:
        ax.legend()
    ax.grid(True, linestyle='--', alpha=0.3)

    if savepath:
        fig.savefig(savepath, dpi=150, bbox_inches='tight')
        print(f'mesh visualization saved to: {os.path.abspath(savepath)}')
    else:
        plt.show()
    plt.close(fig)

def geometry_main(debugoutput, ifrender=False, showwhat=(True, True, True)):
    calc_cell_vol()
    calc_cell_center()
    calc_face_direction_tau()
    calc_face_direction_n()
    calc_most_near_walldistance()
    geometry_debug(debugoutput)
    if ifrender:
        mesh_visualization("mesh_visual.svg",
                           show_centers=showwhat[0],
                           show_tau=showwhat[1],
                           show_n=showwhat[2])



