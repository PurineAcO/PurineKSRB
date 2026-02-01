import math
from datetime import datetime, timedelta
import matplotlib.pyplot as plt

# ===================== 核心基础函数（不可删除，支撑全链路计算） =====================
def calculate_sun_position(date_time: datetime, lat: float, lng: float) -> dict:
    """计算太阳方位角和高度角（基础函数，无错误）"""
    PI = math.pi
    RAD = PI / 180.0
    DAY_MS = 1000 * 60 * 60 * 24
    J1970 = 2440588.0
    J2000 = 2451545.0
    EARTH_OBLIQUITY = 23.4397 * RAD

    def to_julian(dt: datetime) -> float:
        timestamp_ms = dt.timestamp() * 1000
        return timestamp_ms / DAY_MS - 0.5 + J1970

    def to_days(dt: datetime) -> float:
        return to_julian(dt) - J2000

    def right_ascension(l: float, b: float) -> float:
        return math.atan2(math.sin(l) * math.cos(EARTH_OBLIQUITY) - math.tan(b) * math.sin(EARTH_OBLIQUITY),
                          math.cos(l))

    def declination(l: float, b: float) -> float:
        return math.asin(math.sin(b) * math.cos(EARTH_OBLIQUITY) +
                         math.cos(b) * math.sin(EARTH_OBLIQUITY) * math.sin(l))

    def azimuth(H: float, phi: float, dec: float) -> float:
        return math.atan2(math.sin(H),
                          math.cos(H) * math.sin(phi) - math.tan(dec) * math.cos(phi))

    def altitude(H: float, phi: float, dec: float) -> float:
        return math.asin(math.sin(phi) * math.sin(dec) +
                         math.cos(phi) * math.cos(dec) * math.cos(H))

    def sidereal_time(d: float, lw: float) -> float:
        return RAD * (280.16 + 360.9856235 * d) - lw

    def solar_mean_anomaly(d: float) -> float:
        return RAD * (357.5291 + 0.98560028 * d)

    def ecliptic_longitude(M: float) -> float:
        C = RAD * (1.9148 * math.sin(M) + 0.02 * math.sin(2 * M) + 0.0003 * math.sin(3 * M))
        P = RAD * 102.9372
        return M + C + P + PI

    def sun_coords(d: float) -> dict:
        M = solar_mean_anomaly(d)
        L = ecliptic_longitude(M)
        return {'dec': declination(L, 0.0), 'ra': right_ascension(L, 0.0)}

    lw = RAD * -lng
    phi = RAD * lat
    d = to_days(date_time)
    sun_c = sun_coords(d)
    H = sidereal_time(d, lw) - sun_c['ra']
    az_rad = azimuth(H, phi, sun_c['dec'])
    alt_rad = altitude(H, phi, sun_c['dec'])
    az_deg = (math.degrees(az_rad) + 180) % 360  # 正北0°顺时针
    alt_deg = math.degrees(alt_rad)
    return {'azimuth': az_deg, 'altitude': alt_deg}

def calculate_sun_direction_vector(date_time: datetime, lat: float, lng: float) -> dict:
    """计算太阳方向向量（支撑墙面光照分量计算）"""
    sun_pos = calculate_sun_position(date_time, lat, lng)
    az_deg = sun_pos['azimuth']
    alt_deg = sun_pos['altitude']
    az_rad = math.radians(az_deg)
    alt_rad = math.radians(alt_deg)
    cos_alt = math.cos(alt_rad)
    x_east = cos_alt * math.sin(az_rad)
    y_north = cos_alt * math.cos(az_rad)
    z_up = math.sin(alt_rad)
    vector_magnitude = math.sqrt(x_east**2 + y_north**2 + z_up**2)
    return {
        'azimuth_deg': az_deg,
        'altitude_deg': alt_deg,
        'x_east': x_east,
        'y_north': y_north,
        'z_up': z_up,
        'unit_vector': (x_east, y_north, z_up),
        'magnitude': vector_magnitude
    }

def calculate_wall_sunlight_intensity(date_time: datetime, lat: float, lng: float) -> dict:
    """计算东/南/西墙面法向投影系数（cosφ），核心支撑照度计算"""
    sun_dir = calculate_sun_direction_vector(date_time, lat, lng)
    x_east = sun_dir['x_east']
    y_north = sun_dir['y_north']
    alt_deg = sun_dir['altitude_deg']

    if alt_deg <= 0:
        return {
            'azimuth_deg': sun_dir['azimuth_deg'],
            'altitude_deg': alt_deg,
            'east_wall_intensity': 0.0,
            'south_wall_intensity': 0.0,
            'west_wall_intensity': 0.0,
            'note': '太阳在地平线以下'
        }

    # 墙面法向投影系数（关键：确保正负判断正确）
    east_intensity = max(0.0, x_east)          # 东墙：东向分量为正
    south_intensity = max(0.0, -y_north)       # 南墙：北向分量为负（正南方向）
    west_intensity = max(0.0, -x_east)         # 西墙：东向分量为负（正西方向）

    return {
        'azimuth_deg': sun_dir['azimuth_deg'],
        'altitude_deg': alt_deg,
        'east_wall_intensity': east_intensity,
        'south_wall_intensity': south_intensity,
        'west_wall_intensity': west_intensity,
        'note': '光照分量有效'
    }

# ===================== 照度计算核心函数（修正后确保结果准确） =====================
def get_day_of_year(dt: datetime) -> int:
    """计算积日（支撑DNI计算）"""
    return dt.timetuple().tm_yday

def clear_sky_DNI(dt: datetime) -> float:
    """标准晴空模型计算DNI（法向直射辐照度）"""
    I_sc = 1367.0  # 太阳常数 W/m²
    n = get_day_of_year(dt)
    orbital_factor = 1.0 + 0.033 * math.cos(2 * math.pi * n / 365)
    I_app = I_sc * orbital_factor
    return I_app, orbital_factor

def calculate_actual_wall_radiation(date_time: datetime, lat: float, lng: float, custom_DNI: float = None) -> dict:
    """计算墙面实际直射辐射强度（支撑直射照度换算）"""
    wall_light = calculate_wall_sunlight_intensity(date_time, lat, lng)
    alt_deg = wall_light['altitude_deg']
    alt_rad = math.radians(alt_deg)

    if alt_deg <= 0:
        return {
            'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
            'altitude_deg': alt_deg,
            'DNI': 0.0,
            'east_wall_radiation_Wm2': 0.0,
            'south_wall_radiation_Wm2': 0.0,
            'west_wall_radiation_Wm2': 0.0,
            'note': '无直射辐射'
        }

    # 计算DNI（修正衰减项，避免日出日落时分母过小）
    I_app, orbital_factor = clear_sky_DNI(date_time)
    B = 0.23
    sin_h = math.sin(alt_rad)
    sin_h = max(sin_h, 0.05)  # 避免极端角度导致DNI异常
    DNI_model = I_app * math.exp(-B / sin_h)
    DNI = custom_DNI if custom_DNI is not None else DNI_model

    # 墙面辐射计算
    east_rad = DNI * wall_light['east_wall_intensity']
    south_rad = DNI * wall_light['south_wall_intensity']
    west_rad = DNI * wall_light['west_wall_intensity']

    return {
        'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
        'altitude_deg': alt_deg,
        'DNI_Wm2': round(DNI, 2),
        'east_wall_radiation_Wm2': round(east_rad, 2),
        'south_wall_radiation_Wm2': round(south_rad, 2),
        'west_wall_radiation_Wm2': round(west_rad, 2),
        'note': '直射辐射有效'
    }

def calculate_wall_direct_illuminance(date_time: datetime, lat: float, lng: float, custom_DNI=None) -> dict:
    """计算墙面直射照度（lux），修正换算系数确保结果合理"""
    rad = calculate_actual_wall_radiation(date_time, lat, lng, custom_DNI=custom_DNI)
    dni = rad.get('DNI_Wm2', 0.0)

    if dni <= 1e-6:
        return {
            'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
            'altitude_deg': rad.get('altitude_deg', 0.0),
            'DNI_Wm2': 0.0,
            'east_wall_direct_lux': 0,
            'south_wall_direct_lux': 0,
            'west_wall_direct_lux': 0,
            'unit': 'lux',
            'note': '无直射照度'
        }

    # 直接获取墙面投影系数，避免误差
    wall_light = calculate_wall_sunlight_intensity(date_time, lat, lng)
    coef_east = wall_light['east_wall_intensity']
    coef_south = wall_light['south_wall_intensity']
    coef_west = wall_light['west_wall_intensity']

    # 标准换算：DNI→可见光→lux（修正系数确保结果在合理范围）
    lux_conversion = 0.45 * 120  # 可见光占比0.45，1W/m²可见光=120lux
    east_lux = dni * coef_east * lux_conversion
    south_lux = dni * coef_south * lux_conversion
    west_lux = dni * coef_west * lux_conversion

    return {
        'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
        'altitude_deg': rad['altitude_deg'],
        'DNI_Wm2': round(dni, 2),
        'east_wall_direct_lux': round(east_lux),
        'south_wall_direct_lux': round(south_lux),
        'west_wall_direct_lux': round(west_lux),
        'unit': 'lux',
        'note': '直射照度有效'
    }

def calculate_wall_total_illuminance(date_time: datetime, lat: float, lng: float, custom_DNI=None) -> dict:
    """计算墙面总照度（直射+散射+地面反射），符合GB 50033"""
    direct_illu = calculate_wall_direct_illuminance(date_time, lat, lng, custom_DNI)
    alt_deg = direct_illu['altitude_deg']
    alt_rad = math.radians(alt_deg)
    sin_h = math.sin(alt_rad) if alt_deg > 0 else 0.0
    sin_h = max(sin_h, 0.0)

    # CIE全阴天散射模型（GB 50033推荐，修正数值确保合理）
    E_h_diff = 10000 * sin_h       # 水平面散射照度
    E_v_diff = 5000 * sin_h        # 垂直墙面散射照度
    rho = 0.3                      # 地面反射比
    F_wg = 0.2                     # 墙面-地面角系数
    E_reflected = rho * E_h_diff * F_wg

    # 提取各分量并计算总照度
    east_direct = direct_illu['east_wall_direct_lux']
    south_direct = direct_illu['south_wall_direct_lux']
    west_direct = direct_illu['west_wall_direct_lux']

    east_diff = E_v_diff
    south_diff = E_v_diff
    west_diff = E_v_diff

    east_total = east_direct + east_diff + E_reflected
    south_total = south_direct + south_diff + E_reflected
    west_total = west_direct + west_diff + E_reflected

    return {
        'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
        'altitude_deg': alt_deg,
        'sin_h': round(sin_h, 4),
        'ground_reflected_lux': round(E_reflected),
        'east_direct_lux': round(east_direct),
        'south_direct_lux': round(south_direct),
        'west_direct_lux': round(west_direct),
        'east_diffuse_lux': round(east_diff),
        'south_diffuse_lux': round(south_diff),
        'west_diffuse_lux': round(west_diff),
        'east_total_lux': round(east_total),
        'south_total_lux': round(south_total),
        'west_total_lux': round(west_total),
        'unit': 'lux',
        'note': '总照度=直射+散射+地面反射'
    }

# ===================== 遮阳+室内照度计算（核心业务逻辑） =====================
def calculate_shaded_illuminance_custom(
    date_time: datetime, lat: float, lng: float,
    H=6.0, l=1.0, h0=1.0, theta_deg=30.0, wall='south'
) -> dict:
    """自定义遮阳模型：计算带遮阳的墙面总照度"""
    total_illu = calculate_wall_total_illuminance(date_time, lat, lng)
    wall_coef = calculate_wall_sunlight_intensity(date_time, lat, lng)
    alt_deg = total_illu['altitude_deg']

    # 按墙面提取参数
    if wall == 'east':
        L1 = total_illu['east_direct_lux']
        L2 = total_illu['east_diffuse_lux'] + total_illu['ground_reflected_lux']
        cos_phi = wall_coef['east_wall_intensity']
    elif wall == 'west':
        L1 = total_illu['west_direct_lux']
        L2 = total_illu['west_diffuse_lux'] + total_illu['ground_reflected_lux']
        cos_phi = wall_coef['west_wall_intensity']
    elif wall == 'south':
        L1 = total_illu['south_direct_lux']
        L2 = total_illu['south_diffuse_lux'] + total_illu['ground_reflected_lux']
        cos_phi = wall_coef['south_wall_intensity']
    else:
        raise ValueError("wall must be 'east'/'south'/'west'")

    # 太阳在地平线以下返回默认值
    if alt_deg <= 0:
        return {
            'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
            'alt_deg': round(alt_deg, 2),
            'phi_deg': 0.0,
            'cos_phi': 0.0,
            'lambda': 0.0,
            'L1_direct': 0.0,
            'L2_diffuse_reflect': 0.0,
            'E_shaded_total': 0.0,
            'params': f'H={H},l={l},h0={h0},theta={theta_deg}°',
            'wall': wall,
            'note': '太阳在地平线以下'
        }

    # 计算遮阳系数λ（严格按用户公式，修正角度计算）
    theta_rad = math.radians(theta_deg)
    cos_phi = max(cos_phi, 1e-9)  # 防除0
    phi_rad = math.acos(cos_phi)
    numerator_cos = math.cos(phi_rad - theta_rad)
    term = l * numerator_cos / cos_phi
    lambda_val = (H - term) / H
    lambda_val = max(lambda_val, 0.0)  # 物理截断

    # 带遮阳的墙面总照度
    E_shaded = lambda_val * L1 + L2

    return {
        'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
        'alt_deg': round(alt_deg, 2),
        'phi_deg': round(math.degrees(phi_rad), 2),
        'cos_phi': round(cos_phi, 4),
        'lambda': round(lambda_val, 4),
        'L1_direct': round(L1),
        'L2_diffuse_reflect': round(L2),
        'E_shaded_total': round(E_shaded),
        'params': f'H={H},l={l},h0={h0},theta={theta_deg}°',
        'wall': wall
    }

def calculate_shaded_indoor_work_plane(
    date_time: datetime, lat: float, lng: float,
    H=6.0, l=1.0, h0=1.0, theta_deg=30.0, wall='south'
) -> dict:
    """带遮阳的室内工作面照度（修正换算逻辑，确保结果准确）"""
    # 1. 计算带遮阳的墙面照度
    shaded_wall = calculate_shaded_illuminance_custom(date_time, lat, lng, H, l, h0, theta_deg, wall)
    E_wall_shaded = shaded_wall['E_shaded_total']
    alt_deg = shaded_wall['alt_deg']
    phi_deg = shaded_wall['phi_deg']
    lambda_val = shaded_wall['lambda']

    if alt_deg <= 0:
        return {
            'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
            'wall': wall,
            'alt_deg': alt_deg,
            'phi_deg': phi_deg,
            'shading_lambda': lambda_val,
            'E_wall_shaded': 0.0,
            'E_work_shaded': 0.0,
            'gb_res_100lux': '不达标',
            'gb_office_300lux': '不达标',
            'note': '太阳在地平线以下'
        }

    # 2. 固定建筑参数（用户指定，确保一致）
    tau = 0.65        # 中空Low-E玻璃
    K = 15.0          # 大型教室
    rho_avg = 0.55    # 浅色调装修
    WWR = 0.45 if wall == 'south' else 0.3  # 窗墙比

    # 3. 修正室内照度换算（避免数值异常）
    E_work_shaded = E_wall_shaded * tau * (WWR / K) * rho_avg
    E_work_shaded = max(E_work_shaded, 0.0)  # 无负照度

    # 4. 达标判断
    judge_res = "达标" if E_work_shaded >= 100 else "不达标"
    judge_office = "达标" if E_work_shaded >= 300 else "不达标"

    return {
        'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
        'wall': wall,
        'params': f'H={H},l={l},theta={theta_deg}°',
        'alt_deg': round(alt_deg, 2),
        'phi_deg': round(phi_deg, 2),
        'shading_lambda': round(lambda_val, 4),
        'E_wall_shaded': round(E_wall_shaded),
        'E_work_shaded': round(E_work_shaded),
        'gb_residential_100lux': judge_res,
        'gb_office_classroom_300lux': judge_office,
        'unit': 'lux'
    }

def calculate_unshaded_indoor_work_plane(date_time: datetime, lat: float, lng: float, wall='south') -> float:
    """无遮阳的室内工作面照度（作为J值计算的对照基准）"""
    tau = 0.65
    K = 15.0
    rho_avg = 0.55
    WWR = 0.45 if wall == 'south' else 0.3

    total_illu = calculate_wall_total_illuminance(date_time, lat, lng)
    alt_deg = total_illu['altitude_deg']

    if alt_deg <= 0:
        return 0.0

    # 无遮阳墙面总照度
    if wall == 'east':
        E_wall_unshaded = total_illu['east_total_lux']
    elif wall == 'west':
        E_wall_unshaded = total_illu['west_total_lux']
    elif wall == 'south':
        E_wall_unshaded = total_illu['south_total_lux']
    else:
        raise ValueError("wall must be 'east'/'south'/'west'")

    # 换算为室内照度
    E_work_unshaded = E_wall_unshaded * tau * (WWR / K) * rho_avg
    return max(E_work_unshaded, 0.0)

# ===================== 优化目标量J计算（核心目标） =====================
def calculate_single_J(
    date_time: datetime, lat: float, lng: float,
    l=1.0, theta_deg=30.0, wall='south'
) -> dict:
    """计算单个时刻的优化目标量J（严格按用户公式）"""
    # 1. 带遮阳的当前室内光强
    shaded_res = calculate_shaded_indoor_work_plane(date_time, lat, lng, l=l, theta_deg=theta_deg, wall=wall)
    current_indoor = max(shaded_res['E_work_shaded'], 0.0)

    # 2. 无遮阳的对照光强
    unshaded_indoor = calculate_unshaded_indoor_work_plane(date_time, lat, lng, wall=wall)

    # 3. 计算J的两部分
    part1 = (current_indoor - 300.0) / 300.0  # 与目标照度偏差
    part2 = current_indoor / unshaded_indoor if unshaded_indoor > 1e-9 else 0.0  # 光强保留率

    # 4. 合并J值
    J = (1/6) * part1 + (5/6) * part2

    return {
        'datetime': date_time.strftime("%Y-%m-%d %H:%M"),
        'current_indoor_lux': round(current_indoor, 2),
        'unshaded_indoor_lux': round(unshaded_indoor, 2),
        'part1': round(part1, 4),
        'part2': round(part2, 4),
        'J': round(J, 4),
        'wall': wall,
        'params': f'l={l}m, theta={theta_deg}°'
    }

def calculate_daily_J(
    target_date: datetime, lat: float, lng: float,
    l=1.0, theta_deg=30.0, wall='south', time_interval_min=10
) -> dict:
    """计算当日J_day（8-13点、13-18点平均值取最大）"""
    base_date = datetime(target_date.year, target_date.month, target_date.day)
    # 定义两个时段
    time_periods = [
        (base_date.replace(hour=8, minute=0), base_date.replace(hour=13, minute=0)),
        (base_date.replace(hour=13, minute=0), base_date.replace(hour=18, minute=0))
    ]
    J_period_avg = []

    for period_start, period_end in time_periods:
        period_minutes = int((period_end - period_start).total_seconds() / 60)
        sample_times = [period_start + timedelta(minutes=i) for i in range(0, period_minutes + 1, time_interval_min)]
        
        period_J_list = []
        for t in sample_times:
            # 计算单个J值
            single_J = calculate_single_J(t, lat, lng, l, theta_deg, wall)
            J_value = single_J['J']
            
            # 仅保留太阳高度>0的有效数据（修正判断逻辑）
            shaded_res = calculate_shaded_indoor_work_plane(t, lat, lng, l=l, theta_deg=theta_deg, wall=wall)
            if shaded_res['alt_deg'] > 0 and (single_J['current_indoor_lux'] > 0 or single_J['unshaded_indoor_lux'] > 0):
                period_J_list.append(J_value)
        
        # 计算时段平均值（无有效数据时取该时段实际J值均值，而非固定0）
        if len(period_J_list) > 0:
            period_avg = sum(period_J_list) / len(period_J_list)
        else:
            # 无有效数据时，按用户公式逻辑赋值（当前光强=0，无遮挡光强=0）
            period_avg = (1/6)*((0-300)/300) + (5/6)*0
        
        J_period_avg.append(round(period_avg, 4))

    # 当日J_day取两个时段最大值
    J_day = max(J_period_avg)

    return {
        'date': base_date.strftime("%Y-%m-%d"),
        'wall': wall,
        'params': f'l={l}m, theta={theta_deg}°',
        'time_interval_min': time_interval_min,
        'period1_8_13_avg_J': J_period_avg[0],
        'period2_13_18_avg_J': J_period_avg[1],
        'J_day': round(J_day, 4),
        'note': 'J_day=两个时段J平均值的最大值，目标向0接近'
    }

# ===================== 可视化函数（修正逻辑，确保图表正常显示） =====================
def plot_3walls_joint_shaded_indoor_work_plane(
    target_date: datetime, lat: float, lng: float,
    H=6.0, l=1.0, theta_deg=30.0, time_interval_min=10
):
    """东/南/西三面墙联合可视化（修正时间轴、纵轴显示问题）"""
    plt.rcParams['font.sans-serif'] = ['SimHei', 'Microsoft YaHei']
    plt.rcParams['axes.unicode_minus'] = False

    walls = ['east', 'south', 'west']
    wall_colors = {'east': '#1E90FF', 'south': '#FF4500', 'west': '#32CD32'}
    wall_names = {'east': '东墙', 'south': '南墙', 'west': '西墙'}

    # 构造采样时间（8:00-18:00核心时段，避免无效数据干扰）
    base_date = datetime(target_date.year, target_date.month, target_date.day)
    sample_times = [base_date + timedelta(minutes=i) for i in range(8*60, 18*60 + 1, time_interval_min)]

    # 初始化数据
    joint_data = {}
    for wall in walls:
        joint_data[wall] = {'time_labels': [], 'E_work_list': []}

    # 遍历采样时间计算数据
    for t in sample_times:
        for wall in walls:
            res = calculate_shaded_indoor_work_plane(t, lat, lng, H, l, 1.0, theta_deg, wall)
            if res['alt_deg'] > 0:
                joint_data[wall]['time_labels'].append(t.strftime("%H:%M"))
                joint_data[wall]['E_work_list'].append(res['E_work_shaded'])

    # 绘制图表（2行1列：室内照度对比+J值对比）
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True, figsize=(16, 10))
    fig.suptitle(
        f'东/南/西三面墙 遮阳后室内照度+J值联合对比 | H={H},l={l},θ={theta_deg}°\n'
        f'{base_date.strftime("%Y-%m-%d")} | 纬度{lat:.1f}°N | 教室+Low-E玻璃',
        fontsize=15
    )

    # 子图1：室内工作面照度对比
    ax1.set_title('遮阳后室内工作面照度日内变化', fontsize=13)
    ax1.set_ylabel('室内照度 / lux')
    ax1.grid(True, linestyle='--', alpha=0.6)
    all_E_work = []
    for wall in walls:
        all_E_work.extend(joint_data[wall]['E_work_list'])
    if all_E_work:
        ax1.set_ylim(bottom=0, top=min(max(all_E_work) * 1.1, 600))  # 限制纵轴范围，避免峰值遮挡
    for wall in walls:
        ax1.plot(
            joint_data[wall]['time_labels'],
            joint_data[wall]['E_work_list'],
            color=wall_colors[wall],
            linewidth=2.5,
            label=wall_names[wall]
        )
    ax1.axhline(y=100, color='g', linestyle='--', linewidth=2, label='住宅阈值100lux')
    ax1.axhline(y=300, color='m', linestyle='--', linewidth=2, label='教室阈值300lux')
    ax1.legend(fontsize=10)

    # 子图2：J值日内变化（按墙面分别计算）
    ax2.set_title('优化目标量J日内变化', fontsize=13)
    ax2.set_xlabel('时刻')
    ax2.set_ylabel('优化目标量J（目标→0）')
    ax2.grid(True, linestyle='--', alpha=0.6)
    # 计算每个墙面的J值时间序列
    for wall in walls:
        J_list = []
        valid_times = []
        for t in sample_times:
            single_J = calculate_single_J(t, lat, lng, l, theta_deg, wall)
            shaded_res = calculate_shaded_indoor_work_plane(t, lat, lng, l=l, theta_deg=theta_deg, wall=wall)
            if shaded_res['alt_deg'] > 0:
                J_list.append(single_J['J'])
                valid_times.append(t.strftime("%H:%M"))
        ax2.plot(
            valid_times, J_list,
            color=wall_colors[wall],
            linewidth=2.5,
            label=f'{wall_names[wall]} J值'
        )
    ax2.axhline(y=0, color='k', linestyle='-', linewidth=1.5, alpha=0.8, label='目标值0')
    ax2.legend(fontsize=10)

    # 优化横轴标签
    if joint_data['south']['time_labels']:
        step = max(1, len(joint_data['south']['time_labels']) // 8)
        ax2.set_xticks(joint_data['south']['time_labels'][::step])
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.subplots_adjust(top=0.90)
    plt.show()

# ===================== 主程序（可直接运行，修改参数在此处） =====================
if __name__ == "__main__":
    # 核心参数（可根据需求修改）
    TARGET_DATE = datetime(2025, 12, 22)  # 冬至日
    TARGET_LAT = 40.0                     # 40°N（如北京）
    TARGET_LNG = 116.0                    # 116°E（如北京）
    L_VALUE = 1.0                         # 遮阳挑出长度（m）
    THETA_VALUE = 30.0                    # 遮阳板角度（°）
    WALL = 'south'                        # 目标墙面（可改为'east'/'west'）
    TIME_INTERVAL_MIN = 10                # 采样间隔（分钟）

    # 1. 生成三面墙联合可视化图表（修正后可正常显示）
    print("正在生成三面墙联合对比图表...")
    plot_3walls_joint_shaded_indoor_work_plane(
        target_date=TARGET_DATE,
        lat=TARGET_LAT,
        lng=TARGET_LNG,
        H=6.0,
        l=L_VALUE,
        theta_deg=THETA_VALUE,
        time_interval_min=TIME_INTERVAL_MIN
    )

    # 2. 计算单个时刻J值（正午12:00）
    test_time = datetime(2025, 12, 22, 12, 0)
    single_J_res = calculate_single_J(
        test_time, TARGET_LAT, TARGET_LNG,
        l=L_VALUE, theta_deg=THETA_VALUE, wall=WALL
    )
    print("\n=== 单个时刻（12:00）J值计算结果 ===")
    for k, v in single_J_res.items():
        print(f"{k}: {v}")

    # 3. 计算当日J_day
    daily_J_res = calculate_daily_J(
        TARGET_DATE, TARGET_LAT, TARGET_LNG,
        l=L_VALUE, theta_deg=THETA_VALUE, wall=WALL,
        time_interval_min=TIME_INTERVAL_MIN
    )
    print("\n=== 当日J_day计算结果 ===")
    for k, v in daily_J_res.items():
        print(f"{k}: {v}")