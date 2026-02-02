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
        
        # 初始化温度数据（有日照/无日照，单位：℃）
        self._init_temperature_data()

    def _init_temperature_data(self):
        # 有日照时的温度（24小时）
        data_sun = np.array([
            296.0163007, 296.7024689, 296.9093501, 297.0639341, 297.5276481, 298.0179310,
            298.2261999, 298.9085913, 300.1002298, 300.8662137, 301.4847586, 302.3411005,
            302.5742203, 301.9964721, 301.2625588, 300.8178949, 300.5747770, 299.5839113,
            298.1380237, 297.3855772, 297.1427833, 296.9549780, 296.6360040, 296.0270487
        ])
        self.data_sun_celsius = data_sun - 273.0  # 转℃
        
        # 无日照时的温度（24小时）
        data_no_sun = np.array([
            24.1359699, 24.3986172, 24.5169152, 24.5502761, 24.5581122, 24.5980846,
            24.6597814, 24.6444436, 24.5570502, 24.7283847, 25.4604961, 26.3978844,
            26.9093899, 26.8007342, 26.3158262, 25.6997821, 25.1578972, 24.8514932,
            24.7331920, 24.6886416, 24.6522631, 24.5960635, 24.4930170, 24.3160976
        ])
        self.data_no_sun_celsius = data_no_sun

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

    def calculate_wall_temperature(self, date_time, wall, shading_ratio):
        hour = date_time.hour
        hour = max(0, min(23, hour))
        
        t_sun = self.data_sun_celsius[hour]
        t_no_sun = self.data_no_sun_celsius[hour]
        
        t_wall = t_sun * (1 - shading_ratio) + t_no_sun * shading_ratio
        return round(t_wall, 2)

    def calculate_indoor_illuminance(self, date_time, wall, shading_ratio):
        wall_coef = self.calculate_wall_light_coef(date_time, wall)
        sun_altitude = wall_coef['sun_altitude']
        
        if sun_altitude <= 0:
            base_illuminance = 0.0
        else:
            DNI = 1000 * math.sin(self.RAD * sun_altitude)
            base_illuminance = DNI * wall_coef['k'] * 100000
        
        indoor_illuminance = base_illuminance * (1 - shading_ratio)
        return max(indoor_illuminance, 0.0)

    def calculate_J(self, date_time, wall, H=6.0, l=1.0, theta_deg=30.0):
        shading_params = self.calculate_shading_params(date_time, wall, H, l, theta_deg)
        shading_ratio = shading_params['shading_ratio']
        
        indoor_ill = self.calculate_indoor_illuminance(date_time, wall, shading_ratio)
        wall_temp = self.calculate_wall_temperature(date_time, wall, shading_ratio)
        
        ill_deficit = max(300 - indoor_ill, 0.0) / 300
        temp_excess = max(wall_temp - 23.0, 0.0) / 23.0
        
        J = (1/6) * ill_deficit + (5/6) * temp_excess
        
        return {
            'datetime': date_time.strftime("%Y-%m-%d %H:%M:%S"),
            'wall': wall,
            'J': round(J, 6),
            'shading_ratio': shading_ratio,
            'indoor_illuminance': round(indoor_ill, 2),
            'wall_temperature': wall_temp,
            'phi_deg': shading_params['phi_deg'],
            'theta_deg': theta_deg,
            'l': l
        }

    def generate_three_walls_J(self, target_date, H=6.0, l=1.0, theta_deg=30.0):
        walls = ['east', 'south', 'west']
        sunrise = target_date.replace(hour=7, minute=30)
        sunset = target_date.replace(hour=16, minute=30)
        
        times = []
        current_time = sunrise
        while current_time <= sunset:
            times.append(current_time)
            current_time += timedelta(hours=1)
        time_labels = [t.strftime("%H:%M") for t in times]
        
        all_data = {}
        for wall in walls:
            J_vals = []
            shading_ratios = []
            temps = []
            ill_vals = []
            
            for t in times:
                j_res = self.calculate_J(t, wall, H, l, theta_deg)
                J_vals.append(j_res['J'])
                shading_ratios.append(j_res['shading_ratio'])
                temps.append(j_res['wall_temperature'])
                ill_vals.append(j_res['indoor_illuminance'])
            
            all_data[wall] = {
                'time_labels': time_labels,
                'J_values': J_vals,
                'shading_ratios': shading_ratios,
                'temperatures': temps,
                'illuminances': ill_vals,
                'J_mean': round(np.mean(J_vals), 6),
                'shading_mean': round(np.mean(shading_ratios), 4),
                'temp_mean': round(np.mean(temps), 2)
            }
        
        # 计算三个墙面的J值总均值
        total_J_mean = np.mean([all_data[wall]['J_mean'] for wall in walls])
        
        return all_data, total_J_mean

# ===================== 遗传算法优化模块（对标MATLAB风格 + 约束l≤1.5m + 普通坐标） =====================
class GeneticAlgorithmOptimizer:
    def __init__(self, calculator, target_date, H=6.0):
        self.calc = calculator
        self.target_date = target_date
        self.H = H
        
        # ========== 关键修改1：l范围强制改为 0.5~1.5m，不允许超过1.5m ==========
        self.l_min, self.l_max = 0.5, 1.5
        self.theta_min, self.theta_max = 0.0, 90.0
        
        # 遗传算法超参数
        self.pop_size = 50
        self.generations = 100
        self.crossover_rate = 0.8
        self.mutation_rate = 0.1
        self.elitism_rate = 0.1
        
        # MATLAB风格输出配置
        self.print_interval = 10
        self.converge_threshold = 1e-4
        self.converge_stable_gens = 20
        self.converge_tol = 1e-6
        
        # 收敛曲线数据
        self.gen_history = []
        self.best_J_history = []
        self.avg_J_history = []

    def _init_population(self):
        population = []
        for _ in range(self.pop_size):
            # l 只在 0.5~1.5 之间随机
            l = random.uniform(self.l_min, self.l_max)
            theta = random.uniform(self.theta_min, self.theta_max)
            population.append((l, theta))
        return population

    def _fitness(self, individual):
        l, theta_deg = individual
        _, total_J_mean = self.calc.generate_three_walls_J(
            target_date=self.target_date,
            H=self.H,
            l=l,
            theta_deg=theta_deg
        )
        return 1.0 / (total_J_mean + 1e-8), total_J_mean

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
        
        # 交叉后依旧强制约束范围
        child_l = max(min(child_l, self.l_max), self.l_min)
        child_theta = max(min(child_theta, self.theta_max), self.theta_min)
        
        return (child_l, child_theta)

    def _mutation(self, individual):
        l, theta_deg = individual
        
        if random.random() < self.mutation_rate:
            l += random.gauss(0, 0.05)  # 扰动变小，更贴合1.5m上限
            l = max(min(l, self.l_max), self.l_min)
        
        if random.random() < self.mutation_rate:
            theta_deg += random.gauss(0, 1.0)
            theta_deg = max(min(theta_deg, self.theta_max), self.theta_min)
        
        return (l, theta_deg)

    def _check_convergence(self):
        if len(self.best_J_history) > 0 and self.best_J_history[-1] <= self.converge_threshold:
            return True, f"J值({self.best_J_history[-1]:.6f})≤收敛阈值({self.converge_threshold})，达到目标精度"
        
        if len(self.best_J_history) >= self.converge_stable_gens:
            recent_J = self.best_J_history[-self.converge_stable_gens:]
            max_change = max(recent_J) - min(recent_J)
            if max_change <= self.converge_tol:
                return True, f"连续{self.converge_stable_gens}代J值变化量({max_change:.8f})≤容忍度({self.converge_tol})，趋于稳定"
        
        return False, ""

    def _plot_convergence_curve(self):
        plt.figure(figsize=(12, 6))
        
        plt.plot(self.gen_history, self.best_J_history, 'r-', linewidth=2, marker='o', markersize=4, label='每代最优J值')
        plt.plot(self.gen_history, self.avg_J_history, 'b--', linewidth=1.5, marker='s', markersize=3, label='每代平均J值')
        
        plt.axhline(y=self.converge_threshold, color='g', linestyle=':', linewidth=1, label=f'收敛阈值({self.converge_threshold})')
        if len(self.best_J_history) > 0:
            plt.scatter(self.gen_history[-1], self.best_J_history[-1], color='red', s=100, zorder=5, label='终止点')
        
        plt.xlabel('进化代次', fontsize=12)
        plt.ylabel('J值（越低越舒适）', fontsize=12)
        plt.title('遗传算法优化收敛曲线', fontsize=14)
        plt.grid(True, alpha=0.3)
        plt.legend(loc='best', fontsize=10)
        plt.xlim(0, max(self.gen_history) + 5)
        
        # ========== 关键修改2：彻底删除对数坐标，使用默认线性坐标 ==========
        # plt.yscale('log')  # 已注释，永久关闭对数轴
        
        plt.tight_layout()
        plt.show()

    def optimize(self):
        population = self._init_population()
        best_individual = None
        best_J_mean = float('inf')
        stable_count = 0
        
        print("="*80)
        print("============= 遗传算法优化开始（对标MATLAB风格） =============")
        print("="*80)
        print(f"优化目标：三个墙面J值总均值接近0")
        print(f"参数范围：l∈[{self.l_min}, {self.l_max}]m（强制≤1.5m），θ∈[{self.theta_min}, {self.theta_max}]°")
        print(f"超参数：种群大小={self.pop_size}，最大迭代={self.generations}，间隔输出={self.print_interval}代")
        print(f"收敛条件：1. J值≤{self.converge_threshold}  2. 连续{self.converge_stable_gens}代变化≤{self.converge_tol}")
        print("="*80)
        print(f"{'代次':<6} {'最优l(m)':<10} {'最优θ(°)':<10} {'最优J值':<15} {'平均J值':<15} {'状态':<20}")
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
            
            if current_best_J < best_J_mean:
                best_individual = current_best_ind
                best_J_mean = current_best_J
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
        print("============= 遗传算法优化完成 =============")
        print(f"最优参数：l={best_individual[0]:.2f}m，θ={best_individual[1]:.2f}°")
        print(f"最优J值总均值：{best_J_mean:.6f}（越接近0越优）")
        print(f"迭代终止代次：{len(self.gen_history)}代")
        print("="*80)
        
        self._plot_convergence_curve()
        
        return {
            'best_l': round(best_individual[0], 2),
            'best_theta': round(best_individual[1], 2),
            'best_total_J_mean': round(best_J_mean, 6),
            'converge_generation': len(self.gen_history)
        }

# ===================== 测试代码 =====================
if __name__ == "__main__":
    calc = SunIlluminanceCalculator(lat=13.0, lng=100.0)
    target_date = datetime(2025, 6, 22)
    H = 6.0
    
    ga_optimizer = GeneticAlgorithmOptimizer(
        calculator=calc,
        target_date=target_date,
        H=H
    )
    optimal_result = ga_optimizer.optimize()
    
    print(f"\n=====================================")
    print(f"============= 最优参数可视化 =============")
    print(f"=====================================")
    three_walls_data, _ = calc.generate_three_walls_J(
        target_date=target_date,
        H=H,
        l=optimal_result['best_l'],
        theta_deg=optimal_result['best_theta']
    )
    
    walls = ['east', 'south', 'west']
    colors = {'east': 'blue', 'south': 'red', 'west': 'green'}
    markers = {'east': 'o', 'south': 's', 'west': '^'}
    
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10), sharex=True)
    
    for wall in walls:
        data = three_walls_data[wall]
        ax1.plot(data['time_labels'], data['J_values'], 
                 color=colors[wall], marker=markers[wall], 
                 label=f'{wall.upper()} (均值：{data["J_mean"]})')
    ax1.set_ylabel('J值（越低越舒适）', fontsize=12)
    ax1.set_title(f'夏至日东/南/西墙面J值变化（最优参数：l={optimal_result["best_l"]}m, θ={optimal_result["best_theta"]}°）', fontsize=14)
    ax1.legend(loc='best')
    ax1.grid(True, alpha=0.3)
    ax1.axhline(0, color='black', linestyle='--', alpha=0.5)
    
    for wall in walls:
        data = three_walls_data[wall]
        ax2.plot(data['time_labels'], [s*100 for s in data['shading_ratios']], 
                 color=colors[wall], marker=markers[wall], 
                 label=f'{wall.upper()} (均值：{data["shading_mean"]*100:.1f}%)')
    ax2.set_xlabel('时间', fontsize=12)
    ax2.set_ylabel('遮阳率（%）', fontsize=12)
    ax2.set_title('夏至日东/南/西墙面遮阳率变化', fontsize=14)
    ax2.legend(loc='best')
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(0, 100)
    
    plt.tight_layout()
    plt.show()