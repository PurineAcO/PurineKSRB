import pandas as pd
import numpy as np

# ===================== 1. 读取数据并预处理（核心：国家名称去空格） =====================
# 读取CSV文件（替换为你的实际文件路径）
df = pd.read_csv("summerOly_medal_counts.csv")

print("=== 数据预处理前的关键检查 ===")
# 检查NOC列是否存在前后空格（示例：查看前20个NOC，带引号显示以暴露空格）
print("前20个NOC原始值（带引号，可观察空格）：")
for i, noc in enumerate(df['NOC'].head(20), 1):
    print(f"{i:2d}. '{noc}'")  # 引号包裹可清晰看到前后空格

# 🔴 核心步骤：清洗NOC名称——去除前后空格，避免伪重复
df['NOC_Cleaned'] = df['NOC'].str.strip()  # 去除字符串前后的空格（中间空格保留，如"Great Britain"）

# 检查清洗效果：对比清洗前后的重复情况
print(f"\n=== 去空格清洗效果 ===")
print(f"清洗前唯一NOC数量：{df['NOC'].nunique()}")
print(f"清洗后唯一NOC数量：{df['NOC_Cleaned'].nunique()}")
if df['NOC'].nunique() > df['NOC_Cleaned'].nunique():
    print(f"✅ 成功合并 {df['NOC'].nunique() - df['NOC_Cleaned'].nunique()} 组因空格导致的重复国家！")

# ===================== 2. 构建“清洗后国家-年份”金牌矩阵 =====================
# 提取清洗后的唯一国家和年份（排序）
unique_nocs = sorted(df['NOC_Cleaned'].unique())  # 按字母排序
unique_years = sorted(df['Year'].unique())        # 按时间排序

print(f"\n=== 矩阵基础信息 ===")
print(f"最终包含国家/地区数量：{len(unique_nocs)}")
print(f"包含奥运会年份数量：{len(unique_years)}")
print(f"年份范围：{unique_years[0]} - {unique_years[-1]}")

# 创建空矩阵（行：清洗后的NOC，列：年份）
gold_matrix = pd.DataFrame(
    index=unique_nocs,
    columns=unique_years,
    dtype=int
)

# 填充矩阵：使用清洗后的NOC名称匹配，避免空格导致的填充失败
for _, row in df.iterrows():
    cleaned_noc = row['NOC_Cleaned']
    year = row['Year']
    gold = row['Gold']
    gold_matrix.loc[cleaned_noc, year] = gold

# 缺失值填充为0（未获金牌或未参与）
gold_matrix = gold_matrix.fillna(0).astype(int)

# ===================== 3. 添加统计列 & 排序 =====================
# 总金牌数（累计）
gold_matrix['Total_Gold'] = gold_matrix[unique_years].sum(axis=1)
# 参与届数（获得至少1枚金牌的届数）
gold_matrix['Participated_Years_Count'] = (gold_matrix[unique_years] > 0).sum(axis=1)

# 按总金牌数降序排序
gold_matrix = gold_matrix.sort_values('Total_Gold', ascending=False)

# ===================== 4. 预览 & 保存 =====================
print(f"\n=== 金牌矩阵预览（前10国家/地区，前10年份）===")
print(gold_matrix.iloc[:10, :10])

print(f"\n=== 总金牌数Top10 ===")
print(gold_matrix[['Total_Gold', 'Participated_Years_Count']].head(10))

# 保存CSV（含清洗后的NOC名称）
output_path = "country_year_gold_matrix_cleaned.csv"
gold_matrix.to_csv(output_path, encoding='utf-8-sig', index_label='NOC_Cleaned')

print(f"\n✅ 去空格清洗后的金牌矩阵CSV已生成！")
print(f"文件路径：{output_path}")
print(f"关键说明：所有国家名称已去除前后空格，相同国家已合并，无伪重复数据。")



