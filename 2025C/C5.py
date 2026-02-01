import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import MinMaxScaler
from keras.models import Sequential
from keras.layers import LSTM, Dense, Dropout
from keras.callbacks import EarlyStopping

# -------------------------- 1. 核心配置（仅需修改文件路径） --------------------------
DATA_FILE_PATH = "counts.csv"  # 替换为你的数据文件路径（csv/xlsx）
TIME_STEP = 5  # 用前5年预测下一年，数据量少可改为3

# -------------------------- 2. 数据加载与预处理（严格匹配表头） --------------------------
# 加载数据（自动兼容csv/xlsx）
try:
    df = pd.read_csv(DATA_FILE_PATH, encoding='utf-8')
except UnicodeDecodeError:
    df = pd.read_csv(DATA_FILE_PATH, encoding='gbk')  # 适配中文编码
except:
    df = pd.read_excel(DATA_FILE_PATH)

# 打印数据校验信息（快速核对NOC列的国家全称）
print("=== 数据基础信息 ===")
print(f"数据表头：{df.columns.tolist()}")
print(f"\n前5行数据：\n{df.head()}")
print(f"\nNOC列的国家全称（前10个）：\n{df['NOC'].unique()[:10]}")
print("-"*80)

# 数据清洗：仅保留核心列 + 删除缺失值 + 去重
# 严格匹配你的表头：Rank、NOC、Gold、Silver、Bronze、Total、Year
df = df[['NOC', 'Total', 'Year']].dropna(subset=['NOC', 'Total', 'Year'])
df = df.drop_duplicates(subset=['NOC', 'Year'])  # 去重同国家同年份数据
df = df.sort_values(by=['NOC', 'Year']).reset_index(drop=True)  # 按国家+年份排序

# -------------------------- 3. 自动筛选有效国家（适配任意长度全称） --------------------------
valid_countries = []  # 存储数据量足够的国家全称
country_data = {}     # 存储每个国家的历史数据
scalers = {}          # 存储每个国家的标准化器

# 遍历所有唯一的国家全称（NOC列）
all_countries = df['NOC'].unique()
for country_full_name in all_countries:
    # 提取单个国家的所有数据
    country_df = df[df['NOC'] == country_full_name].copy()
    
    # 校验：数据量需≥TIME_STEP+1（才能构建时间序列）
    if len(country_df) >= TIME_STEP + 1:
        valid_countries.append(country_full_name)
        # 存储该国家的年份和奖牌总数
        country_data[country_full_name] = {
            "years": country_df['Year'].values,
            "total": country_df['Total'].values.flatten(),
            "total_sum": country_df['Total'].sum()  # 新增：统计该国家历史奖牌总数
        }
        # 打印信息：适配长名称展示
        print(f"✅ 有效国家：{country_full_name.ljust(20)} | 数据行数：{len(country_df)} | 年份范围：{country_df['Year'].min()} - {country_df['Year'].max()}")
    else:
        print(f"❌ 跳过国家：{country_full_name.ljust(20)} | 数据量不足（仅{len(country_df)}条），需至少{TIME_STEP+1}条")

# 最终校验：无有效国家则终止
if not valid_countries:
    raise ValueError(f"❌ 无有效国家数据！请减小TIME_STEP（当前{TIME_STEP}）或检查数据文件")
print(f"\n最终可预测的国家列表：{valid_countries}")
print("-"*80)

# -------------------------- 4. 构建LSTM训练数据集 --------------------------
def create_sequences(data, time_step):
    """生成LSTM输入序列：前time_step个值→下一个值"""
    X, y = [], []
    for i in range(len(data) - time_step):
        X.append(data[i:i+time_step])
        y.append(data[i+time_step])
    return np.array(X), np.array(y)

# 为每个有效国家构建标准化训练数据
X_train_list, y_train_list = [], []
for country_full_name in valid_countries:
    # 提取奖牌总数并标准化（单国家独立标准化）
    total_data = country_data[country_full_name]["total"].reshape(-1, 1)
    scaler = MinMaxScaler(feature_range=(0, 1))
    total_scaled = scaler.fit_transform(total_data)
    scalers[country_full_name] = scaler
    
    # 构建时间序列并调整输入格式
    X, y = create_sequences(total_scaled, TIME_STEP)
    X = X.reshape(X.shape[0], X.shape[1], 1)  # LSTM要求：[样本数, 时间步, 特征数]
    
    X_train_list.append(X)
    y_train_list.append(y)

# 合并所有国家的训练数据
X_train = np.concatenate(X_train_list, axis=0)
y_train = np.concatenate(y_train_list, axis=0)
print(f"✅ 训练数据构建完成 | 总样本数：{len(X_train)}")
print("-"*80)

# -------------------------- 5. 搭建并训练LSTM模型 --------------------------
def build_lstm_model(input_shape):
    """轻量LSTM模型，适配单维度（奖牌总数）预测"""
    model = Sequential()
    model.add(LSTM(64, return_sequences=True, input_shape=input_shape))
    model.add(Dropout(0.2))  # 防过拟合
    model.add(LSTM(64, return_sequences=False))
    model.add(Dropout(0.2))
    model.add(Dense(1))  # 输出层：1个神经元（预测奖牌总数）
    
    model.compile(optimizer="adam", loss="mean_squared_error")
    return model

# 初始化模型并训练
model = build_lstm_model(input_shape=(TIME_STEP, 1))
# 早停机制：损失不再下降则停止，避免过拟合
early_stop = EarlyStopping(monitor="loss", patience=5, restore_best_weights=True)

print("=== 开始训练LSTM模型 ===")
history = model.fit(
    X_train, y_train,
    epochs=50,
    batch_size=8,
    callbacks=[early_stop],
    verbose=1
)
print("✅ 模型训练完成！")
print("-"*80)

# -------------------------- 6. 预测2028年奖牌总数 --------------------------
predictions_2028 = {}

def predict_2028_medals(country_full_name):
    """预测单个国家2028年的奖牌总数"""
    # 提取该国家最后TIME_STEP个历史数据
    last_total = country_data[country_full_name]["total"][-TIME_STEP:]
    # 标准化
    last_scaled = scalers[country_full_name].transform(last_total.reshape(-1, 1))
    last_scaled = last_scaled.reshape(1, TIME_STEP, 1)
    # 预测并反标准化（还原真实值）
    pred_scaled = model.predict(last_scaled, verbose=0)
    pred_total = scalers[country_full_name].inverse_transform(pred_scaled)[0][0]
    # 确保预测值为非负整数（奖牌数无负数/小数）
    return max(round(pred_total), 0)

# 批量预测所有有效国家
for country_full_name in valid_countries:
    predictions_2028[country_full_name] = predict_2028_medals(country_full_name)

# -------------------------- 7. 输出预测结果（适配长国家名称） --------------------------
print("\n=== 2028年奥运会奖牌总数预测结果 ===")
for country_full_name, total in predictions_2028.items():
    # 对齐长名称，展示更清晰
    print(f"{country_full_name.ljust(25)} | 2028年预测奖牌总数：{total} 枚")
print("-"*80)

# -------------------------- 8. 可视化结果（核心修改：绘制奖牌数TOP15国家） --------------------------
# 步骤1：按历史奖牌总数排序，筛选TOP15国家
# 构建「国家名称-历史总奖牌数」字典
country_total_dict = {k: v['total_sum'] for k, v in country_data.items()}
# 按奖牌数降序排序，取前15个
top15_countries = sorted(country_total_dict.items(), key=lambda x: x[1], reverse=True)[:15]
top15_names = [item[0] for item in top15_countries]
print(f"\n=== 历史奖牌总数TOP15国家 ===")
for idx, (name, total) in enumerate(top15_countries, 1):
    print(f"{idx:2d}. {name.ljust(25)} | 历史总奖牌数：{total}")

# 步骤2：绘制TOP15国家的曲线（适配长名称展示）
plt.figure(figsize=(18, 10))  # 放大图表，适配15个国家展示
# 扩展配色方案（适配15个国家）
colors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FECA57',
    '#FF9FF3', '#54A0FF', '#5F27CD', '#00D2D3', '#FF7F50',
    '#10AC84', '#FF3838', '#3742fa', '#F79F1F', '#A3CB38'
]
color_map = dict(zip(top15_names, colors[:len(top15_names)]))

# 绘制TOP15国家的历史数据 + 2028预测值
for idx, country_full_name in enumerate(top15_names):
    years = country_data[country_full_name]["years"]
    total = country_data[country_full_name]["total"]
    pred_total = predictions_2028[country_full_name]
    
    # 绘制历史数据曲线（适配长名称标签）
    plt.plot(
        years, total, 'o-', color=color_map[country_full_name],
        label=f'{idx+1}. {country_full_name}', linewidth=2, markersize=5
    )
    # 绘制2028预测值（星形标记，突出显示）
    plt.scatter(
        2028, pred_total, color=color_map[country_full_name],
        s=150, marker='*', zorder=10
    )

# 图表美化（适配15个国家展示）
plt.title('2028 Olympic Medals Total Prediction (TOP15 Countries by Total Medals)', fontsize=18, pad=20)
plt.xlabel('Year', fontsize=14)
plt.ylabel('Total Medals', fontsize=14)
# 图例分两列展示，避免过长
plt.legend(bbox_to_anchor=(1.02, 1), loc='upper left', fontsize=9, ncol=2)
plt.grid(True, alpha=0.3)
plt.tight_layout()  # 自动适配布局，防止标签被截断
plt.show()