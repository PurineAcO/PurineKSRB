import math
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
import numpy as np
import random

# ===================== 字体配置 =====================
plt.rcParams['font.sans-serif'] = ['SimHei']    # 用黑体显示中文
plt.rcParams['axes.unicode_minus'] = False      # 正常显示负号
# ====================================================

class SunIlluminanceCalculator:
    def __init__(self, lat: float, lng: float):
        self.lat = lat  # 纬度（北纬为正）
        self.lng = lng  # 经度（东经为正）
        self.PI = math.pi
        self.RAD = self.PI / 180.0
        self.I_sc = 1367.0
        self.EARTH_OBLIQUITY = 23.4397 * self.RAD  # 黄赤交角
        self.J1970 = 2440588.0
        self.J2000 = 2451545.0
        self.DAY_MS = 1000 * 60 * 60 * 24

    def _to_julian(self, dt):
        """将datetime转换为儒略日"""
        epoch = datetime(1970, 1, 1)
        delta = dt - epoch
        julian = self.J1970 + delta.total_seconds() / 86400.0
        return julian

    def calculate_sun_position(self, date_time):
        dt = date_time
        julian = self._to_julian(dt)
        days = julian - self.J2000
        
        mean_longitude = (280.46646 + days * 0.98560028) % 360
        mean_anomaly = (357.52911 + days * 0.98560028) % 360
        ecliptic_longitude = mean_longitude + 1.914602 * math.sin(self.RAD * mean_anomaly)
        ecliptic_longitude_rad = self.RAD * ecliptic_longitude
        
        declination = math.asin(math.sin(self.EARTH_OBLIQUITY) * math.sin(ecliptic_longitude_rad))
        
        local_time = dt.hour + dt.minute/60 + dt.second/3600
        hour_angle = (local_time - 12) * 15
        hour_angle_rad = self.RAD * hour_angle
        
        lat_rad = self.RAD * self.lat
        sin_altitude = (math.sin(lat_rad) * math.sin(declination) + 
                        math.cos(lat_rad) * math.cos(declination) * math.cos(hour_angle_rad))
        altitude = math.asin(max(min(sin_altitude, 1.0), -1.0))
        
        cos_azimuth = (math.sin(declination) - math.sin(lat_rad) * math.sin(altitude)) / (
            math.cos(lat_rad) * math.cos(altitude)
        )
        cos_azimuth = max(min(cos_azimuth, 1.0), -1.0)
        azimuth = math.acos(cos_azimuth)
        
        if hour_angle > 0:
            azimuth = 2 * self.PI - azimuth
        
        return {
            'azimuth_deg': math.degrees(azimuth),
            'altitude_deg': math.degrees(altitude)
        }

    def calculate_wall_light_coef(self, date_time, wall):
        sun_pos = self.calculate_sun_position(date_time)
        sun_azimuth = sun_pos['azimuth_deg']
        sun_altitude = sun_pos['altitude_deg']
        
        wall_normal_azimuth = {
            'east': 90,
            'south': 0,
            'west': -90,
            'north': 180
        }[wall]
        
        horizontal_angle = abs(sun_azimuth - wall_normal_azimuth)
        horizontal_angle = min(horizontal_angle, 360 - horizontal_angle)
        
        phi_rad = math.atan2(
            math.sin(self.RAD * horizontal_angle) * math.cos(self.RAD * sun_altitude),
            math.sin(self.RAD * sun_altitude)
        )
        phi_deg = math.degrees(phi_rad)
        
        k = math.cos(self.RAD * phi_deg) if sun_altitude > 0 else 0.0
        k = max(k, 0.0)
        
        return {
            'k': k,
            'phi_deg': phi_deg,
            'sun_azimuth': sun_azimuth,
            'sun_altitude': sun_altitude
        }

    def calculate_shading_params(self, date_time, wall, H=6.0, l=1.0, theta_deg=30.0):
        wall_coef = self.calculate_wall_light_coef(date_time, wall)
        k = wall_coef['k']
        phi_deg = wall_coef['phi_deg']
        
        k_safe = max(k, 1e-6)
        
        theta_rad = self.RAD * theta_deg
        phi_rad = self.RAD * phi_deg
        numerator = l * math.cos(phi_rad - theta_rad)
        term = numerator / k_safe
        
        shading_ratio = term / H
        shading_ratio = max(min(shading_ratio, 1.0), 0.0)
        
        return {
            'shading_ratio': shading_ratio,
            'phi_deg': phi_deg,
            'theta_deg': theta_deg,
            'term': term,
            'k': k
        }

    def calculate_indoor_illuminance(self, date_time, wall, shading_ratio):
        """
        最终版：适配10×10m教室 + 雷克雅未克地区的室内天然光照度计算
        仅聚焦照度，无温度相关逻辑
        返回：室内工作面平均照度，单位 lx（勒克斯）
        """
        wall_coef = self.calculate_wall_light_coef(date_time, wall)
        sun_altitude = wall_coef['sun_altitude']  # 太阳高度角，度
        k = wall_coef['k']                         # 墙面采光系数（角度投影，适配南侧窗）

        # 太阳高度≤0（夜间/极夜），无天然光，照度为0
        if sun_altitude <= 0:
            return 0.0

        # -------------- 10×10m教室 + 雷克雅未克 专属参数 --------------
        E_horizon_max = 60000.0        # 雷克雅未克晴天正午室外水平面最大照度，保守取值
        C_sky = 0.65                   # 雷克雅未克大气/天空修正系数（多阴雨、雾，透明度差）
        tau_glass = 0.70               # 双层中空清玻璃透射比（含轻微脏污/老化折减）
        window_floor_ratio = 0.12      # 窗地面积比（10×10m教室，南侧窗12㎡ / 地面100㎡）
        CU = 0.40                      # 光利用系数（单侧采光，教室有桌椅遮挡，保守取值）
        # -------------------------------------------------------------

        # 计算太阳高度角正弦值（立面采光有效入射角修正）
        sin_h = math.sin(self.RAD * sun_altitude)
        
        # 步骤1：计算室外入射到教室墙面（窗面）的有效照度
        E_wall = E_horizon_max * sin_h * C_sky * k
        
        # 步骤2：计算室内工作面平均照度（透过玻璃+室内传导+遮阳遮挡）
        E_in = E_wall * tau_glass * window_floor_ratio * CU * (1 - shading_ratio)
        
        # 仅约束非负
        E_in = max(float(E_in), 0.0)
        
        return round(E_in, 2)

    def calculate_J_south(self, date_time, H=6.0, l=1.0, theta_deg=30.0):
        """
        专门为南墙定义J值：聚焦南墙正午12点照度与300 lx的接近程度
        J越小，说明南墙照度越接近300 lx，优化效果越好
        """
        wall = 'south'  # 强制聚焦南墙
        # 强制提取当前日期的正午12点（南墙采光最大值关键时间点）
        noon_time = date_time.replace(hour=12, minute=0, second=0)
        
        # 计算南墙正午12点的遮阳率和照度
        shading_params = self.calculate_shading_params(noon_time, wall, H, l, theta_deg)
        shading_ratio = shading_params['shading_ratio']
        indoor_ill = self.calculate_indoor_illuminance(noon_time, wall, shading_ratio)
        
        # 重新定义J值（核心优化目标：仅针对南墙）
        target_ill = 300.0  # 目标照度
        if indoor_ill < target_ill:
            # 低于300 lx，给予大幅惩罚（J值快速增大），引导算法优先保证不低于目标
            J = (target_ill - indoor_ill) / target_ill * 10.0
        else:
            # 高于300 lx，小幅惩罚（J值随偏离程度缓慢增大），引导算法向300 lx收敛
            J = (indoor_ill - target_ill) / target_ill
        
        # 约束J值非负，保留6位小数
        J = max(round(J, 6), 0.0)
        
        return {
            'datetime': noon_time.strftime("%Y-%m-%d %H:%M:%S"),
            'wall': wall,
            'J': J,
            'shading_ratio': shading_ratio,
            'indoor_illuminance': round(indoor_ill, 2),
            'phi_deg': shading_params['phi_deg'],
            'theta_deg': theta_deg,
            'l': l
        }

    # ========== 新增：获取南墙24小时完整照度数据（突出核心优化对象） ==========
    def get_south_wall_24h_data(self, target_date, H=6.0, l=1.0, theta_deg=30.0):
        """
        专门获取南墙一天24小时的室内光强、遮阳率数据
        """
        wall = 'south'
        times = []
        time_labels = []
        illuminances = []
        shading_ratios = []
        
        # 遍历0:00到23:00，每小时一个数据点
        for hour in range(24):
            current_time = target_date.replace(hour=hour, minute=0, second=0)
            times.append(current_time)
            time_labels.append(f"{hour:02d}:00")
            
            # 计算当前时间的遮阳率和照度
            shading_params = self.calculate_shading_params(current_time, wall, H, l, theta_deg)
            shading_ratio = shading_params['shading_ratio']
            indoor_ill = self.calculate_indoor_illuminance(current_time, wall, shading_ratio)
            
            # 存入数据列表
            illuminances.append(indoor_ill)
            shading_ratios.append(shading_ratio)
        
        return {
            'time_labels': time_labels,
            'illuminances': illuminances,  # 南墙24小时室内光强
            'shading_ratios': shading_ratios
        }
    
    # ========== 绘制南墙光强24小时变化图（突出核心优化效果） ==========
    def plot_south_wall_24h_illuminance(self, target_date, H=6.0, l=1.0, theta_deg=30.0):
        wall = 'south'
        wall_24h_data = self.get_south_wall_24h_data(target_date, H, l, theta_deg)
        
        plt.figure(figsize=(16, 8))
        
        # 绘制南墙24小时光强（突出显示）
        plt.plot(wall_24h_data['time_labels'], wall_24h_data['illuminances'],
                 color='red', marker='s', markersize=6, linewidth=3,
                 label=f'{wall.upper()} 墙面（核心优化对象）')
        
        # 图表美化：突出300 lx目标阈值
        plt.axhline(y=300, color='black', linestyle='--', alpha=0.8, linewidth=2, label='目标照度（300 lx）')
        # 标注正午12点（最大值点）
        plt.axvline(x='12:00', color='orange', linestyle=':', linewidth=2, alpha=0.7, label='正午12点（采光最大值）')
        plt.xlabel('时间（24小时）', fontsize=14)
        plt.ylabel('室内光强（lx，勒克斯）', fontsize=14)
        plt.title(f'{target_date.strftime("%Y年%m月%d日")} 南墙室内光强24小时变化趋势（目标：接近300 lx）', fontsize=16)
        plt.grid(True, alpha=0.3)
        plt.legend(loc='best', fontsize=12)
        
        # 调整x轴标签，避免重叠
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        
        # 显示图表
        plt.show()

# ===================== 遗传算法优化模块（仅聚焦南墙照度优化） =====================
class GeneticAlgorithmOptimizer:
    def __init__(self, calculator, target_date, H=6.0):
        self.calc = calculator
        self.target_date = target_date
        self.H = H
        
        # 参数范围：l∈[1.0, 1.5]m，θ∈[0.0, 90.0]°（你当前设定的范围）
        self.l_min, self.l_max = 0.5, 0.55
        self.theta_min, self.theta_max = 0.0, 90.0
        
        # 遗传算法超参数
        self.pop_size = 50
        self.generations = 100
        self.crossover_rate = 0.8
        self.mutation_rate = 0.1
        self.elitism_rate = 0.1
        
        # 收敛配置
        self.print_interval = 10
        self.converge_threshold = 0.01  # J值≤0.01即认为南墙照度接近300 lx
        self.converge_stable_gens = 20
        self.converge_tol = 1e-6
        
        # 收敛曲线数据
        self.gen_history = []
        self.best_J_history = []
        self.avg_J_history = []

    def _init_population(self):
        population = []
        for _ in range(self.pop_size):
            l = random.uniform(self.l_min, self.l_max)
            theta = random.uniform(self.theta_min, self.theta_max)
            population.append((l, theta))
        return population

    def _fitness(self, individual):
        """
        适应度计算：仅基于南墙的J值，J越小，适应度越高（聚焦核心优化对象）
        """
        l, theta_deg = individual
        # 仅计算南墙的J值，不再兼顾东、西墙
        south_j_res = self.calc.calculate_J_south(
            date_time=self.target_date,
            H=self.H,
            l=l,
            theta_deg=theta_deg
        )
        south_J = south_j_res['J']
        
        # 适应度值：倒数关系（J越小，适应度越高），避免除零
        return 1.0 / (south_J + 1e-8), south_J

    def _selection(self, population, fitness_scores):
        elite_size = int(self.pop_size * self.elitism_rate)
        elite_indices = np.argsort(fitness_scores)[::-1][:elite_size]
        elite_individuals = [population[i] for i in elite_indices]
        
        remaining_size = self.pop_size - elite_size
        total_fitness = sum(fitness_scores)
        probabilities = [score / total_fitness for score in fitness_scores]
        
        selected_individuals = []
        for _ in range(remaining_size):
            idx = np.random.choice(len(population), p=probabilities)
            selected_individuals.append(population[idx])
        
        return elite_individuals + selected_individuals

    def _crossover(self, parent1, parent2):
        if random.random() > self.crossover_rate:
            return parent1
        
        l1, theta1 = parent1
        l2, theta2 = parent2
        
        alpha = random.uniform(0, 1)
        child_l = alpha * l1 + (1 - alpha) * l2
        child_theta = alpha * theta1 + (1 - alpha) * theta2
        
        # 约束参数范围
        child_l = max(min(child_l, self.l_max), self.l_min)
        child_theta = max(min(child_theta, self.theta_max), self.theta_min)
        
        return (child_l, child_theta)

    def _mutation(self, individual):
        l, theta_deg = individual
        
        if random.random() < self.mutation_rate:
            l += random.gauss(0, 0.05)
            l = max(min(l, self.l_max), self.l_min)
        
        if random.random() < self.mutation_rate:
            theta_deg += random.gauss(0, 1.0)
            theta_deg = max(min(theta_deg, self.theta_max), self.theta_min)
        
        return (l, theta_deg)

    def _check_convergence(self):
        if len(self.best_J_history) > 0 and self.best_J_history[-1] <= self.converge_threshold:
            return True, f"南墙J值({self.best_J_history[-1]:.6f})≤收敛阈值({self.converge_threshold})，接近目标照度300 lx"
        
        if len(self.best_J_history) >= self.converge_stable_gens:
            recent_J = self.best_J_history[-self.converge_stable_gens:]
            max_change = max(recent_J) - min(recent_J)
            if max_change <= self.converge_tol:
                return True, f"连续{self.converge_stable_gens}代南墙J值变化量({max_change:.8f})≤容忍度({self.converge_tol})，趋于稳定"
        
        return False, ""

    def _plot_convergence_curve(self):
        plt.figure(figsize=(12, 6))
        
        plt.plot(self.gen_history, self.best_J_history, 'r-', linewidth=2, marker='o', markersize=4, label='每代最优南墙J值（越小越接近300 lx）')
        plt.plot(self.gen_history, self.avg_J_history, 'b--', linewidth=1.5, marker='s', markersize=3, label='每代平均南墙J值')
        
        plt.axhline(y=self.converge_threshold, color='g', linestyle=':', linewidth=2, label=f'收敛阈值({self.converge_threshold})')
        if len(self.best_J_history) > 0:
            plt.scatter(self.gen_history[-1], self.best_J_history[-1], color='red', s=100, zorder=5, label='终止点')
        
        plt.xlabel('进化代次', fontsize=12)
        plt.ylabel('南墙J值（越低越优，接近300 lx）', fontsize=12)
        plt.title('遗传算法南墙照度优化收敛曲线（目标：南墙照度接近300 lx）', fontsize=14)
        plt.grid(True, alpha=0.3)
        plt.legend(loc='best', fontsize=10)
        plt.xlim(0, max(self.gen_history) + 5)
        
        plt.tight_layout()
        plt.show()

    def optimize(self):
        population = self._init_population()
        best_individual = None
        best_J = float('inf')  # 仅记录南墙的最优J值
        stable_count = 0
        
        print("="*80)
        print("============= 遗传算法南墙照度优化开始（目标：接近300 lx） =============")
        print("="*80)
        print(f"优化目标：南墙正午12点采光最大值尽可能接近300 lx（优先不低于目标）")
        print(f"参数范围：l∈[{self.l_min}, {self.l_max}]m，θ∈[{self.theta_min}, {self.theta_max}]°")
        print(f"超参数：种群大小={self.pop_size}，最大迭代={self.generations}，间隔输出={self.print_interval}代")
        print(f"收敛条件：1. 南墙J值≤{self.converge_threshold}  2. 连续{self.converge_stable_gens}代变化≤{self.converge_tol}")
        print("="*80)
        print(f"{'代次':<6} {'最优l(m)':<10} {'最优θ(°)':<10} {'最优南墙J值':<15} {'平均南墙J值':<15} {'状态':<20}")
        print("-"*80)
        
        for gen in range(self.generations):
            fitness_scores = []
            j_values = []
            
            for ind in population:
                fit, j_val = self._fitness(ind)
                fitness_scores.append(fit)
                j_values.append(j_val)
            
            current_best_J = min(j_values)
            current_avg_J = np.mean(j_values)
            current_best_idx = np.argmin(j_values)
            current_best_ind = population[current_best_idx]
            
            self.gen_history.append(gen+1)
            self.best_J_history.append(current_best_J)
            self.avg_J_history.append(current_avg_J)
            
            if current_best_J < best_J:
                best_individual = current_best_ind
                best_J = current_best_J
                stable_count = 0
            else:
                stable_count += 1
            
            if (gen+1) % self.print_interval == 0 or gen == 0 or gen == self.generations-1:
                status = "迭代中"
                if current_best_J <= self.converge_threshold:
                    status = "接近目标"
                elif stable_count >= self.converge_stable_gens:
                    status = "趋于稳定"
                print(f"{gen+1:<6} {current_best_ind[0]:<10.2f} {current_best_ind[1]:<10.2f} {current_best_J:<15.6f} {current_avg_J:<15.6f} {status:<20}")
            
            converge_flag, converge_reason = self._check_convergence()
            if converge_flag:
                print("-"*80)
                print(f"第{gen+1}代满足收敛条件，提前终止迭代！")
                print(f"收敛原因：{converge_reason}")
                break
            
            selected_pop = self._selection(population, fitness_scores)
            next_population = []
            
            elite_size = int(self.pop_size * self.elitism_rate)
            next_population.extend(selected_pop[:elite_size])
            
            for i in range(elite_size, self.pop_size):
                parent1 = random.choice(selected_pop)
                parent2 = random.choice(selected_pop)
                child = self._crossover(parent1, parent2)
                child = self._mutation(child)
                next_population.append(child)
            
            population = next_population
        
        print("-"*80)
        print("============= 遗传算法南墙照度优化完成 =============")
        print(f"最优参数：l={best_individual[0]:.2f}m，θ={best_individual[1]:.2f}°")
        print(f"最优南墙J值：{best_J:.6f}（越接近0，说明南墙照度越接近300 lx）")
        print(f"迭代终止代次：{len(self.gen_history)}代")
        print("="*80)
        
        self._plot_convergence_curve()
        
        # 计算最优参数下的南墙正午照度，强化验证优化效果
        south_j_res = self.calc.calculate_J_south(
            date_time=self.target_date,
            H=self.H,
            l=best_individual[0],
            theta_deg=best_individual[1]
        )
        south_noon_ill = south_j_res['indoor_illuminance']
        print(f"\n【优化效果验证】：南墙正午12点照度 = {south_noon_ill:.2f} lx（目标：300 lx）")
        
        return {
            'best_l': round(best_individual[0], 2),
            'best_theta': round(best_individual[1], 2),
            'best_south_J': round(best_J, 6),
            'south_noon_ill': round(south_noon_ill, 2),
            'converge_generation': len(self.gen_history)
        }

# ===================== 测试代码（仅聚焦南墙照度优化与可视化） =====================
if __name__ == "__main__":
    # 雷克雅未克正确坐标
    calc = SunIlluminanceCalculator(lat=64.13, lng=-21.82)
    # 目标日期：春分（3月22日），可替换为夏至（6月22日）、冬至（12月22日）
    target_date = datetime(2025, 10, 1)
    H = 6.0
    
    # 遗传算法优化（仅聚焦南墙）
    ga_optimizer = GeneticAlgorithmOptimizer(
        calculator=calc,
        target_date=target_date,
        H=H
    )
    optimal_result = ga_optimizer.optimize()
    
    # 南墙24小时光强可视化（最优参数下，突出核心优化效果）
    print(f"\n=====================================")
    print(f"============= 南墙24小时光强可视化 =============")
    print(f"=====================================")
    calc.plot_south_wall_24h_illuminance(
        target_date=target_date,
        H=H,
        l=optimal_result['best_l'],
        theta_deg=optimal_result['best_theta']
    )