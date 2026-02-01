import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import CubicSpline

# ===================== 全局设置 =====================
plt.rcParams['font.sans-serif'] = ['Times New Roman']  # Times New Roman字体
plt.rcParams['axes.unicode_minus'] = False    # 正常显示负号
plt.rcParams['figure.dpi'] = 100              # 画布分辨率
plt.rcParams['savefig.dpi'] = 300             # 保存图片分辨率

# ===================== 1. 读取数据并筛选1920年后的数据 =====================
df = pd.read_csv("6countries_medal_data.csv")  # 替换为你的CSV文件路径
df = df[df['Year'] >= 1920].reset_index(drop=True)  # 筛选1920年后数据

# ===================== 2. 数据预处理 =====================
pred_2028 = df.groupby('Country')['2028_Prediction'].first().to_dict()

# ===================== 3. 全局连续样条插值 =====================
# 小清新配色
colors = {
    'United States': '#a5c947',    
    'China': "#01bd94",           
    'Great Britain': "#0aabd3",    
    'Japan': "#5e689e",            
    'Sweden': '#3f144d'           
}

fig, ax = plt.subplots(figsize=(14, 8))

for country in df['Country'].unique():
    country_history = df[df['Country'] == country].sort_values('Year')
    x_hist = country_history['Year'].values
    y_hist = country_history['Total_Medals'].values
    
    last_year = x_hist.max()
    pred_year = 2028
    pred_value = pred_2028[country]
    
    x_global = np.concatenate([x_hist, [pred_year]])
    y_global = np.concatenate([y_hist, [pred_value]])
    
    spl_global = CubicSpline(x_global, y_global, bc_type='natural')
    
    x_smooth_hist = np.linspace(x_hist.min(), last_year, 300)
    y_smooth_hist = spl_global(x_smooth_hist)
    y_smooth_hist = np.clip(y_smooth_hist, 0, None)
    
    x_smooth_pred = np.linspace(last_year, pred_year, 100)
    y_smooth_pred = spl_global(x_smooth_pred)
    y_smooth_pred = np.clip(y_smooth_pred, 0, None)
    
    # 加粗曲线 + 高透明度（小清新）
    ax.plot(x_smooth_hist, y_smooth_hist, color=colors[country], linewidth=3.0, alpha=1.0)
    ax.plot(x_smooth_pred, y_smooth_pred, 
            color=colors[country], linestyle='--', linewidth=2.5, alpha=0.7)
    
    # 🔴 修改1：降低数据点透明度（alpha=0.9，更实）+ 加粗描边
    ax.scatter(x_hist, y_hist, color=colors[country], s=45, edgecolor='black', linewidth=1.0)
    
    # 加粗五角星边框
    ax.scatter(pred_year, pred_value, color=colors[country], 
               marker='*', s=160, edgecolor='black', linewidth=1.2, alpha=1.0)

# ===================== 4. 图表美化 =====================
ax.set_title('Historical Trend of Olympic Medals by Country and 2028 Prediction', fontsize=18, pad=20)
ax.set_xlabel('Year', fontsize=16)
ax.set_ylabel('Total Medals', fontsize=16)

# 横纵坐标刻度字号
ax.tick_params(axis='x', labelsize=13)  
ax.tick_params(axis='y', labelsize=13)  

# 网格设置
ax.grid(False)

# 坐标轴范围
ax.set_xlim(1920, 2035)
ax.set_ylim(0, 200)

# 安全取消图例
if ax.get_legend() is not None:
    ax.get_legend().remove()

# 2028标注文字（斜体）+ 加粗标注线
ax.axvline(x=2028, color='#666666', linestyle=':', linewidth=2.0, alpha=0.8)
ax.text(2012, 190, r'2028 Prediction →', fontsize=16, color='#333333', 
        usetex=False, style='italic')

# 🔴 修改2：加粗图表外边框
# 获取图表的四个边框（top/bottom/left/right）
for spine in ax.spines.values():
    spine.set_linewidth(2.0)  # 边框宽度设为2.0（默认1.0）
    spine.set_color('#333333')  # 边框颜色设为深灰色（更醒目）

# 调整布局
plt.tight_layout(pad=2.0)

# 保存图片
plt.savefig("medal_trend_final_1920_en_ylim200_fresh_bold_border.png", dpi=300, bbox_inches='tight', facecolor='white')
plt.show()

print("✅ 最终版图表已保存：medal_trend_final_1920_en_ylim200_fresh_bold_border.png")