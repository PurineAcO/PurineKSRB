import pandas as pd
import numpy as np

# ===================== 1. 读取数据并匹配年份列类型 =====================
# 读取清洗后的金牌矩阵文件（确保索引列正确）
# 若你的文件索引列不是"NO_Cleaned"，可根据实际表头修改（如"Country"）
df = pd.read_csv("country_year_gold_matrix_cleaned.csv", index_col=0)  # index_col=0表示用第一列作为行索引

# 查看数据结构，重点确认年份列的类型
print("=== 数据基本信息 ===")
print(f"数据形状：{df.shape}（{df.shape[0]}个国家 × {df.shape[1]}列）")
print(f"所有列名：{df.columns.tolist()}")
print(f"年份列示例（前5个）：{[col for col in df.columns if col.isdigit()][:5]}")
print(f"年份列类型：字符串（如 '1896'）")  # 关键：确认年份列是字符串类型

# 分离年份列和统计列（只保留纯数字的年份列，排除Total_Gold等统计列）
# 核心修正：年份列名保留字符串类型，不转整数
year_columns = sorted([col for col in df.columns if col.isdigit()])  # 如 ['1896', '1900', ..., '2024']
gold_data = df[year_columns].copy()  # 此时列名类型匹配，不会报KeyError

print(f"\n=== 年份范围 ===")
print(f"最早奥运会年份：{year_columns[0]}")
print(f"最晚奥运会年份：{year_columns[-1]}")
print(f"共{len(year_columns)}届奥运会")
print(f"前5个国家的金牌数据预览：")
print(gold_data.head())

# ===================== 2. 计算每个国家首次获得金牌的年份（排除第一年） =====================
def get_first_gold_year(country_data, years):
    """
    country_data: 单个国家各年份的金牌数（Series，列名是字符串年份）
    years: 字符串类型的年份列表（与country_data顺序一致）
    返回：首次获金年份（排除第一年），无则返回None
    """
    # 遍历年份（从第二年开始，i=0是第一年，跳过）
    for i in range(1, len(years)):
        year = years[i]
        gold = country_data[year]  # 用字符串年份匹配列名
        if gold > 0:  # 找到第一个金牌数>0的年份
            return year
    # 仅第一年获金/从未获金，返回None
    return None

# 批量计算所有国家的首次获金年份
first_gold_result = []
for country in gold_data.index:
    country_gold = gold_data.loc[country]  # 单个国家的所有年份金牌数据
    first_year = get_first_gold_year(country_gold, year_columns)
    
    # 整理结果
    first_gold_result.append({
        '国家': country,
        '首次获得金牌年份（排除第一年）': first_year if first_year is not None else '无（仅第一年获金或未获金）',
        '是否有效首次获金': '是' if first_year is not None else '否'
    })

# 转换为DataFrame便于查看
first_gold_df = pd.DataFrame(first_gold_result)

# 筛选有效结果（排除“无”的情况）
valid_first_gold = first_gold_df[first_gold_df['是否有效首次获金'] == '是']
invalid_first_gold = first_gold_df[first_gold_df['是否有效首次获金'] == '否']

print(f"\n=== 统计结果 ===")
print(f"总国家数量：{len(first_gold_df)}")
print(f"有有效首次获金的国家数量（排除第一年）：{len(valid_first_gold)}")
print(f"无有效首次获金的国家数量：{len(invalid_first_gold)}")

print(f"\n=== 有有效首次获金的国家示例（前10个）===")
print(valid_first_gold[['国家', '首次获得金牌年份（排除第一年）']].to_string(index=False))

# ===================== 3. 保存结果为CSV =====================
# 保存完整结果（含所有国家）
full_output_path = "country_first_gold_year_full.csv"
first_gold_df.to_csv(full_output_path, encoding='utf-8-sig', index=False)

# 单独保存有效结果（仅含首次获金的国家）
valid_output_path = "country_first_gold_year_valid.csv"
valid_first_gold[['国家', '首次获得金牌年份（排除第一年）']].to_csv(
    valid_output_path, encoding='utf-8-sig', index=False
)

print(f"\n✅ 结果文件已生成！")
print(f"1. 完整结果文件：{full_output_path}（含所有国家的首次获金情况）")
print(f"2. 有效结果文件：{valid_output_path}（仅含排除第一年後首次获金的国家）")

# 补充关键信息
if len(valid_first_gold) > 0:
    earliest_year = min(valid_first_gold['首次获得金牌年份（排除第一年）'])
    earliest_countries = valid_first_gold[valid_first_gold['首次获得金牌年份（排除第一年）'] == earliest_year]['国家'].tolist()
    print(f"\n=== 补充信息 ===")
    print(f"首次获金年份最早的国家：{', '.join(earliest_countries)}（{earliest_year}年）")