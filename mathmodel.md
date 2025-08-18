# 2024 A

### Problem 1

由等距螺线的定义，各个把手所在的位置可以用如下极坐标方程表示

$$r=\frac{55}{2\pi}\theta \tag{1}$$

积分得，等距螺线的弧长为

$$L=\frac{55}{4\pi}\Delta\left(\theta\sqrt{\theta^{2}+1}+\ln\left(\theta+\sqrt{\theta^{2}+1}\right)\right) \tag{2}$$

注: $\Delta$ 的含义为 ${|}^{\theta_{1}}_{\theta_{2}}$ ,另外记 $k=\frac{55}{2\pi}$ ，下同

进而可以得到整个曲线的弧长为 $442.59\mathrm{m}$ ，于是，在 $t$ 时刻后，龙头进入了 $442.59-t$ 处，需要解出 $(2)$ ，即可得到龙头所在的 $\theta_{0}$ .

$$442.59-t=\frac{55}{4\pi}\Delta\left(\theta\sqrt{\theta^{2}+1}+\ln\left(\theta+\sqrt{\theta^{2}+1}\right)\right) \tag{3}$$

下一步计算龙身 $i$ 前把手所在的 $\theta_{i}$ ，由于龙身是一个直线且不可弯曲的刚体，因此当 $t$ 足够大而龙头足够接近螺线中心时，无法用螺线的弧长来代替龙身的直线长度，此时需要进行迭代。  
考虑第 $i$ 个点和 $i+1$ 个点，前者的极坐标为 $(k\theta_{i},\theta_{i})$ ，以之为圆心，做出一个半径为 $r_{0}$ 的圆，其参数方程为

$$r_{i+1}^{2}-2r_{i+1}r_{i}\cos(\theta_{i}-\theta_{i+1})+r_{i}^{2}=r_{0}^{2} \tag{4}$$

其中需要满足 $\theta_{i}<\theta_{i+1}\le 16\pi$ ，代入 $(1)$ 得：

$$\theta_{i+1}^2-2\theta_{i+1}\theta_{i}\cos(\theta_{i+1}-\theta_{i})+r_{i}^{2}=\frac{r_{0}^{2}}{k^{2}} \tag{5}$$

代入 $r_{0}=341-27.5\times 2=286$ ，对每个时刻分别求解 $(2)$ 得到 $\theta_{0}$ ，进而迭代 $(4)$ 得到 $\theta_{i}$  
具体的直角坐标，可以由以下式子得到

$$x_{i}=k\theta_{i}\cos\theta_{i}\tag{6}$$
$$y_{i}=k\theta_{i}\sin\theta_{i}\tag{7}$$

**下面介绍一种新做法**

由于在极坐标中， $v_{0}=\sqrt{v_r^2+v_\theta^2}=\sqrt{\dot{r}^2+(r\dot{\theta})^2}$  
进而代入各个参数得到了

$$||\boldsymbol{v_{0}}||=k|\dot{\theta}|\sqrt{1+\theta^2}\tag{8}$$

化简得到微分方程

$$\frac{\mathrm{d}\theta}{\mathrm{d} t} =\frac{2\pi v_0}{d\sqrt{1+\theta^2}}\tag{9}$$

其初值为$\theta(0)=32\pi$，之后同上

**速度求解**

观察$(5)$式子，并对$t$微分:

$$
\theta_{i+1}' \left[ \theta_{i+1} - \theta_i \cos\Delta\theta + \theta_{i+1}\theta_i \sin\Delta\theta \right] + \\
\theta_i' \left[ \theta_i - \theta_{i+1} \cos\Delta\theta - \theta_{i+1}\theta_i \sin\Delta\theta \right] = 0\tag{10}$$

化简得到递推关系

$$
\boxed{
\frac{\dot{\theta}_{i+1}}{\dot{\theta}_{i}}= \frac{\theta_i - \theta_{i+1} \cos(\theta_{i+1}-\theta_{i}) - \theta_{i+1}\theta_i \sin(\theta_{i+1}-\theta_{i})}{\theta_i \cos(\theta_{i+1}-\theta_{i}) - \theta_{i+1} - \theta_{i+1}\theta_i \sin(\theta_{i+1}-\theta_{i})}\tag{11}
}
$$

初值 $\dot{\theta}_0=\frac{1}{k\sqrt{\theta_{0}^{2}+1}}$ ，另外由 $(8)$ 得到实际速度。  
对于本题应该注意所求的龙头索引为 $0$ ，龙尾索引是 $221+1+1=223$.












