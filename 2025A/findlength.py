import pandas as pd

# 读取CSV专用
# df = pd.read_csv('data.csv')

# # 读取 Excel 文件
# df = pd.read_excel("FY2import3.xlsx", sheet_name="Sheet3", usecols="H:I", header=None)
#
# # 转换成二维列表 [[x1, y1], [x2, y2], ...]
# intervals = df.values.tolist()


# 如果是空格分隔
#intervals = pd.read_csv("data.xlsx", sep='\s+', header=None)
# 测试用例
intervals = [
    [11.8, 12.07], [11.8, 12.41], [11.8, 12.67], [11.8, 12.73], [11.8, 12.85], [11.8, 12.92],
    [11.9, 12.09], [11.9, 13.06], [11.9, 13.65], [11.9, 14.13], [11.9, 14.52], [11.9, 14.83],
    [11.9, 15.07], [11.9, 15.25], [11.98, 15.37], [12.38, 15.43], [12.64, 15.93], [12.66, 15.39],
    [12.81, 15.37], [13.05, 14.46], [13.13, 16.98], [13.35, 17.2], [13.44, 15.17], [13.59, 17.37],
    [13.84, 17.51], [14.09, 17.6], [14.34, 17.67], [14.6, 17.7], [14.86, 17.68], [15.01, 18.31],
    [15.09, 18.62], [15.12, 17.63], [15.15, 17.41], [15.2, 18.87], [15.32, 19.07], [15.41, 17.54],
    [15.46, 19.24], [15.6, 19.37], [15.74, 17.42], [15.75, 16.37], [15.75, 19.48], [15.89, 19.56],
    [16.02, 19.62], [16.11, 17.22], [16.15, 19.67], [16.27, 19.7], [16.37, 19.73], [16.46, 19.74],
    [16.53, 19.75], [16.58, 19.76], [17.14, 20.27], [17.17, 20.5], [17.18, 19.98], [17.21, 20.68],
    [17.27, 20.84], [17.28, 19.61], [17.33, 20.96], [17.39, 21.06], [17.45, 21.14], [17.51, 21.2],
    [17.56, 19.06], [17.56, 21.25], [17.59, 21.29], [19.12, 21.93], [19.12, 21.93], [19.12, 21.93],
    [19.14, 21.92], [19.18, 21.81], [19.25, 21.59], [19.38, 21.29], [19.65, 20.83], [21.57, 21.91]
]
# 如果需要乘100并四舍五入
intervals = [[round(x*100), round(y*100)] for x, y in intervals]

# k = 3
# #intervals=[[1,3],[2,4],[5,7],[8,11],[9,13],[15,17]]
# mx = max([i[1] for i in intervals])
# end, dp = [mx + 10] * (mx + 1), [0] * (mx + 1)
# path = [[] for _ in range(mx + 1)]
#
# for idx, (s, e) in enumerate(intervals):
#     for j in range(s, e + 1):
#         if j <= mx:  # 防止越界
#             end[j] = min(end[j], s)
#
# for _ in range(k):
#     dp_c = [0] * (mx + 1)
#     path_c = [[] for _ in range(mx + 1)]
#
#     for i in range(1, mx + 1):
#         x = end[i]
#         dp_c[i] = dp_c[i - 1]
#         path_c[i] = path_c[i - 1].copy()
#
#         length = i - x
#         if 1 <= x <= mx and dp[x - 1] + length > dp_c[i]:
#             dp_c[i] = dp[x - 1] + length
#             path_c[i] = path[x - 1].copy()
#             # 找对应区间索引
#             for idx2, (s2, e2) in enumerate(intervals):
#                 if s2 <= x and e2 >= i:
#                     path_c[i].append(idx2)
#                     break
#         elif x <= 0 or x > mx:
#             continue  # 跳过不合法的 x
#
#     dp = dp_c.copy()
#     path = path_c.copy()
#
# def calcu(x1,x2,x3):
#     if x1[1]>=x2[0]:
#         if x2[1]>=x3[0]:
#             return x3[1]-x1[0]
#         else:
#             return x3[1]-x3[0]+x2[1]-x1[0]
#     else:
#         if x2[1]>=x3[0]:
#             return x1[1]-x1[0]+x3[1]-x2[0]
#         else:
#             return x1[1]+x2[1]+x3[1]-x1[0]-x2[0]-x3[0]
#
# print("选中的区间：", [intervals[i] for i in path[-1]])
# x1, x2, x3 = [intervals[i] for i in path[-1]]
# res=calcu(x1,x2,x3)
# print(res)

k = 2
#intervals=[[1,3],[2,4],[5,7],[8,11],[9,13],[15,17]]
mx = max([i[1] for i in intervals])
end, dp = [mx + 10] * (mx + 1), [0] * (mx + 1)
path = [[] for _ in range(mx + 1)]

for idx, (s, e) in enumerate(intervals):
    for j in range(s, e + 1):
        if j <= mx:  # 防止越界
            end[j] = min(end[j], s)

for _ in range(k):
    dp_cur = [0] * (mx + 1)
    path_cur = [[] for _ in range(mx + 1)]

    for i in range(1, mx + 1):
        x = end[i]
        dp_cur[i] = dp_cur[i - 1]
        path_cur[i] = path_cur[i - 1].copy()

        length = i - x
        if 1 <= x <= mx and dp[x - 1] + length > dp_cur[i]:
            dp_cur[i] = dp[x - 1] + length
            path_cur[i] = path[x - 1].copy()
            # 找对应区间索引
            for idx2, (s2, e2) in enumerate(intervals):
                if s2 <= x and e2 >= i:
                    path_cur[i].append(idx2)
                    break
        elif x <= 0 or x > mx:
            continue  # 跳过不合法的 x

    dp = dp_cur.copy()
    path = path_cur.copy()

def calcu(x1,x2):
    if x1[1]>=x2[0]:
        return x2[1]-x1[0]
    else:
        return x1[1]+x2[1]-x1[0]-x2[0]

print("选中的区间：", [intervals[i] for i in path[-1]])
x1, x2= [intervals[i] for i in path[-1]]
res=calcu(x1,x2)
print(res)