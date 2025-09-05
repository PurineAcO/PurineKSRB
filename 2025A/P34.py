import math
import numpy as np
import matplotlib.pyplot as plt
from copy import deepcopy

# 物理参数和原始函数（保持不变）
g = 9.8
alpha = 3000 / math.sqrt(101)
beta = 300 / math.sqrt(101)

def s2e(a, b, c):
    if a == 0 or b**2 - 4*a*c < 0:
        return None
    else:
        delta = math.sqrt(b**2 - 4*a*c)
        x1 = (-b + delta) / (2*a)
        x2 = (-b - delta) / (2*a)
        return x1, x2
    
def MissilePlace(t):
    if 2000 - beta * t >= 0:
        return (20000 - alpha * t, 0, 2000 - beta * t)
    else:
        return (0, 0, 0)

def GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6):
    if num == 1:
        if 0 <= t < t1:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800)
        elif t1 <= t < t1 + t2:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t - t1)**2)
        elif t1 + t2 <= t:
            return (17800 - v * (t1 + t2) * math.cos(th), v * (t1 + t2) * math.sin(th), 
                    1800 - 0.5 * g * t2**2 - 3 * (t - t1 - t2))
    elif num == 2:
        if 0 <= t < t3:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800)
        elif t3 <= t < t3 + t4:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t - t3)**2)
        elif t3 + t4 <= t:
            return (17800 - v * (t3 + t4) * math.cos(th), v * (t3 + t4) * math.sin(th), 
                    1800 - 0.5 * g * t4**2 - 3 * (t - t3 - t4))
    elif num == 3:
        if 0 <= t < t5:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800)
        elif t5 <= t < t5 + t6:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t - t5)**2)
        elif t5 + t6 <= t:
            return (17800 - v * (t5 + t6) * math.cos(th), v * (t5 + t6) * math.sin(th), 
                    1800 - 0.5 * g * t6**2 - 3 * (t - t5 - t6))

def lengther(v, th, num, t, t1, t2, t3, t4, t5, t6):
    M = MissilePlace(t)
    G = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6)
    P = (0, 200, 0)

    vector_PM = np.array([M[0] - P[0], M[1] - P[1], M[2] - P[2]])
    vector_PG = np.array([G[0] - P[0], G[1] - P[1], G[2] - P[2]])
    
    cross_product = np.cross(vector_PG, vector_PM)
    distance = np.linalg.norm(cross_product) / np.linalg.norm(vector_PM)
    
    return t, distance < 10  # 返回是否在有效范围内

def ccnt(v, th, t1, t2, t3, t4, t5, t6):
    t_start = 0
    t_end = 20
    t_step = 0.01
    cntt = 0
    
    for t in np.arange(t_start, t_end, t_step):
        # 检查第一个目标的时间区间
        if t1 + t2 <= t <= 20 + t1 + t2:
            if lengther(v, th, 1, t, t1, t2, t3, t4, t5, t6)[1]:
                cntt += 1
        
        # 检查第二个目标的时间区间
        if t3 + t4 <= t <= 20 + t3 + t4:
            if lengther(v, th, 2, t, t1, t2, t3, t4, t5, t6)[1]:
                cntt += 1
        
        # 检查第三个目标的时间区间
        if t5 + t6 <= t <= 20 + t5 + t6:
            if lengther(v, th, 3, t, t1, t2, t3, t4, t5, t6)[1]:
                cntt += 1
    
    return cntt

# 遗传算法实现
class GeneticAlgorithm:
    def __init__(self, param_ranges, fitness_func, pop_size=50, generations=100, 
                 mutation_rate=0.1, crossover_rate=0.8):
        """
        初始化遗传算法
        :param param_ranges: 参数范围，格式为[(min1, max1), (min2, max2), ...]
        :param fitness_func: 适应度函数
        :param pop_size: 种群大小
        :param generations: 迭代代数
        :param mutation_rate: 变异率
        :param crossover_rate: 交叉率
        """
        self.param_ranges = param_ranges
        self.num_params = len(param_ranges)
        self.fitness_func = fitness_func
        self.pop_size = pop_size
        self.generations = generations
        self.mutation_rate = mutation_rate
        self.crossover_rate = crossover_rate
        
        # 初始化种群
        self.population = self.initialize_population()
        
        # 记录每代的最佳适应度
        self.best_fitness_history = []
        self.best_individual_history = []
        
    def initialize_population(self):
        """初始化种群"""
        population = []
        for _ in range(self.pop_size):
            individual = []
            for (min_val, max_val) in self.param_ranges:
                # 在参数范围内随机生成值
                individual.append(min_val + (max_val - min_val) * np.random.random())
            population.append(individual)
        return population
    
    def calculate_fitness(self, individual):
        """计算个体的适应度"""
        # 解包参数
        th, v, t1, t2, t3, t4, t5, t6 = individual
        return self.fitness_func(v, th, t1, t2, t3, t4, t5, t6)
    
    def select_parents(self, fitness_values):
        """选择父代（轮盘赌选择）"""
        # 确保适应度为正值
        fitness_values = np.array(fitness_values)
        min_fitness = np.min(fitness_values)
        if min_fitness < 0:
            fitness_values += -min_fitness + 1e-6  # 偏移量确保为正
        
        # 计算选择概率
        total_fitness = np.sum(fitness_values)
        probabilities = fitness_values / total_fitness
        
        # 选择父代
        parents = []
        for _ in range(self.pop_size):
            # 轮盘赌选择
            parent_idx = np.random.choice(range(self.pop_size), p=probabilities)
            parents.append(self.population[parent_idx])
        
        return parents
    
    def crossover(self, parent1, parent2):
        """单点交叉"""
        if np.random.random() < self.crossover_rate:
            # 随机选择交叉点
            crossover_point = np.random.randint(1, self.num_params - 1)
            child1 = parent1[:crossover_point] + parent2[crossover_point:]
            child2 = parent2[:crossover_point] + parent1[crossover_point:]
            return child1, child2
        else:
            # 不交叉，直接复制
            return parent1.copy(), parent2.copy()
    
    def mutate(self, individual):
        """变异操作"""
        mutated_individual = individual.copy()
        for i in range(self.num_params):
            if np.random.random() < self.mutation_rate:
                min_val, max_val = self.param_ranges[i]
                # 高斯变异，在当前值附近小幅扰动
                mutation = np.random.normal(0, 0.1 * (max_val - min_val))
                mutated_individual[i] += mutation
                
                # 确保变异后的值仍在参数范围内
                mutated_individual[i] = max(min_val, min(mutated_individual[i], max_val))
        return mutated_individual
    
    def evolve(self):
        """执行遗传算法进化过程，每代输出结果"""
        for generation in range(self.generations):
            # 计算所有个体的适应度
            fitness_values = [self.calculate_fitness(ind) for ind in self.population]
            
            # 记录最佳个体
            best_idx = np.argmax(fitness_values)
            best_fitness = fitness_values[best_idx]
            best_individual = self.population[best_idx]
            
            self.best_fitness_history.append(best_fitness)
            self.best_individual_history.append(best_individual)
            
            # 每代都输出结果
            print(f"\n第{generation}代 - 最佳适应度: {best_fitness}")
            th, v, t1, t2, t3, t4, t5, t6 = best_individual
            print(f"  th: {th:.4f} 弧度 ({math.degrees(th):.1f}°)")
            print(f"  v: {v:.2f}")
            print(f"  t1: {t1:.2f}, t2: {t2:.2f}")
            print(f"  t3: {t3:.2f}, t4: {t4:.2f}")
            print(f"  t5: {t5:.2f}, t6: {t6:.2f}")
            
            # 选择父代
            parents = self.select_parents(fitness_values)
            
            # 交叉产生子代
            offspring = []
            for i in range(0, self.pop_size, 2):
                parent1 = parents[i]
                parent2 = parents[i+1] if i+1 < self.pop_size else parents[0]
                
                child1, child2 = self.crossover(parent1, parent2)
                offspring.append(child1)
                offspring.append(child2)
            
            # 变异
            offspring = [self.mutate(child) for child in offspring[:self.pop_size]]
            
            # 更新种群
            self.population = offspring
        
        # 返回最佳结果
        best_idx = np.argmax(self.best_fitness_history)
        return self.best_individual_history[best_idx], self.best_fitness_history[best_idx]

# 主函数：运行遗传算法并显示结果
def main():
    # 参数范围：[th, v, t1, t2, t3, t4, t5, t6]
    param_ranges = [
        [7*math.pi/8, math.pi],  # th (弧度)
        [70, 90],                # v
        [0, 10],                 # t1
        [0, 5],                  # t2
        [1, 10],                 # t3
        [0, 5],                  # t4
        [2, 10],                 # t5
        [0, 5]                   # t6
    ]
    
    # 创建并运行遗传算法
    ga = GeneticAlgorithm(
        param_ranges=param_ranges,
        fitness_func=ccnt,
        pop_size=75,
        generations=20,
        mutation_rate=0.1,
        crossover_rate=0.8
    )
    
    best_params, best_fitness = ga.evolve()
    
    # 显示最终结果
    print("\n==================== 优化完成 ====================")
    print(f"最佳适应度 (最大ccnt值): {best_fitness}")
    print("最佳参数:")
    th, v, t1, t2, t3, t4, t5, t6 = best_params
    print(f"  th: {th:.4f} 弧度 ({math.degrees(th):.1f}°)")
    print(f"  v: {v:.2f}")
    print(f"  t1: {t1:.2f}, t2: {t2:.2f}")
    print(f"  t3: {t3:.2f}, t4: {t4:.2f}")
    print(f"  t5: {t5:.2f}, t6: {t6:.2f}")
    
    # 绘制适应度变化曲线
    plt.figure(figsize=(10, 6))
    plt.plot(ga.best_fitness_history)
    plt.title('遗传算法优化过程 - 最佳适应度变化')
    plt.xlabel('代数')
    plt.ylabel('最佳适应度 (ccnt值)')
    plt.grid(True)
    plt.show()

if __name__ == "__main__":
    main()
