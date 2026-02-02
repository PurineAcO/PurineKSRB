import math
from datetime import datetime
import matplotlib.pyplot as plt
import numpy as np
import random

# ===================== 字体配置 =====================
plt.rcParams['font.sans-serif'] = ['SimHei']
plt.rcParams['axes.unicode_minus'] = False
# ====================================================

def generate_regular_polygon_wall_azimuths(n: int) -> list:
    """生成正n边形墙面法向方位角"""
    if not isinstance(n, int) or n < 3 or n > 100:  # 放宽上限到100，适配优化需求
        raise ValueError("边数n必须是3~100之间的整数")
    delta = 360.0 / n
    wall_azimuths = []
    for i in range(n):
        az = delta * i
        if az > 180.0:
            az -= 360.0
        wall_azimuths.append(round(az, 2))
    wall_azimuths = sorted(list(set(wall_azimuths)))[:n]
    return wall_azimuths

class SunIlluminanceCalculator:
    def __init__(self, lat: float, lng: float, wall_azimuths: list, window_wall_ratio: float):
        self.lat = lat
        self.lng = lng
        self.PI = math.pi
        self.RAD = self.PI / 180.0  # 角度转弧度系数
        self.EARTH_OBLIQUITY = 23.4397 * self.RAD

        self.wall_azimuths = wall_azimuths
        self.n_walls = len(wall_azimuths)
        self.window_wall_ratio = np.clip(window_wall_ratio, 0.2, 0.7)

    def calculate_sun_position(self, date_time):
        """计算太阳高度角、方位角（统一单位：弧度/角度，保证后续计算准确）"""
        dt = date_time
        day_of_year = dt.timetuple().tm_yday

        # 太阳赤纬
        decl_rad = 0.4093 * math.sin(2 * self.PI * (284 + day_of_year) / 365)
        # 时角（12点为0，上午为负，下午为正）
        hour_angle = (dt.hour - 12 + dt.minute/60 + dt.second/3600) * 15 * self.RAD
        # 纬度转弧度
        lat_rad = self.lat * self.RAD

        # 太阳高度角（弧度+角度）
        sin_sun_alt = math.sin(lat_rad) * math.sin(decl_rad) + \
                      math.cos(lat_rad) * math.cos(decl_rad) * math.cos(hour_angle)
        sin_sun_alt = max(min(sin_sun_alt, 1.0), -1.0)
        sun_alt_rad = math.asin(sin_sun_alt)
        sun_alt_deg = math.degrees(sun_alt_rad)

        # 太阳方位角（弧度+角度，0~360°，南=180°）
        cos_sun_az = (math.sin(decl_rad) - math.sin(lat_rad) * math.sin(sun_alt_rad)) / \
                     (math.cos(lat_rad) * math.cos(sun_alt_rad) + 1e-12)
        cos_sun_az = max(min(cos_sun_az, 1.0), -1.0)
        sun_az_rad = math.acos(cos_sun_az)
        if hour_angle > 0:
            sun_az_rad = 2 * self.PI - sun_az_rad
        sun_az_deg = math.degrees(sun_az_rad)

        return {
            'alt_rad': sun_alt_rad, 'alt_deg': sun_alt_deg,
            'az_rad': sun_az_rad, 'az_deg': sun_az_deg
        }

    def calculate_phi_k(self, sun_data, wall_az_deg):
        """
        修正版：支持任意朝向墙面（含东/西向）的三维入射夹角计算
        """
        # 1. 提取太阳参数（弧度）
        sun_az_rad = sun_data['az_rad']    # 太阳方位角（弧度，正南=180°）
        sun_alt_rad = sun_data['alt_rad']  # 太阳高度角（弧度）
        sun_alt_deg = sun_data['alt_deg']  # 太阳高度角（角度，用于快速判断）

        # 2. 墙面法线方位角标准化（转弧度，统一到0~2π范围）
        wall_az_deg_abs = (wall_az_deg + 360) % 360  # 标准化到0~360°
        wall_az_rad = wall_az_deg_abs * self.RAD     # 转弧度

        # 3. 定义三维单位向量（关键：支持任意墙面朝向）
        # 墙面法线向量（水平面内，垂直于墙面，单位向量）
        wall_normal = np.array([
            math.sin(wall_az_rad),  # x分量：东向（正）/西向（负）
            math.cos(wall_az_rad),  # y分量：南向（正）/北向（负）
            0.0                     # z分量：墙面法线无垂直分量
        ])

        # 太阳光线向量（指向太阳的单位向量，三维）
        sun_dir = np.array([
            math.sin(sun_az_rad) * math.cos(sun_alt_rad),  # x：东/西分量
            math.cos(sun_az_rad) * math.cos(sun_alt_rad),  # y：南/北分量
            math.sin(sun_alt_rad)                          # z：垂直高度分量
        ])

        # 4. 计算三维向量点积（核心：真实的cos(phi)）
        cos_phi = np.dot(wall_normal, sun_dir)

        # 5. 物理约束：仅当太阳在墙面正面（cos_phi>0）且太阳高度>0时有效
        if cos_phi < 0 or sun_alt_deg <= 0:
            cos_phi = 0.0
        cos_phi = max(min(cos_phi, 1.0), 0.0)  # 钳位到[0,1]

        # 6. 计算phi（入射夹角，弧度/角度）
        phi_rad = math.acos(cos_phi) if cos_phi > 1e-12 else self.PI/2  # 避免acos(0)的精度问题
        phi_deg = math.degrees(phi_rad)

        # 7. 采光系数k（仅当phi<90°时有效）
        k = cos_phi if phi_deg < 90 else 0.0

        return {
            'phi_rad': phi_rad, 'phi_deg': phi_deg,
            'k': k
        }

    def calculate_single_wall_shading(self, date_time, wall_az_deg, H=6.0, l=1.0, theta_deg=30.0):
        """
        完全遵循公式：fs = [l * cos(phi - theta)] / (k * H)
        """
        # 1. 基础判断：太阳未升起，无遮阳
        sun_data = self.calculate_sun_position(date_time)
        sun_alt_deg = sun_data['alt_deg']
        if sun_alt_deg <= 0:
            return {'shading_ratio': 0.0, 'k': 0.0, 'phi_deg': 0.0}

        # 2. 计算phi（入射夹角）和k（采光系数）
        phi_k_data = self.calculate_phi_k(sun_data, wall_az_deg)
        phi_rad = phi_k_data['phi_rad']
        k = phi_k_data['k']
        if k < 1e-6:  # 避免分母为0
            return {'shading_ratio': 0.0, 'k': k, 'phi_deg': phi_k_data['phi_deg']}

        # 3. 转换theta为弧度（与phi单位统一）
        theta_rad = theta_deg * self.RAD

        # 4. 公式分子：l * cos(phi - theta)
        cos_phi_theta = math.cos(phi_rad - theta_rad)
        cos_phi_theta = max(cos_phi_theta, 0.0)  # 非负约束
        numerator = l * cos_phi_theta

        # 5. 公式分母：k * H
        denominator = k * H + 1e-12  # 避免分母为0

        # 6. 计算遮阳率fs
        fs = numerator / denominator

        # 7. 物理约束：遮阳率取值[0,1]
        fs = max(min(fs, 1.0), 0.0)

        return {
            'shading_ratio': round(fs, 4),
            'k': round(k, 4),
            'phi_deg': round(phi_k_data['phi_deg'], 2),
            'cos_phi_theta': round(cos_phi_theta, 4)
        }

    def calculate_single_wall_indoor_ill(self, date_time, wall_az_deg, H=6.0, l=1.0, theta_deg=30.0):
        sun_data = self.calculate_sun_position(date_time)
        sun_alt_deg = sun_data['alt_deg']
        if sun_alt_deg <= 0:
            return 0.0

        # 计算遮阳率
        shade_data = self.calculate_single_wall_shading(date_time, wall_az_deg, H, l, theta_deg)
        fs = shade_data['shading_ratio']
        k = shade_data['k']

        # 真实室外基准照度 + 合理衰减系数
        E_horiz = 80000.0
        atm_att = pow(math.e, -0.13 / (math.sin(sun_data['alt_rad']) + 1e-12))  # 避免除0
        E_wall = E_horiz * k * atm_att

        # 玻璃透射 + 窗墙比 + 室内利用系数
        tau_glass = 0.75
        indoor_util = 0.045
        E_in = E_wall * (1 - fs) * tau_glass * self.window_wall_ratio * indoor_util

        return round(float(max(E_in, 0.0)), 2)

    def calculate_total_indoor_illuminance(self, date_time, H=6.0, l=1.0, theta_deg=30.0):
        total_ill = 0.0
        ill_list = []
        shade_list = []
        k_list = []

        for wall_az in self.wall_azimuths:
            # 单墙面照度
            ein = self.calculate_single_wall_indoor_ill(date_time, wall_az, H, l, theta_deg)
            # 单墙面遮阳率
            shade_data = self.calculate_single_wall_shading(date_time, wall_az, H, l, theta_deg)
            fs = shade_data['shading_ratio']

            ill_list.append(ein)
            shade_list.append(fs)
            k_list.append(shade_data['k'])
            total_ill += ein

        return round(total_ill, 2), ill_list, shade_list, k_list

    def get_24h_data(self, H=6.0, l=1.0, theta_deg=30.0):
        times, totals, avg_shades, avg_ks = [], [], [], []
        all_wall_ills = []
        for h in range(24):
            dt = datetime(2025, 11, 1, h, 0, 0)
            etot, ill_list, fss, ks = self.calculate_total_indoor_illuminance(dt, H, l, theta_deg)
            times.append(f"{h:02d}:00")
            totals.append(etot)
            avg_shades.append(round(np.mean(fss), 4))
            avg_ks.append(round(np.mean(ks), 4))
            all_wall_ills.append(ill_list)
        return times, totals, avg_shades, avg_ks, all_wall_ills

    def calculate_24h_avg_ill(self, H=6.0, l=1.0, theta_deg=30.0):
        """计算24小时所有墙面的平均照度"""
        _, _, _, _, all_wall_ills = self.get_24h_data(H, l, theta_deg)
        flat_ills = [ill for hour_ills in all_wall_ills for ill in hour_ills]
        avg_24h = np.mean(flat_ills) if flat_ills else 0.0
        return round(avg_24h, 2)

    def plot_24h_ill_shading(self, H=6.0, l=1.0, theta_deg=30.0, target_avg=300.0):
        tl, totals, avg_sh, avg_ks, _ = self.get_24h_data(H, l, theta_deg)
        fig, ax1 = plt.subplots(figsize=(15, 7))

        # 总照度
        ax1.plot(tl, totals, 'r-o', lw=2.5, ms=4, label='总室内照度')
        target_total = target_avg * self.n_walls
        ax1.axhline(target_total, c='k', ls='--', lw=2, label=f'目标总照度 {target_total:.0f} lx')
        ax1.axvline('12:00', c='orange', ls=':', lw=2, label='正午')
        ax1.set_ylabel('总照度 (lx)', color='r')
        ax1.tick_params(axis='y', labelcolor='r')
        ax1.set_ylim(0, max(totals) * 1.2 if totals else 800)
        ax1.grid(alpha=0.3)

        # 遮阳率
        ax2 = ax1.twinx()
        ax2.plot(tl, avg_sh, 'b-s', lw=2.5, ms=4, label='平均遮阳率')
        ax2.set_ylabel('遮阳率 / 采光系数k', color='b')
        ax2.tick_params(axis='y', labelcolor='b')
        ax2.set_ylim(0, 1)

        # 采光系数k
        ax2.plot(tl, avg_ks, 'g-.^', lw=2, ms=4, label='平均采光系数k')

        # 合并图例
        lines1, labels1 = ax1.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
        plt.title(f'{self.n_walls}边形 24h总照度 + 平均遮阳率（公式：fs=l·cos(φ-θ)/(k·H)）')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.show()

    def plot_noon_shading(self, H=6.0, l=1.0, theta_deg=30.0):
        """正午各墙面遮阳率、k值对比"""
        noon = datetime(2025, 11, 1, 12, 0, 0)
        _, _, fss, ks = self.calculate_total_indoor_illuminance(noon, H, l, theta_deg)
        wall_labels = [f'墙{i+1}\n({az}°)' for i, az in enumerate(self.wall_azimuths)]

        # 双柱状图对比
        fig, ax1 = plt.subplots(figsize=(12, 6))
        x = np.arange(len(wall_labels))
        width = 0.35

        # 遮阳率
        bars1 = ax1.bar(x - width/2, fss, width, color='steelblue', edgecolor='k', label='遮阳率fs')
        ax1.set_ylabel('遮阳率fs', color='steelblue')
        ax1.tick_params(axis='y', labelcolor='steelblue')
        ax1.set_ylim(0, 1)

        # 采光系数k
        ax2 = ax1.twinx()
        bars2 = ax2.bar(x + width/2, ks, width, color='lightgreen', edgecolor='k', label='采光系数k')
        ax2.set_ylabel('采光系数k', color='darkgreen')
        ax2.tick_params(axis='y', labelcolor='darkgreen')
        ax2.set_ylim(0, 1)

        # 标注数值
        for bar, val in zip(bars1, fss):
            plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.02, f'{val:.3f}', ha='center', fontsize=9)
        for bar, val in zip(bars2, ks):
            plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.02, f'{val:.3f}', ha='center', fontsize=9)

        # 配置图表
        ax1.set_xticks(x)
        ax1.set_xticklabels(wall_labels)
        ax1.grid(axis='y', alpha=0.3)
        plt.title(f'正午各墙面遮阳率fs & 采光系数k（公式：fs=l·cos(φ-θ)/(k·H)）')

        # 合并图例
        lines1, labels1 = ax1.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper right')
        plt.tight_layout()
        plt.show()

class EdgeCountGA:
    """仅优化建筑边数n的遗传算法"""
    def __init__(self, lat, lng, target_avg=300.0, 
                 fixed_l=1.0, fixed_theta=30.0, fixed_wwr=0.45, H=6.0):
        self.lat = lat
        self.lng = lng
        self.target_avg = target_avg  # 全天各墙面照度平均值目标
        self.H = H

        # 固定参数（仅优化边数）
        self.fixed_l = fixed_l          # 遮阳板长度
        self.fixed_theta = fixed_theta  # 遮阳板角度
        self.fixed_wwr = fixed_wwr      # 窗墙比

        # 边数优化范围
        self.n_min = 3
        self.n_max = 100  # 最大边数可根据需求调整

        # 遗传算法参数（适配单变量优化）
        self.pop_size = 40    # 种群规模
        self.gen_max = 80     # 最大迭代次数
        self.p_cross = 0.7    # 交叉概率
        self.p_mut = 0.15     # 变异概率
        self.elite_ratio = 0.1# 精英保留比例

        # 收敛判定
        self.conv_thresh = 0.01  # 代价函数小于该值则收敛
        self.conv_stable = 15    # 连续稳定代数

        # 历史记录
        self.history_gen = []
        self.history_best_J = []
        self.history_best_n = []

    def _fitness(self, n):
        """代价函数：照度平均值与目标的相对偏差"""
        try:
            wall_azs = generate_regular_polygon_wall_azimuths(n)
        except:
            return 1e9  # 无效边数，惩罚
        
        calc = SunIlluminanceCalculator(self.lat, self.lng, wall_azs, self.fixed_wwr)
        avg_ill = calc.calculate_24h_avg_ill(self.H, self.fixed_l, self.fixed_theta)
        
        # 相对偏差（越小越好）
        J = abs(avg_ill - self.target_avg) / self.target_avg
        return max(J, 0.0)

    def _init_pop(self):
        """初始化种群：仅包含边数n"""
        pop = [random.randint(self.n_min, self.n_max) for _ in range(self.pop_size)]
        return pop

    def _select(self, pop, fitness_list):
        """精英保留 + 轮盘赌选择"""
        # 精英保留
        elite_num = max(1, int(self.pop_size * self.elite_ratio))
        sorted_pairs = sorted(zip(pop, fitness_list), key=lambda x: x[1])
        elite = [p[0] for p in sorted_pairs[:elite_num]]

        # 轮盘赌选择剩余个体（适应度越高，选中概率越大）
        rest_pop = [p[0] for p in sorted_pairs]
        rest_fitness = [p[1] for p in sorted_pairs]
        
        # 转换为选择权重（越小的代价，权重越大）
        max_fit = max(rest_fitness) + 1e-8
        weights = [max_fit - f for f in rest_fitness]
        weight_sum = sum(weights) + 1e-8
        probs = [w / weight_sum for w in weights]

        # 选择剩余个体
        rest = []
        while len(rest) < self.pop_size - elite_num:
            rest.append(random.choices(rest_pop, weights=probs, k=1)[0])
        
        return elite + rest

    def _cross(self, a, b):
        """交叉：单变量交叉（随机选择父代）"""
        if random.random() > self.p_cross:
            return a
        return a if random.random() > 0.5 else b

    def _mutate(self, n):
        """变异：随机增减1~3，约束在范围内"""
        if random.random() > self.p_mut:
            return n
        
        delta = random.choice([-3, -2, -1, 1, 2, 3])
        new_n = n + delta
        return max(self.n_min, min(self.n_max, new_n))

    def optimize(self):
        """执行边数优化"""
        # 初始化种群
        pop = self._init_pop()
        best_n = None
        best_J = 1e9

        print("=" * 80)
        print(f"仅优化边数n | 目标全天平均照度：{self.target_avg} lx")
        print(f"固定参数：l={self.fixed_l}m, theta={self.fixed_theta}°, wwr={self.fixed_wwr}")
        print("=" * 80)
        print(f"{'迭代':<5}{'最优n':<8}{'最优代价J':<12}{'平均代价J':<12}")
        print("-" * 80)

        stable_count = 0  # 收敛稳定计数
        for gen in range(self.gen_max):
            # 计算适应度
            fitness_list = [self._fitness(n) for n in pop]
            curr_best_J = min(fitness_list)
            curr_best_n = pop[np.argmin(fitness_list)]
            curr_avg_J = np.mean(fitness_list)

            # 更新全局最优
            if curr_best_J < best_J:
                best_J = curr_best_J
                best_n = curr_best_n
                stable_count = 0  # 最优值变化，重置稳定计数
            else:
                stable_count += 1

            # 记录历史
            self.history_gen.append(gen+1)
            self.history_best_J.append(curr_best_J)
            self.history_best_n.append(curr_best_n)

            # 打印进度
            if gen % 5 == 0 or gen == self.gen_max-1 or stable_count >= self.conv_stable:
                print(f"{gen+1:<5}{curr_best_n:<8}{curr_best_J:<12.5f}{curr_avg_J:<12.5f}")

            # 收敛判定
            if curr_best_J <= self.conv_thresh or stable_count >= self.conv_stable:
                print(f"\n→ 迭代{gen+1}代收敛！最优边数n={best_n}，代价J={best_J:.5f}")
                break

            # 生成下一代
            sel_pop = self._select(pop, fitness_list)
            new_pop = []
            while len(new_pop) < self.pop_size:
                a = random.choice(sel_pop)
                b = random.choice(sel_pop)
                child = self._cross(a, b)
                child = self._mutate(child)
                new_pop.append(child)
            pop = new_pop

        # 结果汇总
        if best_n is None:
            best_n = 4  # 默认值
            best_J = self._fitness(best_n)
        
        # 计算最优边数下的详细结果
        wall_azs_opt = generate_regular_polygon_wall_azimuths(best_n)
        calc_opt = SunIlluminanceCalculator(self.lat, self.lng, wall_azs_opt, self.fixed_wwr)
        avg_ill_opt = calc_opt.calculate_24h_avg_ill(self.H, self.fixed_l, self.fixed_theta)

        print("=" * 80)
        print("优化结果汇总：")
        print(f"最优边数n：{best_n}")
        print(f"最优边数下的全天平均照度：{avg_ill_opt:.2f} lx（目标：{self.target_avg} lx）")
        print(f"相对偏差：{best_J:.5f}")
        print("=" * 80)

        # 绘制优化过程
        self._plot_optimization()

        return best_n, best_J, avg_ill_opt

    def _plot_optimization(self):
        """绘制边数优化过程"""
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), sharex=True)

        # 代价函数变化
        ax1.plot(self.history_gen, self.history_best_J, 'r-o', lw=2, label='最优代价J')
        ax1.axhline(self.conv_thresh, c='k', ls='--', label='收敛阈值')
        ax1.set_ylabel('代价函数J（相对偏差）', color='r')
        ax1.tick_params(axis='y', labelcolor='r')
        ax1.grid(alpha=0.3)
        ax1.legend()

        # 最优边数变化
        ax2.plot(self.history_gen, self.history_best_n, 'b-s', lw=2, label='最优边数n')
        ax2.set_xlabel('迭代次数')
        ax2.set_ylabel('最优边数n', color='b')
        ax2.tick_params(axis='y', labelcolor='b')
        ax2.grid(alpha=0.3)
        ax2.legend()

        plt.suptitle('边数n优化过程（仅优化边数，固定遮阳/窗墙比）')
        plt.tight_layout()
        plt.show()

# ===================== 测试代码 =====================
if __name__ == "__main__":
    # 示例：北京纬度39.9°，经度116.4°，目标全天平均照度300lx
    lat = 39.9
    lng = 116.4
    target_avg = 300.0

    # 初始化边数优化器
    ga = EdgeCountGA(
        lat=lat, lng=lng, 
        target_avg=target_avg,
        fixed_l=0, fixed_theta=0, fixed_wwr=0.45
    )

    # 执行优化
    best_n, best_J, avg_ill_opt = ga.optimize()

    # 验证最优边数的照度/遮阳效果
    wall_azs_opt = generate_regular_polygon_wall_azimuths(best_n)
    calc_opt = SunIlluminanceCalculator(lat, lng, wall_azs_opt, 0.45)
    calc_opt.plot_24h_ill_shading(target_avg=target_avg)
    calc_opt.plot_noon_shading()