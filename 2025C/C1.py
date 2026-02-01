import pandas as pd
import numpy as np

# 1. 读取原始数据（UTF-8，仅用NOC缩写）
df_athlete = pd.read_csv("athletes.csv", encoding='utf-8')

# 2. 筛选核心数据：2024年 + 有奖牌的记录
df_2024 = df_athlete[
    (df_athlete['Year'] == 2024) &  # 仅2024年
    (df_athlete['Medal'].notna())   # 仅有奖牌的记录
].copy()

# 3. 计算奖牌加权得分（金=0.5，银=0.3，铜=0.2，简化统计）
df_2024['Gold_Score'] = (df_2024['Medal'] == 'Gold').astype(int) * 0.5
df_2024['Silver_Score'] = (df_2024['Medal'] == 'Silver').astype(int) * 0.3
df_2024['Bronze_Score'] = (df_2024['Medal'] == 'Bronze').astype(int) * 0.2
df_2024['Total_Score'] = df_2024['Gold_Score'] + df_2024['Silver_Score'] + df_2024['Bronze_Score']

# 4. 按“国家(NOC缩写)+项目”汇总得分（无映射）
medal_stats = df_2024.groupby(['NOC', 'Sport'])['Total_Score'].sum().reset_index()

# 5. 保存统计结果（UTF-8，仅含NOC缩写）
medal_stats.to_csv("step1_medal_stats_2024.csv", encoding='utf-8', index=False)

# 输出验证
print("✅ 步骤1完成：")
print(f"- 生成文件：step1_medal_stats_2024.csv")
print(f"- 统计维度：{medal_stats.shape[0]}条国家-项目记录")
print(f"- 涉及国家数：{medal_stats['NOC'].nunique()}个（均为缩写）")
print("- 前5条数据预览：")
print(medal_stats.head())