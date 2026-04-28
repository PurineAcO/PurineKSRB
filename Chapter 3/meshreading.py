import numpy as np
import classconfig as cc

def read_mesh(meshfile):
    """read the meshdata and return the number of 
    points `i`,`j`, and **class list** `NodeList`.\n
    you should give the `meshfile` as the path of the meshdata\n
    and the meshdata should begin with a line of header which 
    contains the num of the `i` and `j` \n
    this case we should use n-direction number `i` and tau-direction number `j`  
    to construct the meshgrid, then the `NodeList` is a 2D list of **class** `Node`
    """

    with open(meshfile, 'r') as f:
        header = f.readline().strip()
        try:
            cc.i_total, cc.j_total= map(int, header.split())  
        except ValueError:
            print(f"Error: The header of {meshfile} is not in the expected format. Please check the file.")
            return 

    data = np.loadtxt(meshfile, skiprows=1)
    cc.meshcnt = len(data)

    if cc.meshcnt == 0:
        print(f"Error: No data found in {meshfile}. Please check the file format and content.")
        return 

    if cc.meshcnt != cc.i_total * cc.j_total:
        print(f"Error: Mismatch in number of points in {meshfile}.")
        return 

    readindex = 0
    # cc.NodeList = [[]]
    for i in range(cc.i_total):
        circle = [[]]
        for j in range(cc.j_total):
            tempnode = cc.node_class(readindex)
            tempnode.x = data[readindex, 0]
            tempnode.y = data[readindex, 1]
            circle.append(tempnode)
            readindex += 1
        cc.NodeList.append(circle)

    print(f"successfully read {meshfile} with {cc.meshcnt} points.")
    print(f"i_total: {cc.i_total}, j_total: {cc.j_total}, meshcnt: {cc.meshcnt}")


def mesh_visualization():
    """visualize the meshdata and return the figure.\n
    you should give the **class** `NodeList` """

    x=[]; y=[]
    for i in range(len(cc.NodeList)):
        for j in range(len(cc.NodeList[i])):
            x.append(cc.NodeList[i][j].x)
            y.append(cc.NodeList[i][j].y)       
    
    import matplotlib.pyplot as plt
    
    plt.figure(figsize=(10, 8), dpi=100)
    plt.scatter(x, y, s=5, c='steelblue', alpha=0.7, edgecolors='none')

    plt.xlabel('X Coordinate', fontsize=12)
    plt.ylabel('Y Coordinate', fontsize=12)
    plt.title('Grid Points Visualization (yuanzhudata.txt)', fontsize=14)
    plt.grid(True, linestyle='--', alpha=0.3)
    plt.axis('equal')

    plt.show()

# if __name__ == "__main__":
#     read_mesh("yuanzhudata.txt")
#     mesh_visualization()
