import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.patches import Circle

# ===================== 全局设置 =====================
plt.rcParams['font.sans-serif'] = ['SimHei']
plt.rcParams['axes.unicode_minus'] = False
plt.rcParams['figure.dpi'] = 100
plt.rcParams['savefig.dpi'] = 300

# ===================== 1. 数据读取与预处理 =====================
medal_stats = pd.read_csv("step1_medal_stats_2024.csv", encoding='utf-8')
pca_input = medal_stats.pivot(
    index='NOC',
    columns='Sport',
    values='Total_Score'
).fillna(0)
scaler = StandardScaler()
pca_input_scaled = scaler.fit_transform(pca_input)

# ===================== 2. 执行PCA降维 =====================
pca = PCA(n_components=5)
pca_result = pca.fit_transform(pca_input_scaled)
pca_df = pd.DataFrame(
    pca_result,
    columns=['PC1', 'PC2', 'PC3', 'PC4', 'PC5'],
    index=pca_input.index
).reset_index()
pca_df.to_csv("step2_pca_result.csv", encoding='utf-8', index=False)

# ===================== 3. 载荷矩阵计算 =====================
loadings = pca.components_.T
loading_df = pd.DataFrame(
    loadings,
    columns=['PC1', 'PC2', 'PC3', 'PC4', 'PC5'],
    index=pca_input.columns
)
loading_df.to_csv("step2_pca_loadings.csv", encoding='utf-8')

# ===================== 4. 可视化：圆点占比最大化+单元格最小化 =====================
sports = loading_df.index.values
pcs = ['PC1', 'PC2', 'PC3', 'PC4', 'PC5']

# 颜色映射：红→白
colors = ['#FF3333', '#FFFFFF']
cmap = LinearSegmentedColormap.from_list('custom_red', colors, N=100)
vmin = loading_df[pcs].min().min()
vmax = 0
norm = plt.Normalize(vmin, vmax)

# 创建画布（宽度适配所有项目，高度进一步压缩）
fig, ax = plt.subplots(figsize=(30, 3.5))

# 压缩单元格大小
n_sports = len(sports)
n_pcs = len(pcs)
ax.set_xlim(-0.1, n_sports - 0.9)
ax.set_ylim(-0.1, n_pcs - 0.9)

# 设置刻度
ax.set_xticks(np.arange(n_sports))
ax.set_yticks(np.arange(n_pcs))
ax.set_xticklabels(sports, rotation=90, ha='center', fontsize=6)
ax.set_yticklabels(pcs, fontsize=9)

# 绘制网格线（更细）
ax.set_xticks(np.arange(-0.5, n_sports, 1), minor=True)
ax.set_yticks(np.arange(-0.5, n_pcs, 1), minor=True)
ax.grid(which='minor', color='#DDDDDD', linestyle='-', linewidth=0.4)
ax.tick_params(which='minor', size=0)

# 绘制圆点（占据单元格80%以上空间）
for i, pc in enumerate(pcs):
    for j, sport in enumerate(sports):
        value = -(loading_df.loc[sport, pc])
        color = cmap(norm(value))
        # 圆点半径最大0.4（单元格宽度为1，半径0.4意味着占满80%宽度）
        radius = np.clip(0.6 * abs(value) + 0.05, 0.3, 0.8)
        circle = Circle((j, i), radius, color=color, ec='#444444', lw=0.15)
        ax.add_patch(circle)

# 添加颜色条
sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
sm.set_array([])
cbar = plt.colorbar(sm, ax=ax, orientation='vertical', aspect=10, shrink=0.65)
cbar.set_label('载荷值（红色=负贡献，白色=无贡献）', fontsize=9)

# 调整布局
ax.set_title('PCA载荷矩阵可视化（圆点占比最大化版）', fontsize=11, pad=12)
plt.tight_layout()
plt.savefig("step2_pca_loadings_heatmap_max_density.png", dpi=300, bbox_inches='tight')
plt.show()

# ===================== 输出验证 =====================
print("\n✅ 圆点占比最大化版可视化完成：")
print(f"- 生成图片：step2_pca_loadings_heatmap_max_density.png")