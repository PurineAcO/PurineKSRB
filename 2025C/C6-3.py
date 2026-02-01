import pandas as pd

# ===================== 1. 读取数据并预处理 =====================
# 文件1：国家-首次金牌年份（明确列名）
first_gold_df = pd.read_csv("country_first_gold_year_valid.csv")
# 清洗国家名称（去空格），计算“首次金牌年份前4年”
first_gold_df['国家_清洗'] = first_gold_df['国家'].str.strip()
first_gold_df['首次金牌年份'] = first_gold_df['首次获得金牌年份（排除第一年）']
# 核心修改：新增“首次金牌年份前4年”列（确保为整数类型）
first_gold_df['首次金牌前4年'] = first_gold_df['首次金牌年份'] - 4

# 文件2：原始奖牌数据（提取关键列并清洗）
raw_medal_df = pd.read_csv("summerOly_medal_counts.csv")
raw_medal_df['NOC_清洗'] = raw_medal_df['NOC'].str.strip()  # 国家名称去空格，统一匹配标准
# 保留关键列，减少数据量（仅需国家、年份、银、铜牌）
raw_medal_key = raw_medal_df[['NOC_清洗', 'Year', 'Silver', 'Bronze']].copy()

# 验证前4年计算结果（确保逻辑正确）
print("=== 首次金牌年份前4年计算验证 ===")
print(f"国家 | 首次金牌年份 | 首次金牌前4年")
print("-" * 40)
for _, row in first_gold_df.head(5).iterrows():
    print(f"{row['国家']:10} | {row['首次金牌年份']:^12} | {row['首次金牌前4年']:^12}")

# ===================== 2. 核心逻辑：匹配前4年的银铜牌 =====================
def match_prev4_silver_bronze(target_country, target_prev4_year, raw_data):
    """
    匹配目标国家“首次金牌年份前4年”的银牌和铜牌
    target_country：清洗后的国家名称
    target_prev4_year：首次金牌年份的前4年（整数）
    raw_data：清洗后的原始奖牌数据
    返回：前4年的银牌数、铜牌数；若无该年份数据，返回0, 0
    """
    # 精准匹配：国家一致 + 年份=首次金牌前4年
    matched_row = raw_data[
        (raw_data['NOC_清洗'] == target_country) & 
        (raw_data['Year'] == target_prev4_year)
    ]
    
    if not matched_row.empty:
        # 提取匹配年份的银、铜牌（转为整数，避免小数）
        silver = int(matched_row['Silver'].iloc[0])
        bronze = int(matched_row['Bronze'].iloc[0])
        return silver, bronze, "存在该年份数据"
    else:
        # 若前4年无该国家的奖牌记录（如未参赛），返回0和状态说明
        return 0, 0, "无该年份数据"

# 批量匹配所有国家的“首次金牌前4年”银铜牌
result_list = []
for _, row in first_gold_df.iterrows():
    # 提取当前国家的关键信息
    country_raw = row['国家']  # 原始国家名称（保留格式）
    country_clean = row['国家_清洗']  # 清洗后国家名称（用于匹配）
    first_gold_year = row['首次金牌年份']  # 原首次金牌年份
    target_prev4_year = row['首次金牌前4年']  # 目标匹配年份：前4年
    
    # 调用函数匹配前4年的银铜牌
    silver_prev4, bronze_prev4, data_status = match_prev4_silver_bronze(
        target_country=country_clean,
        target_prev4_year=target_prev4_year,
        raw_data=raw_medal_key
    )
    
    # 整理结果（包含原始信息、匹配状态和银铜牌数）
    result_list.append({
        '原始国家名称': country_raw,
        '首次获得金牌年份': first_gold_year,
        '首次金牌前4年（匹配年份）': target_prev4_year,
        '前4年银牌数': silver_prev4,
        '前4年铜牌数': bronze_prev4,
        '数据匹配状态': data_status
    })

# 转换为DataFrame，便于查看和保存
final_result = pd.DataFrame(result_list)

# ===================== 3. 结果统计与预览 =====================
print(f"\n=== 匹配结果统计 ===")
total_countries = len(final_result)
has_data = len(final_result[final_result['数据匹配状态'] == "存在该年份数据"])
no_data = len(final_result[final_result['数据匹配状态'] == "无该年份数据"])
has_medal = len(final_result[(final_result['前4年银牌数'] > 0) | (final_result['前4年铜牌数'] > 0)])

print(f"1. 总国家数：{total_countries}")
print(f"2. 前4年有奖牌记录的国家数：{has_data}（占比：{has_data/total_countries:.2%}）")
print(f"3. 前4年无奖牌记录的国家数：{no_data}（占比：{no_data/total_countries:.2%}）")
print(f"4. 前4年获得银/铜牌的国家数：{has_medal}（占比：{has_medal/total_countries:.2%}）")

print(f"\n=== 匹配结果预览（前10条）===")
print(final_result.to_string(index=False, max_colwidth=15))

# ===================== 4. 保存结果文件 =====================
# 1. 完整结果文件（含所有国家及匹配状态）
full_output = "country_first_gold_prev4_year_silver_bronze.csv"
final_result.to_csv(full_output, encoding='utf-8-sig', index=False)

# 2. 筛选结果文件（仅含前4年有银/铜牌的国家）
filtered_result = final_result[(final_result['前4年银牌数'] > 0) | (final_result['前4年铜牌数'] > 0)].copy()
filtered_output = "country_first_gold_prev4_year_with_medal.csv"
filtered_result.to_csv(filtered_output, encoding='utf-8-sig', index=False)

print(f"\n✅ 结果文件生成完成！")
print(f"- 完整结果文件：{full_output}（{len(final_result)}条记录，含所有国家前4年数据）")
print(f"- 筛选结果文件：{filtered_output}（{len(filtered_result)}条记录，仅含前4年有银/铜牌的国家）")

# 补充：前4年银铜牌数最多的3个国家示例
if len(filtered_result) > 0:
    print(f"\n=== 前4年银铜牌数最多的3个国家 ===")
    filtered_result['前4年奖牌总数（银+铜）'] = filtered_result['前4年银牌数'] + filtered_result['前4年铜牌数']
    top3 = filtered_result.nlargest(3, '前4年奖牌总数（银+铜）')
    print(top3[['原始国家名称', '首次金牌前4年（匹配年份）', '前4年银牌数', '前4年铜牌数', '前4年奖牌总数（银+铜）']].to_string(index=False))