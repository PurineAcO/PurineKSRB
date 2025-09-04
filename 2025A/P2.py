import math
import random
import numpy as np

# 定义原函数
def gaer(theta, v, t1, t2):
    g = 9.8
    tau = (math.cos(theta), math.sin(theta))
    # 计算GRD_1坐标
    GRD_1 = (17800 + v * t1 * tau[0], v * t1 * tau[1], 1800)
    # 计算GRD_2坐标
    GRD_2 = (
        GRD_1[0] + v * t2 * tau[0],
        GRD_1[1] + v * t2 * tau[1],
        GRD_1[2] - 0.5 * g * t2 * t2
    )
    # 计算M_2坐标
    total_time = t1 + t2
    M_2 = (
        20000 - (300 * total_time * 10) / math.sqrt(101),
        0,
        2000 - (300 * total_time) / math.sqrt(101)
    )
    
    X1, Y1, Z1 = GRD_2
    X2 = M_2[0]
    Z2 = X2 / 10
    alpha = 3000 / math.sqrt(101)
    beta = alpha / 10

    # 计算二次方程系数
    a = alpha**2 + (beta - 3)** 2
    b = 2 * alpha * (X1 - X2) + 2 * (beta - 3) * (Z1 - Z2)
    c = (X1 - X2)**2 + Y1**2 + (Z1 - Z2)**2 - 10**2
    
    # 计算判别式
    discriminant = b**2 - 4 * a * c
    
    if discriminant <= 0:
        return 0  # 无实根时返回0，表示适应度低
    else:
        # 计算两个根
        t_1 = (-b + math.sqrt(discriminant)) / (2 * a)
        t_2 = (-b - math.sqrt(discriminant)) / (2 * a)
        
        # 确保t_1 <= t_2
        if t_1 > t_2:
            t_1, t_2 = t_2, t_1
        
        # 应用约束
        if t_2 >= 20:
            t_2 = 20      
            
        # 计算dt值
        dt = t_2 - t_1
        return max(dt, 0)  # 确保dt非负

# 遗传算法类
class GeneticAlgorithm:
    def __init__(self, pop_size=100, generations=50, mutation_rate=0.01, crossover_rate=0.8):
        self.pop_size = pop_size  # 种群大小
        self.generations = generations  # 迭代代数
        self.mutation_rate = mutation_rate  # 变异率
        self.crossover_rate = crossover_rate  # 交叉率
        
        # 参数范围
        self.param_ranges = [
            (0, 2 * math.pi),   # theta范围
            (70, 140),          # v范围
            (0, 100),           # t1范围（可根据实际情况调整）
            (0, 100)            # t2范围（可根据实际情况调整）
        ]
        
        # 初始化种群
        self.population = self.initialize_population()
        self.best_fitness = 0
        self.best_individual = None
        
    def initialize_population(self):
        """初始化种群"""
        population = []
        for _ in range(self.pop_size):
            individual = [
                random.uniform(*self.param_ranges[0]),  # theta
                random.uniform(*self.param_ranges[1]),  # v
                random.uniform(*self.param_ranges[2]),  # t1
                random.uniform(*self.param_ranges[3])   # t2
            ]
            population.append(individual)
        return population
    
    def calculate_fitness(self, individual):
        """计算适应度"""
        theta, v, t1, t2 = individual
        return gaer(theta, v, t1, t2)
    
    def select_parents(self, fitness_scores):
        """轮盘赌选择父母"""
        total_fitness = sum(fitness_scores)
        
        # 处理总适应度为0的情况
        if total_fitness == 0:
            return random.choices(self.population, k=2)
            
        probabilities = [f / total_fitness for f in fitness_scores]
        parents = random.choices(self.population, weights=probabilities, k=2)
        return parents
    
    def crossover(self, parent1, parent2):
        """单点交叉"""
        if random.random() < self.crossover_rate:
            point = random.randint(1, len(parent1) - 1)
            child1 = parent1[:point] + parent2[point:]
            child2 = parent2[:point] + parent1[point:]
            return child1, child2
        else:
            return parent1.copy(), parent2.copy()
    
    def mutate(self, individual):
        """变异操作"""
        mutated = individual.copy()
        for i in range(len(mutated)):
            if random.random() < self.mutation_rate:
                # 对每个基因进行高斯变异
                min_val, max_val = self.param_ranges[i]
                # 变异步长为参数范围的5%
                step = (max_val - min_val) * 0.05
                mutated[i] += random.gauss(0, step)
                # 确保变异后的值在范围内
                mutated[i] = max(min_val, min(mutated[i], max_val))
        return mutated
    
    def evolve(self):
        """进化主循环"""
        for generation in range(self.generations):
            # 计算适应度
            fitness_scores = [self.calculate_fitness(ind) for ind in self.population]
            
            # 记录最佳个体
            current_best_idx = np.argmax(fitness_scores)
            current_best_fitness = fitness_scores[current_best_idx]
            current_best_individual = self.population[current_best_idx]
            
            if current_best_fitness > self.best_fitness:
                self.best_fitness = current_best_fitness
                self.best_individual = current_best_individual.copy()
            
            # 打印当前代信息
            if generation % 10 == 0:
                print(f"代数: {generation}, 平均适应度: {np.mean(fitness_scores):.4f}, "
                      f"最佳适应度: {current_best_fitness:.4f}")
            
            # 创建新一代
            new_population = []
            
            # 保留精英个体
            elite_ratio = 0.1
            elite_count = int(self.pop_size * elite_ratio)
            elite_indices = np.argsort(fitness_scores)[-elite_count:]
            for idx in elite_indices:
                new_population.append(self.population[idx])
            
            # 生成剩余个体
            while len(new_population) < self.pop_size:
                # 选择父母
                parent1, parent2 = self.select_parents(fitness_scores)
                # 交叉
                child1, child2 = self.crossover(parent1, parent2)
                # 变异
                child1 = self.mutate(child1)
                child2 = self.mutate(child2)
                # 添加到新种群
                new_population.append(child1)
                if len(new_population) < self.pop_size:
                    new_population.append(child2)
            
            # 更新种群
            self.population = new_population
        
        return self.best_individual, self.best_fitness

# 运行遗传算法
if __name__ == "__main__":
    # 设置算法参数
    ga = GeneticAlgorithm(
        pop_size=100,    # 种群大小
        generations=100, # 迭代代数
        mutation_rate=0.1, # 变异率
        crossover_rate=0.8 # 交叉率
    )
    
    # 执行优化
    best_params, best_dt = ga.evolve()
    
    # 输出结果
    print("\n优化结果:")
    print(f"最佳参数:")
    print(f"theta: {best_params[0]:.4f} 弧度")
    print(f"v: {best_params[1]:.4f}")
    print(f"t1: {best_params[2]:.4f}")
    print(f"t2: {best_params[3]:.4f}")
    print(f"最大dt值: {best_dt:.4f}")
    