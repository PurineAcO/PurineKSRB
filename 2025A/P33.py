import math
import numpy as np
import gym
from gym import spaces
from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_vec_env
import random

# 原代码中的常量和函数
g = 9.8
alpha = 3000 / math.sqrt(101)
beta = 300 / math.sqrt(101)

# 画网格
mesh = []
for theta in np.arange(0, 2 * math.pi, 0.1):
    mesh.append((7 * math.cos(theta), 200 + 7 * math.sin(theta), 10))
for theta in np.arange(0, 2 * math.pi, 0.1):
    for z in np.arange(0, 10, 0.1):
        mesh.append((7 * math.cos(theta), 200 + 7 * math.sin(theta), z))

# 定义原始函数
def s2e(a, b, c):
    if a == 0 or b**2 - 4*a*c < 0:
        return None
    else:
        delta = math.sqrt(b**2 - 4*a*c)
        x1 = (-b + delta) / (2*a)
        x2 = (-b - delta) / (2*a)
        return x1, x2
    
def MissilePlace(t):
    if 2000-beta*t>=0:
        return (20000 - alpha * t, 0, 2000 - beta * t)
    else:
        return (0,0,0)

def GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6):
    if num == 1:
        if 0 <= t < t1:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 )
        elif t1 <= t < t1 + t2:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t-t1)*(t-t1))
        elif t1 + t2 <= t:
            return (17800 - v * (t1 + t2) * math.cos(th), v * (t1 + t2) * math.sin(th), 
                   1800 - 0.5 * g * t2*t2 - 3*(t - t1 - t2))
    elif num == 2:
        if 0 <= t < t3:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800)
        elif t3 <= t < t3 + t4:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t-t3)*(t-t3))
        elif t3 + t4 <= t:
            return (17800 - v * (t3 + t4) * math.cos(th), v * (t3 + t4) * math.sin(th), 
                   1800 - 0.5 * g * t4*t4 - 3*(t - t3 - t4))
    elif num == 3:
        if 0 <= t < t5:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800)
        elif t5 <= t < t5 + t6:
            return (17800 - v * t * math.cos(th), v * t * math.sin(th), 1800 - 0.5 * g * (t-t5)*(t-t5))
        elif t5 + t6 <= t:
            return (17800 - v * (t5 + t6) * math.cos(th), v * (t5 + t6) * math.sin(th), 
                   1800 - 0.5 * g * t6*t6 - 3*(t - t5 - t6))

def solvek(t, mesh, v, th, num, t1, t2, t3, t4, t5, t6):
    M1, M2, M3 = MissilePlace(t)
    G1, G2, G3 = GRDPlace(v, th, num, t, t1, t2, t3, t4, t5, t6)
    for point in mesh:
        P1, P2, P3 = point
        a = (M1 - P1)**2 + (M2 - P2)** 2 + (M3 - P3)**2
        b = (-2) * ((M1 - P1) * (G1 - P1) + (M2 - P2) * (G2 - P2) + (M3 - P3) * (G3 - P3))
        c = (G1 - P1)** 2 + (G2 - P2)**2 + (G3 - P3)** 2 - 10**2  
        sol = s2e(a, b, c)
        if sol is not None and 0 <= sol[1] <= 1:
            return True
    return False

def dt(th, v, t1, t2, t3, t4, t5, t6):
    t_start = 0
    t_end = 20
    t_step = 0.01
    cnttinf = np.zeros(int((t_end - t_start) / t_step) + 1)
    cntt = 0
    
    for t in np.arange(t_start, t_end, t_step):
        idx = round((t - t_start) / t_step)
        if 20 + t1 + t2 >= t >= t1 + t2:
            if solvek(t, mesh, v, th, 1, t1, t2, t3, t4, t5, t6):
                cnttinf[idx] += 1
        if 20 + t3 + t4 >= t >= t3 + t4:
            if solvek(t, mesh, v, th, 2, t1, t2, t3, t4, t5, t6):
                cnttinf[idx] += 1
        if 20 + t5 + t6 >= t >= t5 + t6:
            if solvek(t, mesh, v, th, 3, t1, t2, t3, t4, t5, t6):
                cnttinf[idx] += 1

    for cnt in cnttinf:
        if cnt >= 1:
            cntt += 1
    return cntt

# 定义强化学习环境
class MissileEnv(gym.Env):
    metadata = {'render.modes': ['human']}
    
    def __init__(self):
        super(MissileEnv, self).__init__()
        
        # 定义参数范围
        # th: 角度 (0到pi/2)
        # v: 速度 (100到1000)
        # t1-t6: 时间参数 (0到10)
        self.action_space = spaces.Box(
            low=np.array([0, 100, 0, 0, 0, 0, 0, 0]),
            high=np.array([math.pi/2, 1000, 10, 10, 10, 10, 10, 10]),
            dtype=np.float32
        )
        
        # 状态空间可以是上一步的参数和结果
        self.observation_space = spaces.Box(
            low=np.array([0, 100, 0, 0, 0, 0, 0, 0, 0]),
            high=np.array([math.pi/2, 1000, 10, 10, 10, 10, 10, 10, 4000]),
            dtype=np.float32
        )
        
        self.last_params = None
        self.last_reward = 0
    
    def step(self, action):
        # 解析动作参数
        th, v, t1, t2, t3, t4, t5, t6 = action
        
        # 计算当前参数的dt值作为奖励
        current_reward = dt(th, v, t1, t2, t3, t4, t5, t6)
        current_reward-=10/(t3-t1-0.85)+10/(t5-t3-0.85)
        
        # 构建观测值：上一步的参数和奖励
        observation = np.concatenate([action, [current_reward]])
        
        # 定义终止条件（每个episode固定步数后结束）
        self.step_count += 1
        done = self.step_count >= 100  # 每个episode运行100步
        
        # 可选的信息
        info = {"params": action, "dt_value": current_reward}
        
        self.last_params = action
        self.last_reward = current_reward
        
        return observation, current_reward, done, info
    
    def reset(self):
        # 随机初始化参数
        th = random.uniform(0, math.pi/2)
        v = random.uniform(100, 1000)
        t1 = random.uniform(0, 10)
        t2 = random.uniform(0, 10)
        t3 = random.uniform(0, 10)
        t4 = random.uniform(0, 10)
        t5 = random.uniform(0, 10)
        t6 = random.uniform(0, 10)
        
        self.last_params = np.array([th, v, t1, t2, t3, t4, t5, t6])
        self.last_reward = 0
        self.step_count = 0
        
        # 返回初始观测
        return np.concatenate([self.last_params, [self.last_reward]])
    
    def render(self, mode='human'):
        if mode == 'human':
            print(f"参数: {self.last_params}, dt值: {self.last_reward}")

# 训练模型
def train_model():
    # 创建环境
    env = MissileEnv()
    
    # 使用PPO算法
    model = PPO("MlpPolicy", env, verbose=1,
                learning_rate=3e-4,
                n_steps=2048,
                batch_size=64,
                n_epochs=10,
                gamma=0.99,
                gae_lambda=0.95,
                clip_range=0.2,
                ent_coef=0.01)
    
    # 训练模型
    total_timesteps = 100000
    model.learn(total_timesteps=total_timesteps)
    
    # 保存模型
    model.save("missile_defense_model")
    
    return model

# 测试模型
def test_model(model):
    env = MissileEnv()
    obs = env.reset()
    total_reward = 0
    num_episodes = 10
    
    for _ in range(num_episodes):
        action, _ = model.predict(obs, deterministic=True)
        obs, reward, done, info = env.step(action)
        total_reward += reward
        env.render()
        if done:
            obs = env.reset()
    
    print(f"平均奖励: {total_reward / num_episodes}")
    return total_reward / num_episodes

if __name__ == "__main__":
    # 训练模型
    trained_model = train_model()
    
    # 测试模型
    test_model(trained_model)
    
    # 找到最佳参数
    env = MissileEnv()
    obs = env.reset()
    best_reward = -1
    best_params = None
    
    for _ in range(1000):
        action, _ = trained_model.predict(obs, deterministic=True)
        obs, reward, done, info = env.step(action)
        
        if reward > best_reward:
            best_reward = reward
            best_params = action
            
        if done:
            obs = env.reset()
    
    print(f"最佳参数: {best_params}")
    print(f"最佳dt值: {best_reward}")
    print(f"参数解释:")
    print(f"th: {best_params[0]}, v: {best_params[1]}")
    print(f"t1: {best_params[2]}, t2: {best_params[3]}, t3: {best_params[4]}, t4: {best_params[5]}, t5: {best_params[6]}, t6: {best_params[7]}")

