import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.svm import SVC
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import StandardScaler  # 数据标准化提升SVM效果
import joblib
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D  # 3D绘图依赖
from matplotlib.colors import ListedColormap
from matplotlib.table import Table  # 表格绘制依赖

# ===================== 第一步：数据读取与预处理（提升准确率核心步骤） =====================
# 读取训练用的两个文件（确保文件路径正确）
df1 = pd.read_csv('country_two_years_participant_times.csv')
df2 = pd.read_csv('only_zero_gold_countries_with_participants.csv')

# 提取特征和标签
X1 = df1.iloc[:, [3, 4, 7]].values  # 原文件4、5、8列（第一维=铜牌，第二维=银牌，第三维=其他）
X2 = df2.iloc[:, [5, 6, 8]].values  # 原文件6、7、9列（第一维=铜牌，第二维=银牌，第三维=其他）
y1 = np.ones(X1.shape[0])  # S类（1）
y2 = np.zeros(X2.shape[0]) # F类（0）

# 合并训练数据
X = np.concatenate((X1, X2), axis=0)
y = np.concatenate((y1, y2), axis=0)

# 🌟 关键优化1：数据标准化（SVM对特征尺度敏感，标准化能大幅提升准确率）
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)  # 标准化为均值0、方差1

# 划分训练集和测试集（标准化后的数据）
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y, test_size=0.2, random_state=42, stratify=y  # stratify：分层抽样，保证类别分布一致
)

# ===================== 第二步：SVM超参数调优（提升准确率核心步骤） =====================
# 🌟 关键优化2：网格搜索最优超参数（代替固定C和gamma）
param_grid = {
    'C': [0.1, 1, 10, 100],  # 惩罚系数：越大对误分类惩罚越重
    'gamma': ['scale', 'auto', 0.001, 0.01, 0.1, 1],  # 核函数系数：影响RBF核的拟合程度
    'kernel': ['rbf']  # 保持RBF核，适合非线性数据
}

# 网格搜索+交叉验证（cv=5：5折交叉验证）
grid_search = GridSearchCV(
    SVC(probability=True, random_state=42),  # probability=True用于后续可视化
    param_grid, 
    cv=5, 
    scoring='accuracy',  # 以准确率为评价指标
    n_jobs=-1  # 利用所有CPU核心加速
)
grid_search.fit(X_train, y_train)

# 输出最优参数和训练集最优准确率
print("🌟 最优超参数：", grid_search.best_params_)
print("🌟 交叉验证最优准确率：{:.2f}%".format(grid_search.best_score_ * 100))

# 使用最优参数构建最终模型
svm_model = grid_search.best_estimator_

# 在测试集评估模型效果
y_pred = svm_model.predict(X_test)
test_accuracy = accuracy_score(y_test, y_pred)
print("🌟 测试集最终准确率：{:.2f}%".format(test_accuracy * 100))
print("\n分类报告：")
print(classification_report(y_test, y_pred))

# 保存模型和标准化器（后续预测需要用相同的scaler）
joblib.dump(svm_model, 'optimized_svm_model.pkl')
joblib.dump(scaler, 'scaler.pkl')
print("\n优化后的模型和标准化器已保存！")

# ===================== 第三步：训练数据三维散点图可视化 =====================
# 设置可视化样式
plt.rcParams['figure.dpi'] = 300
plt.rcParams['font.sans-serif'] = ['WenQuanYi Zen Hei', 'SimHei', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False
cmap = ListedColormap(['#FF0000', '#00FF00'])  # 红=F(0)，绿=S(1)

# 创建3D图
fig = plt.figure(figsize=(12, 10))
ax = fig.add_subplot(111, projection='3d')

# 绘制训练数据三维散点图（用标准化前的数据更直观）
scatter = ax.scatter(
    X[:, 0], X[:, 1], X[:, 2],  # 三个特征维度
    c=y,  # 按类别着色
    cmap=cmap,
    edgecolors='k',  # 黑色边框，增强区分度
    s=10,  # 点的大小
    alpha=0.8  # 半透明，避免重叠遮挡
)

# 设置坐标轴标签
ax.set_xlabel('特征1（铜牌）', fontsize=12)
ax.set_ylabel('特征2（银牌）', fontsize=12)
ax.set_zlabel('特征3（第8/9列）', fontsize=12)
ax.set_title('SVM训练数据三维散点图（F=红色，S=绿色）', fontsize=14)

# 添加图例
legend1 = ax.legend(*scatter.legend_elements(), title="类别")
ax.add_artist(legend1)
plt.tight_layout()
plt.savefig('train_data_3d_scatter.png', bbox_inches='tight')
plt.show()

# ===================== 新增：铜牌-银牌 表格+可视化模块 =====================
## 1. 构建铜牌-银牌统计表格（按类别分组统计）
# 提取训练集原始数据的铜牌（第一维）、银牌（第二维）和标签
bronze_silver_df = pd.DataFrame({
    '铜牌数量': X[:, 0],
    '银牌数量': X[:, 1],
    '类别': np.where(y == 1, 'S', 'F')  # 转换为S/F标签
})

# 按类别分组统计：计算每个类别的铜牌/银牌 均值、中位数、最大值、最小值
stats_table = bronze_silver_df.groupby('类别').agg({
    '铜牌数量': ['mean', 'median', 'max', 'min'],
    '银牌数量': ['mean', 'median', 'max', 'min']
}).round(2)  # 保留2位小数

# 打印文本版表格
print("\n========== 铜牌-银牌 统计表格 ==========")
print(stats_table)

## 2. 可视化1：铜牌-银牌 分布散点图（带类别区分）
plt.figure(figsize=(10, 8))
# 绘制F类（红色）和S类（绿色）的散点
for label, color, marker in zip(['F', 'S'], ['#FF0000', '#00FF00'], ['o', '^']):
    subset = bronze_silver_df[bronze_silver_df['类别'] == label]
    plt.scatter(
        subset['铜牌数量'], subset['银牌数量'],
        c=color, label=f'类别{label}', marker=marker,
        edgecolors='k', s=60, alpha=0.7
    )

# 设置标签和标题
plt.xlabel('铜牌数量', fontsize=12)
plt.ylabel('银牌数量', fontsize=12)
plt.title('训练集 铜牌-银牌 数量分布（按类别区分）', fontsize=14)
plt.legend(loc='best')
plt.grid(alpha=0.3)  # 添加网格线
plt.tight_layout()
plt.savefig('bronze_silver_scatter.png', bbox_inches='tight')
plt.show()

## 3. 可视化2：matplotlib绘制铜牌-银牌 统计表格（图片版）
fig, ax = plt.subplots(figsize=(8, 4))
ax.set_axis_off()  # 隐藏坐标轴

# 构建表格数据
table_data = []
# 表头
headers = ['类别', '铜牌-均值', '铜牌-中位数', '铜牌-最大值', '铜牌-最小值', 
           '银牌-均值', '银牌-中位数', '银牌-最大值', '银牌-最小值']
# 填充数据（F类和S类）
for cls in ['F', 'S']:
    row = [cls]
    # 提取该类别的统计值
    bronze_stats = stats_table.loc[cls, '铜牌数量'].values
    silver_stats = stats_table.loc[cls, '银牌数量'].values
    row.extend(bronze_stats)
    row.extend(silver_stats)
    table_data.append(row)

# 创建表格
table = Table(ax, bbox=[0, 0, 1, 1])  # 覆盖整个画布
# 设置表格样式
cell_text = []
for i, row in enumerate(table_data):
    cell_text.append([str(val) for val in row])
    for j, val in enumerate(row):
        # 表头行样式
        if i == -1:
            table.add_cell(i, j, width=1/len(headers), height=1/3, text=val, 
                           loc='center', facecolor='#4472C4', edgecolor='w', text_props={'color':'white'})
        # 数据行样式
        else:
            face_color = '#E7E6E6' if i % 2 == 0 else '#FFFFFF'
            table.add_cell(i, j, width=1/len(headers), height=1/3, text=str(val), 
                           loc='center', facecolor=face_color, edgecolor='k')

# 添加表头
for j, header in enumerate(headers):
    table.add_cell(-1, j, width=1/len(headers), height=1/3, text=header, 
                   loc='center', facecolor='#4472C4', edgecolor='w', text_props={'color':'white'})

ax.add_table(table)
plt.title('训练集 铜牌-银牌 统计表格', fontsize=12, pad=20)
plt.tight_layout()
plt.savefig('bronze_silver_table.png', bbox_inches='tight')
plt.show()

# ===================== 第四步：新数据预测（适配优化后的模型） =====================
# 手动构建新数据集（你提供的8条数据）
new_data = [
    ['Kyrgyzstan', 'Kyrgyzstan', 2024, 68, 0, 2, 4, 6, 17],
    ['Moldova', 'Moldova', 2024, 72, 0, 1, 3, 4, 0],
    ['Cyprus', 'Cyprus', 2024, 74, 0, 1, 0, 1, 23],
    ['Albania', 'Albania', 2024, 80, 0, 0, 2, 2, 9],
    ['Malaysia', 'Malaysia', 2024, 80, 0, 0, 2, 2, 32],
    ['Cabo Verde', 'Cabo Verde', 2024, 84, 0, 0, 1, 1, 7],
    ['Refugee Olympic Team', 'Refugee Olympic Team', 2024, 84, 0, 0, 1, 1, 0],
    ['Zambia', 'Zambia', 2024, 84, 0, 0, 1, 1, 32]
]

# 转为DataFrame
columns = ['国家1', '国家2', '年份', '列4', '列5', '列6', '列7', '列8', '列9']
df_new = pd.DataFrame(new_data, columns=columns)

# 提取第6、7、9列作为预测特征，并标准化（必须和训练数据用相同的scaler）
X_new = df_new.iloc[:, [5, 6, 8]].values
X_new_scaled = scaler.transform(X_new)  # 用训练好的scaler标准化

# 预测
y_pred_new = svm_model.predict(X_new_scaled)
df_new['预测类别（数字）'] = y_pred_new
df_new['预测类别（S/F）'] = df_new['预测类别（数字）'].map({0: 'F', 1: 'S'})

# 输出预测结果
print("\n========== 新数据最终预测结果 ==========")
result_display = df_new[['国家1', '列6', '列7', '列9', '预测类别（S/F）']]
result_display.columns = ['国家', '铜牌数量', '银牌数量', '第9列', '预测结果（S/F）']  # 修正列名更直观
print(result_display)