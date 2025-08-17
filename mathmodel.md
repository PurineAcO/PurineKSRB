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

