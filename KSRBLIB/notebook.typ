#import "lib.typ" : *

// #pagebreak()

// 以下是正文部分(可选)
#show: project.with(
  title: "知春饭桶年鉴",
  author:"Know Spring Rice Bucket"
  )


 
#pagebreak()


#text(
  size: 12pt,       // 本页字体大小
  font: ("New Computer Modern","Source Han Serif SC"),
  
)[
#set outline(depth: 3, indent: auto)
#show outline: set align(center)

#let outline-title(s) = text(size: 20pt, s.clusters().intersperse(h(1em)).join())
#show outline.entry.where(
  level: 1
): it => {
  v(20pt, weak: true)
  strong(it)
}
#show outline.entry.where(
  level: 2
): it => {
  v(16pt, weak: true)
  it
}
#show outline.entry.where(
  level: 3
): it => {
  v(16pt, weak: true)
  it
}
#outline(title: outline-title("目录"))

#pagebreak()
]

#let Ma=$"Ma"$

#let rescnt=counter("reser")
#let res(it)={text[#rescnt.step()
*Result #context rescnt.display():* #it
]
}

= 混水器流动传热模型


#pagebreak()
= 电磁对接装置拓扑及控制策略研究@Ruan_2023_ElectromagneticDocking

本篇是本人承担的由他人主导的某个用于参加无意义比赛的课题的理论部分的总结.事实上,我一点都没有看出来这个项目具有任何能够成功的潜质.之所以留在了《年鉴》中,完全是由于这种做法可能形成一种建立复杂动力学控制模型的范式.

== 电磁拓扑结构

(本来此处有一个描述,不过负责人放弃了这种想法,故删除.)

=== 基于欧拉角的随体坐标系定义

#figure(image("assets/image-1.png",width: 45%),caption: [随体坐标系定义])

定义两星的随体坐标系中$X$轴指向外侧,$Y$轴均指向各自1号线圈方向,其余按照右手定则取定.根据地面绝对坐标系定义两星的欧拉角为$(phi_T,theta_T,psi_T)^top$和$(phi_C,theta_C,psi_C)^top$.

由此得到两星的随体坐标系的变换关系为:

$ bold(R_"TC")=bold(R_"Cbe"^(-1))bold(R_"Tbe") $<21>

其中$bold(R_"Cbe")$和$bold(R_"Tbe")$分别为:

$ bold(R_"be")=mat(cos theta cos psi,-cos theta sin psi,sin theta;cos phi sin psi + cos psi sin phi sin theta,cos phi cos psi - sin phi sin psi cos theta,-cos theta sin phi;sin phi sin psi - cos phi cos psi sin theta,sin phi cos psi + cos phi sin psi sin theta,cos theta cos phi;) $<22>

=== 基于四元数的随体坐标系定义 <C212>

除此之外,还可以用四元数进行姿态的刻画.假设某向量在地面参考系中为$bold(r_G^')=(0,bold(r_G)^top)^top$,那么可以用四元数$q$来表示其在某个随体坐标系B的坐标为:

$ bold(r_B^')=q times.o bold(r_G^') times.o q^* $<221>

其中这里的$q$是一个单位四元数

$ q=w+x bold(i) + y bold(j) +z bold(k) $



四元数的描述和欧拉角大部分是等价的,四元数的优越性在于能解决欧拉角带来的万向节问题,避免出现混乱.#footnote[具体内容可以参考——#link("https://www.zhihu.com/tardis/zm/art/78987582?source_id=1005")[四元数与旋转]]

== 电磁力模型

我们考虑下面这个实物模型:

#figure(image("assets/image-2.png",width: 100%),caption: [机械辅助导向式电磁对接装置])

将其进行简化:

#figure(image("assets/image-3.png",width: 100%),caption: [电磁线圈构型与尺寸标记])

该部分电磁线圈的构型和尺寸以及重要电磁参数如下所示:

#show table: three-line-table

#figure(table(columns: 5,[$D_0$],[$L_0$],[$H_0$],[$H_c$],[$T_c$],[300mm],[45mm],[13.72mm],[15.22mm],[1.5mm]),caption: [线圈构型尺寸])

#figure(table(columns: 7,[槽满率$eta$],[线径$italic(Phi)$],[匝数$n$],[特征电阻$R$],[特征电感$L$],[最大电流$I_M$],[质量$m$],[62%],[1.5mm],[216],[1.9$Omega$/45℃],[13.5mH\~3.0mH],[16.4A],[2765g+550g]),caption: [线圈电磁和力学参数])<T22>

=== 基于有限元分析方法的数值分析

为了将磁场发展限制在一个可计算的范围内,设置一个3倍于最大扩展半径的计算域,@F25 展示了计算域的设置.

#figure(image("assets/image-7.png",width: 100%),caption: [计算域设置])<F25>

线圈作为励磁的源,其电流密度描述为:

$ bold(J_"coil")=(N I)/(pi r_"coil"^2)bold(e_"coil") $<23>

在整个空间中,存在磁场发展的边界关系:

$ bold(B)=mu_0 mu_r bold(H) $<24>

如果存在包络整个铜线的铁芯,其很强的非线性和磁饱和特征将导致其本构关系变为*非线性*,此时仅可以通过磁滞回曲线来求解.整个磁场由环路定理控制:

$ nabla times bold(H)=bold(J_"coil") $<25>

对于电磁力的计算,目前主要基于Maxwell张量的积分计算.考虑环路定理在一个积分体$Omega$上有:

$ bold(F)=integral.triple_(Omega) (nabla times bold(H)) times bold(B) dif V= integral.triple_(Omega)  bold(B) dot nabla bold(H)-1/2 nabla(bold(B dot H)) dif V\  $ 

进一步提出Maxwell张量$bold(T)$:

$ bold(T)_(i j)=B_(i)H_(j)-1/2 delta_(i j)bold(B dot H) $<26>

由Guass定理:

$ bold(F)=integral.triple_Omega nabla dot bold(T) dif V= integral.double_(partial Omega) bold(T) dif S $<27>

运用有限元分析软件模拟@T22 所示线圈#footnote[不加外围的硅钢],得到 @F27 所示的结果#footnote[$s_"TC"$实际上指的是C线圈和T线圈距离的一半.],曲线使用3次样条插值拟合#footnote[这个结果和原论文中提到的结果有较大差异,相差了大约5倍之多,尽管趋势是一致的.我们排除了2D/3D几何对称性对结果产生的影响,尽管2D数值会比3D偏低0.7%,但我们认为3D情形除了会大幅增加计算量以外无任何实际意义.我们在之前还排除了"线圈几何分析"对结果产生的影响#footnote[详见知春饭桶·#link("https://mp.weixin.qq.com/s/krHwPkr5vh6qBFvG-noFVA")[一则电磁体建模案例]]\.为了简化计算,我们将$N$匝线圈的共同作用简化到1匝线圈作用,影响仅为1%,亦不显著.综上,我们有理由认为原文献@Ruan_2023_ElectromagneticDocking\的结果不是准确的,或者采用了文中未提及的方法.]:

#figure(image("assets/untitled.png",width:100%),caption: [@T22 裸线圈有限元仿真结果])<F27>

=== 精确解析

#figure(image("assets/image-8.png",width: 70%),caption: [电磁力和力矩模型的向量空间关系])<F2226>

对于C线圈上的位于$bold(a_C)$的某一个电流元$i_C dif bold(l_C)$,其感受到来自于T线圈位于$a_T$上的电流元$i_T dif bold(l_T)$的磁感应强度为:

$ dif bold(B_T)=(mu_0 i_T)/(4 pi) dot (bold(h_"TC") times dif bold(l_T))/(h_"TC"^3) $<28>

进一步,积分得到该部分感受到的力和力矩为:

$ dif bold(F_C)=(n_C n_T i_C i_T mu_0)/(4 pi) dot (integral.cont_T (bold(h_"TC") times dif bold(l_T))/(h_"TC"^3)) times dif bold(l_C) $<29>

$ dif bold(tau_C)=(n_C n_T i_C i_T mu_0)/(4 pi) dot bold(a_C) times ((integral.cont_T (bold(h_"TC") times dif bold(l_T))/(h_"TC"^3)) times dif bold(l_C)) $<210>

对其进行积分,得到:

$ bold(F_C)=(n_C n_T i_C i_T mu_0)/(4 pi) dot integral.cont_C  (integral.cont_T (bold(h_"TC") times dif bold(l_T))/(h_"TC"^3)) times dif bold(l_C) $<211>

$ bold(tau_C)=(n_C n_T i_C i_T mu_0)/(4 pi) dot integral.cont_C bold(a_C) times ((integral.cont_T (bold(h_"TC") times dif bold(l_T))/(h_"TC"^3)) times dif bold(l_C)) $<212>

=== 远场近似  <C2231>

考虑当线圈距离足够远的情形#footnote[因$norm(bold(s_"TC")) < 4 norm(bold(a_"T"))$,导致模型的误差过大,本案例不适用.可以考虑将@215 进一步进行Taylor展开,得到中近场的近似模型,此情况下计算量增加过大,难以为控制律运用.]:下面考虑Stokes定理,其中$bold(c)$是常矢量,$phi$是一个标量场:

$ #box(stroke:0.75pt,outset:2pt,baseline: 40%)[$ bold(c) dot integral.cont phi dif bold(l) $] = integral.cont phi bold(c) dif bold(l) = integral.double nabla times (phi bold(c)) dif bold(S)   = integral.double nabla phi times  bold(c) dot dif bold(S) = integral.double dif bold(S) times nabla phi dot bold(c) = #box(stroke:0.75pt,outset:2pt,baseline: 40%)[$ bold(c) dot integral.double dif bold(S) times nabla phi $] $

由于$bold(c)$是任意常矢量,消去$bold(c)$得到:

$ integral.cont phi dif bold(l) = integral.double dif bold(S) times nabla phi $<214>

如图@F2226,考虑T线圈上的电流元$i_T dif bold(l_T)$,以及观察点$bold(a_C)$,从看去的磁矢势为:

$ bold(A)=(mu_0 i_T)/(4 pi) integral.cont_T (dif bold(l_T))/(||bold(h_"TC")||)  $<213>

根据矢量恒等式@214,得到:

$ bold(A) =& (mu_0 i_T)/(4 pi) integral.cont (dif bold(l_T))/(||bold(h_"TC")||) =  (mu_0 i_T)/(4 pi) integral.double dif bold(S) times nabla (1/(||bold(h_"TC")||)) \ = & (mu_0)/(4 pi) bold(m) times (bold(h_"TC"))/(h_"TC"^3) approx (mu_0)/(4 pi) bold(m) times (bold(s_"TC"))/(s_"TC"^3) $<215>

上面等式成立的条件是$||bold(s_"TC")|| gt.double ||bold(a_"T")||$,即观察点处在足够远的地方,进一步得到:

$ bold(B) = nabla times bold(A) = (mu_0)/(4 pi)((3(bold(m) dot bold(s)) bold(s))/(s^5) - (bold(m))/s^3) $<216>

两个线圈均视为偶极子,由此计算得到电磁力:

$ bold(F)= (3 mu_0)/(4 pi)[((bold(m_T dot m_C))/(s_"TC"^5) - (5(bold(m_T dot s_"TC"))(bold(m_C dot s_"TC")))/(s_"TC"^7))bold(s_"TC") + (bold(m_T dot s_"TC"))/(s_"TC"^5) bold(m_C) + (bold(m_C dot s_"TC"))/(s_"TC"^5) bold(m_T)] $<217>

以及电磁力矩#footnote[也可以利用电磁力对作用点在随体坐标系下取力矩加以实现,此种方法显然是更加偏向于场的观念,个人认为这不是完全必要的,尤其是在接续的六自由度分析中.]:

$ bold(tau) = (mu_0)/(4 pi) bold(m_C) times ((3(bold(m_T) dot bold(s_"TC")) bold(s_"TC"))/(s_"TC"^5) - (bold(m_T))/s_"TC"^3) $<218>

=== 含有永磁铁的静磁场求解

- *在COMSOL中定义的静磁场求解格式*

对于稀土磁铁,在其工作点附近,大致满足以下关系#footnote[作者根本不知道,承担此项任务的负责人到底在想什么,事实上,*使用仿真软件进行磁力的计算是不合适的,为此应当采取更为准确的实验标定方法.*在实际使用COMSOL进行仿真的时候,难以得到完全合乎物理原则的结果,甚至难以逻辑自洽,这令人不得不怀疑历史上从事类似所有实验并声称使用有限元方法的人的居心了!]:

$ bold(B) = mu_0 mu_"rec"bold(H) + bold(B_r) = mu_0 (bold(H)+bold(M)) $<219>

其中,$bold(B_r)$被称为剩余磁通密度,$mu_"rec"$称为回复磁导率.

- *基于本构关系的离散化求解方法*

吉林大学的瞿川提出了一种对于特殊形状永磁体的磁力推导手段@qu_chuan_2018_12012119,以基本形状的钕铁硼永磁体为研究对象,基于静磁场分析方法,建立永磁体间磁力和磁刚度#footnote[指的是磁力随位移的变化率,定义为$k=-(dif F)/(dif x)$.]的参数化数学理论模型,阐明磁力和磁刚度的影响因素.结合永磁体参数,分别建立平行和垂直磁化的两个圆柱体永磁体、两个长方体永磁体、圆柱体和长方体永磁体间磁力和磁刚度的数学理论模型,最后阐述磁力和磁刚度数学理论模型的高效求解方法.

在静磁场中存在以下场关系:

$ cases(nabla times bold(H) = 0,nabla dot bold(B) = 0) $<219-1>

引入磁标势#footnote[COMSOL中的说法,文献称"标量势"]$phi_m$

$ bold(H)=-nabla phi_m $<219-2>

结合@219 得到:

$ nabla^2 phi_m = nabla dot bold(M) $<219-3>

假设永磁铁的磁化强度$bold(M)$仅存在于磁体内部,将@219-3 改写为积分形式得到#footnote[这是一个与Green函数有关的积分结果,详见有关方面参考书.]:

$ phi_m = -1/(4 pi) integral.triple_V (nabla dot bold(M(x')))/(norm(bold(x)-bold(x'))) dif V +1/(4 pi) integral.double_(partial V) (bold(M(x')) dot bold(n))/(norm(bold(x-x'))) dif S $<219-4>

其中,$bold(x)$是场中某点,$bold(x')$是场源,$bold(n)$表示的是$partial V$的外法向.结合磁化强度和磁荷密度的关系,得到:

$ phi_m = 1/(4 pi) integral.triple_V (rho_m (bold(x')))/(norm(bold(x)-bold(x'))) dif V +1/(4 pi) integral.double_(partial V) (sigma_m (bold(x')))/(norm(bold(x-x'))) dif S $<219-5>

结合@219-2 和@219,并且由于磁铁是均匀磁化,$rho_m (bold(x')) equiv 0$,得到:

$ bold(B(x)) = mu_0/(4 pi) integral.double_(partial V) (sigma_m (bold(x'))(bold(x-x')))/(norm(bold(x-x'))^3) dif S $<219-6>

对其进行离散化处理,

$ bold(B(x)) = mu_0/(4 pi) sum_k (sigma_m (bold(x_k))(bold(x-x_k)))/(norm(bold(x-x_k))^3) Delta A_k  $<219-7>

永磁铁表面的磁荷密度受到回复磁导率#footnote[以后简单记为相对磁导率$mu_r$,有利于体现该物理量的类比性质.]的影响:@rovers2013modeling

$ sigma_m = (bold(B_r) (mu_r^2+3))/(mu_0 (mu_r+1)^2) $<219-8>

依旧进行有限元离散化求解,得到力:

$ bold(F) = mu_0/(4 pi) sum_j sum_k (sigma_m (bold(x_j)) sigma_m (bold(x_k))(bold(x_j-x_k)))/(bold(norm(x_j-x_k))^3) Delta A_j Delta A_k $<219-9>

进一步代入@219-8 得到:

$ bold(F) = plus.minus (B_r^2 (mu_r+3)^2)/(4 pi mu_0 (mu_r+1)^4) sum_j sum_k (bold(x_j-x_k))/(norm(bold(x_j-x_k))^3) Delta A_j Delta A_k $<219-10> 

正负号需要根据南北极进行手动确认.



== 运动与时域推进

由于不考虑整个过程中的变形,这将是一个刚体动力学问题.时域推进的方法可以分为显式动力学和隐式动力学,前者基于显含时间的力学定律进行运动的描述,后者基于不显含时间的若干微分方程组描述运动.

我们采用隐式动力学方法,并使用四元数进行描述.@zhang2021arrestinghal

Lagrange方程描述了基于广义坐标的动力学关系,我们定义基于绝对质心位置坐标$bold(r)$和姿态四元数$bold(theta)$(详见@C212)的广义坐标$bold(q)$

$ bold(q)=(bold(r)^top,bold(theta)^top)^top = (x,y,z,theta_0,theta_1,theta_2,theta_3)^top  $<220>

我们设刚体在随体坐标系下的角速度为$bold(omega)$,满足以下关系:

$ dot(bold(theta))= 1/2 bold(Omega(omega) theta) $ <221>

其中$bold(Omega(omega))$指的是一个关于角速度$bold(omega)$的矩阵:

$ bold(Omega(omega))=mat(0,-omega_x,-omega_y,-omega_z;omega_x,0,omega_z,-omega_y;omega_y,-omega_z,0,omega_x;omega_z,omega_y,-omega_x,0)=mat(0,bold(-omega^top);bold(omega),bold(tilde(omega))) $

进一步得到:

$ bold(omega =2  G dot(theta) ) $ <222>

其中这里的

$ bold(G) = mat(-theta_1,theta_0,theta_3,-theta_2;-theta_2,-theta_3,theta_0,theta_1;-theta_3,theta_2,-theta_1,theta_0) $ <223>

动能表示为,其中$bold(J)$表示惯量矩阵:

$ T =& 1/2 m(dot(x)^2+dot(y)^2+dot(z)^2) + 1/2 bold(omega^T J omega) \ =& 1/2 m bold(dot(r)^top dot(r)) +1/2 (2bold(dot(theta)^top G^top dot J) dot 2 bold(G dot(theta))) $

合记为:

$ T = 1/2 bold(dot(q)^top M dot(q)) $<224>

其中这里的$bold(M)$称为广义质量:

$ bold(M)=mat(m bold(I_(3 times 3)),bold(0);bold(0),4bold(G^top J G)) $

根据Lagrange方程:

$ (dif)/(dif t)((partial T)/(partial bold(dot(q)))) - (partial T)/(partial bold(q))=bold(Q) $<225>

进行一步解析展开#footnote[有文献将@226 画框部分记作$bold(Q_q)$,称为广义惯性力.@zhang2021arrestinghal]:

$ bold(M dot.double(q))+ #box(stroke:0.75pt,outset:2pt,baseline: 40%)[$ bold(dot(M)dot(q)) - ((partial T)/(partial bold(q)))^top $]=bold(H f) $<226>

其中#footnote[原文献中把$bold(0_(3 times 3))$误写成了$bold(0_(3 times 4))$@zhang2021arrestinghal]

$ bold(H)=mat(bold(I_(3 times 3)),bold(0_(3 times underline(3)));bold(0_(4 times 3)),2bold(G^top)) $

== 控制律

将整个对接过程分为远场接近、姿态调节、滚转控制三个阶段.均使用PID控制器.

=== 远场接近


#let sgn = $"sgn"$

为了实现航天器对接时的完全柔性化,我们需要设定一个目标使得收尾速度接近于0,选取常见的加速度反转式运动规划方案,进行如下规划:

$ a = a_0 sgn(t_"mid" - t) $<238>

这样得到以下方程:

$ v_max^2 = a_0 x_0 $<239>

我们通过给定$v_max$来决定这个运动过程,并以这个$v_max$引发的$x(t)$作为控制输入.为了使得$a_0$得以稳定,需要控制两端磁极的相对距离处于一个恒定的距离$x_c$,为此,当接近过程中,需要调控伺服电机,使得其拉动磁铁向后.我们设计伺服电机的电压$u$输出作为被控量,记此时伺服电机角速度为$omega$,两个磁铁对接机构的距离为$x$,那么$e = x-x_c$,以此建立PID控制律:

$ v_m=K_p e + K_d (dif e)/(dif t) + K_i integral e dif t $ <240>

经过$dif t$后,磁铁向后移动了$omega R dif t$,而整个装置向前了$v dif t$:

$ e (t+ dif t) = e(t) - omega R dif t + v dif t $ <241>

可以认为:

$ (dif v)/(dif t) = F(x_c) $

除此之外,由于信号的延迟和摩擦等物理因素,还需要考虑电机执行控制律所带来的时延$tau$.对于一个舵机,假设其转动惯量为$J$,阻尼因数为$B$,其转动满足

$ J dot(omega) +B omega = K_t u $<242>

记$T=J/B$,$K=(K_t R)/B$,传递函数为:

$ #box(stroke:0.75pt,outset:2pt,baseline: 40%)[$ G(s) = (K(K_d s^2+K_p s+K_i)e^(-tau s ))/(s(T s+1)) $] $<243>


#pagebreak()

= 频域上的计算流体力学方法

本节主要介绍一种在频域上求解计算流体力学问题时域解的方法@crouch2009origin@crouch2007predicting,并将这个问题应用于部分有一定研究价值的算例中.本课题由知春饭桶单独掌握.

== 流动的物理模型

=== Reynold 输运定理

先考虑以下引理:设有两个向量$bold(r) = (x(t),y(t),z(t))^top,bold(r_0) = (a,b,c)^top$,记$bold(v) = ((dif x)/(dif t),(dif y)/(dif t),(dif z)/(dif t))^top = (u,v,w)^top$,两个向量的微分可以通过Jacobi行列式相互转换:$dif x dif y dif z = |bold(J)| dif a dif b dif c$,那么有:

$ dif/(dif t) |bold(J)| = |bold(J)| nabla dot bold(v) $<3110>

给出一个推导:

$ (dif)/(dif t)|bold(J)| = (dif)/(dif t) mat(delim:"|",(partial x)/(partial a),(partial x)/(partial b),(partial x)/(partial c);(partial y)/(partial a),(partial y)/(partial b),(partial y)/(partial c);(partial z)/(partial a),(partial z)/(partial b),(partial z)/(partial c)) $<3111>

考虑对某一个分量进行求导

$ (dif)/(dif t) (partial x_i)/(partial a_j) &= (partial)/(partial a_j) (dif x_i)/(dif t) = (partial v_i)/(partial a_j) = (partial v_i)/(partial x_k) (partial x_k)/(partial a_j) \ &= (partial v_i)/(partial x) (partial x)/(partial a_j) +(partial v_i)/(partial y) (partial y)/(partial a_j)+ (partial v_i)/(partial z) (partial z)/(partial a_j) $ <3112>

于是上面@3111 化简成为

$ (dif)/(dif t)|bold(J)| = (partial u)/(partial x) mat(delim:"|",(partial x)/(partial a),(partial x)/(partial b),(partial x)/(partial c);(partial y)/(partial a),(partial y)/(partial b),(partial y)/(partial c);(partial z)/(partial a),(partial z)/(partial b),(partial z)/(partial c))+ (partial v)/(partial y) mat(delim:"|",(partial x)/(partial a),(partial x)/(partial b),(partial x)/(partial c);(partial y)/(partial a),(partial y)/(partial b),(partial y)/(partial c);(partial z)/(partial a),(partial z)/(partial b),(partial z)/(partial c))+(partial w)/(partial z) mat(delim:"|",(partial x)/(partial a),(partial x)/(partial b),(partial x)/(partial c);(partial y)/(partial a),(partial y)/(partial b),(partial y)/(partial c);(partial z)/(partial a),(partial z)/(partial b),(partial z)/(partial c)) = |bold(J)| nabla dot bold(v) $

这就是@3110,我们接着考察一个控制体$Omega(t)$,其体内存在一种连续的物理量$f=f(bold(r),t)$,考察它的体积分的导数,但是这个体积分的积分区域是随着时间变化的,为此我们可以将其变化到一个不随时间变化的区域$Omega_0$上:

$ & underline((dif)/(dif t) integral_(Omega(t)) f dif V )= (dif)/(dif t) integral_(Omega_0) f |bold(J)| dif V_0 = integral_(Omega_0)  (dif)/(dif t) (f |bold(J)|) dif V_0 =integral_(Omega_0) |bold(J)|(dif f)/(dif t) + f (dif|bold(J)|)/(dif t) dif V_0 \ &= integral_(Omega_0) |bold(J)|((partial f)/(partial t) +bold(v) dot nabla f) + f (|bold(J)| nabla dot bold(v)) dif V_0 = integral_(Omega_0) |bold(J)|((partial f)/(partial t) + bold(v) dot nabla f + f nabla dot bold(v)) dif V_0  \ &= integral_(Omega_0) |bold(J)|((partial f)/(partial t) + nabla dot (f bold(v))) dif V_0  = underline(integral_(Omega (t)) ((partial f)/(partial t) + nabla  dot (f bold(v))) dif)  V $<3113>


@3113 展示了Reynold输运方程,这个方程的关键点在于,一个区域内某个物理量的表观增加量,等于其内生的增加量和从边界流入的增加量之和(Guass).

== NS控制方程

现在假设$f$代表密度$rho$,对于一个$Omega(t)$而言,流动中质量没有补充和亏损,那么上面@3113 左边项恒为0,不论此时流体被指定到哪一个位置.

$ 0 equiv  integral_Omega(t) ((partial f)/(partial t) + nabla dot (f bold(v))) dif V  $

化成微分形式,有*连续性方程*:

$ (partial rho)/(partial t) + nabla dot (rho bold(v)) = 0 $<3114>

对于一个二维问题,引入速度$u$和$v$,就得到了:

#let partialer(it,it2) = {$(partial it)/(partial it2)$}

$ partialer(rho,t) + partialer((rho u),x) + partialer((rho v),y) = 0 $<3115>

继续假设$f$表示动量,

$ bold(f) = partialer((rho bold(v)),t) + nabla dot (rho bold(v) times.o bold(v)) $<3116>

其中这里的$bold(v) times.o bold(v) := (u bold(i) + v bold(j))(u bold(i)+ v bold(j)) = u^2 bold(i) + v^2 bold(j)$,写成分立的$X$,$Y$形式就是:

$ cases(partialer((rho u),t)+partialer((rho u^2),x)+partialer((rho u v),y)=f_x,partialer((rho v),t)+partialer((rho v^2),y)+partialer((rho u v),x)=f_y) $<3117>

下面着重分析一下受力,事实上根据材料力学的一些理论也可以进行理解,我们可以认为在流体微团受到两种力,一类是体积力,比如重力、电磁力、圆周运动中附加的离心力,也有一部分是表面力,这部分主要是粘性力和压力梯度.

#figure(image("assets/image-4.png",width:50%),caption: [流体微团受到的力])

于是我们代入@3117,得到动量输运方程:

$ partialer((rho u),t)+partialer((rho u^2+rho R T),x)+partialer((rho u v),y)=partialer(tau_(x x),x)+partialer(tau_(y y),y) $<3119>

$ partialer((rho v),t)+partialer((rho v^2+ rho R T),y)+partialer((rho u v),x)=partialer(tau_(x y),x)+partialer(tau_(y y),y) $<3119-1>

这里有几点需要说明,一是我们把理想气体状态方程带入了进去,二是我们并没有解析雷诺切应力的具体数值,这部分将由接下来的湍流模型封闭.

最后我们假设这个$f = E = rho C_v T +1/2 rho (u^2+v^2)$,可以得到能量的控制方程:

$ partialer((rho C_v T +1/2 rho (u^2+v^2)),t)+partialer((rho u C_p T +1/2 rho u (u^2+v^2)),x)+partialer((rho v C_p T +1/2 rho v (u^2+v^2)),y) \ =partial/(partial x) (u tau_(x x)+ v tau_(x y) +lambda_"eff" partialer(T,x) )+ (partial)/(partial y)(u tau_(x x) +v tau_(y y)+lambda_"eff" partialer(T,y)) $<31110>

== RANS和湍流模型

=== URANS方法



@3114,@3119,@3119-1,@31110 总共提供了4个方程,但是产生了8个未知数,分别是$u,v,rho,T,tau_(x x),tau_(x y),tau_(y y),lambda_"eff"$,为此,我们需要额外的方程去封闭他们.

这里我们仅仅介绍少部分RANS的内容,简单来说,RANS将将求平均值视为稳态情况的时间平均以及可重复瞬态情况的整体平均,通过把上面的方程全部替换为一种平均意义上的结果,再加上一些湍流模型的修正,来解析整个流场.

=== S-A湍流模型

我们使用的是_Spalart-Allmaras_模型,简称S-A湍流模型.

该模型首先定义了一个求解变量$tilde(nu)$及其控制方程:

#let tv = $tilde(nu)$

$ partialer((rho tv),t)+partialer((rho u tv),x)+partialer((rho v  tv),y) = rho C_(b 1) (1-f_(t 2))tilde(S)tv +1/sigma (nabla dot ((mu+ rho tv )nabla tv) \ + C_(b 2) rho (nabla tv)^2 ) - rho (C_(w 1)f_w - (C_(b 1))/k^2 f_(t 2) )(tv/d)^2 -C_5 (rho tv^2 S^2)/(gamma R T) $<331>

这个湍流模型很长,但是没有引入除了$tv$以外的任何其他变量,这部分将在后面加以补充描述.通过求解出$tv$,就可以由

$ nu_t  = f_(v 1) tv $<332>

得到湍流涡粘性$v_t$,这个参数将会修正粘度$mu_"eff"$和$lambda_"eff"$,其中$mu=mu(T)$为动力粘度,$Pr$为普朗特数,$Pr_t$为湍流普朗特数.

$ mu_"eff" = mu(T) + rho nu_t $<333>

$ lambda_"eff" = (mu(T))/(Pr) + (rho nu_t)/(Pr_t) $<334>

由此封闭了$tau_(x x),tau_(x y),tau_(y y)$:

$ cases(tau_(x x) = 2mu_"eff" partialer(u,x)-2/3 mu_"eff" (partialer(u,x)+partialer(v,y)),tau_(x y) = mu_"eff" (partialer(u,y)+partialer(v,x)),tau_(x x) = 2mu_"eff" partialer(v,y)-2/3 mu_"eff" (partialer(u,x)+partialer(v,y))) $<335>

生成湍流粘度时用到的$f_(v 1)$由以下方程推出:

$ f_(v 1) = (chi^3)/(chi^3+C_(v 1)^3) $<336>

其中$C_(v 1)=7.1$,而湍流粘度比$chi = tv/nu$,$nu = mu/rho$

- *对流和扩散*

原始的S-A湍流模型输运方程表示为:

$ partialer(tv,t) = M(tv) + P(tv) + D(tv) + T $<337>

其中这里的

$ M(tv) = - nabla (tv dot bold(v) )+ 1/sigma (nabla dot ((nu +tv) nabla tv) +C_(b 2) (nabla tv)^2 ) $<338>

表示了对流项和扩散项的作用,其中$sigma=2/3,C_(b 2) = 0.622$

- *湍流产生项*

$ P(tv) = C_(b 1)(1-f_(t 2))tilde(S) tv $<339>

其中

$ f_(t 2) = C_(t 3) exp(- c_(t 4) chi^2) $<3310>

其中$C_(t 3)=1.2,C_(t 4) = 0.5$,此外

$ tilde(S) = max(0.3 Omega,Omega + (f_(v 2) tv)/(kappa^2 d^2)) $<3311>

其中$Omega$为平均涡转速张量

$ Omega = sqrt(2) ||bold(Omega)|| = sqrt(2)/2 ||nabla bold(v) - nabla bold(v^top)||  $<3312>

此外

$ f_(v 2) = 1- chi/(chi f_(v 1) + 1) $<3313>

常数$kappa = 0.41$,$d$表示和壁面的距离.

- *壁面衰减函数*

$ D(tv) = (C_(w 1) f_(w) - (C_(b 1)/(kappa^2) )f_(t 2))(tv/d)^2 $<3314>

其中

$ C_(w 1) = (C_(b 1))/kappa^2 + (1+ C_(b 2))/sigma  $<3315>

== 后处理手段:本征正交分解和动态模态分解

=== 本征正交分解(POD)

本征正交分解是一种基于特征值分解的降维方法,通过对一个数据矩阵进行SVD分解,得到其特征值和特征向量,从而提取出数据中的主要模式@hinze2005proper.

我们假设有一个矩阵$bold(Y) = (bold(y_1),bold(y_2),...,bold(y_n)) in RR^(m times n)$,满足$m >> n$,并且有

$ "rank" bold(Y) = d <= min(m,n) $ <3411>

对其进行奇异值分解得到$bold(Y) = bold(U Sigma V^top) $,其中$bold(U) in RR^(m times m),bold(Sigma) in RR^(m times n),bold(V) in RR^(n times n)$,$bold(U)$和$bold(V)$分别是左奇异向量矩阵和右奇异向量矩阵,而$bold(Sigma)$是一个对角矩阵,其对角线上的元素为奇异值.

$ bold(Sigma) = "diag"(bold(Sigma_0),bold(0)) = mat(mat(sigma_1;,sigma_2;,,...,;,,,sigma_d),bold(0);bold(0),bold(O)) $<3412>

进行代数运算,容易知道$bold(Y^top) bold(u_i) = sigma_i bold(v_i)$,$bold(Y) bold(v_i) = sigma_i bold(u_i)$,这样就得到了$bold(Y^top Y v_i) = sigma_i^2 bold(v_i),bold(Y Y^top u_i) = sigma_i^2 bold(u_i)$,也就是说,$bold(v_i)$和$bold(u_i)$分别是$bold(Y^top Y)$和$bold(Y Y^top)$的特征向量,而$sigma_i^2$是他们的特征值.

现在我们令以下最大值问题

$ max_(tilde(u_1),tilde(u_2),...,tilde(u_ell) in RR^(m times 1)) sum_(i=1)^ell sum_(j=1)^n |chevron bold(y_j),bold(tilde(u)_i)  chevron.r|^2 , "s.t." chevron bold(tilde(u)_i tilde(u)_j) chevron.r = delta_(i j) $<3413>

其中截断位置$ell in (1,d)$.@3413 可以简化成以下形式:

$ max_(tilde(bold(u))_i in RR(m times 1)) ||bold(tilde(U)^top Y)||^2_F ,"s.t." bold(tilde(U)^top U) = bold(I_ell) $<3414>

实际上,@3414 就是找一组标准正交基,使得矩阵$bold(Y)$的投影在Frobenius范数意义下最大,也就是说,我们希望找到一个子空间,使得数据矩阵$bold(Y)$在这个子空间上的投影尽可能大.而$ell$的意义在于进行约等.当$ell = d$时,相当于没有删除任何信息,而当$ell < d$时,相当于删除了某些信息,我们用$epsilon(ell)$来衡量保存信息的比例#footnote[也有的人认为应该定义成$epsilon(ell) = (sum_(i=1)^ell |sigma_i|)\/(sum_(i=1)^d |sigma_i|)$].

$ epsilon(ell) = (sum_(i=1)^ell sigma_i^2)/(sum_(i=1)^d sigma_i^2) $<3415>

下面我们将证明左奇异向量将是@3413 的最优解:

$ ||bold(tilde(U)^top Y)||^2_F = "tr"((tilde(bold(U))^top bold(Y))^top (tilde(bold(U))^top bold(Y))) = "tr"(bold(Y^top Y)) $<3416>

由于$bold(Y^top Y)$至少半正定,因此有

$ "tr"(bold(Y^top Y)) = "tr"(bold(Q Lambda Q^top)) approx sum_(k=1)^ell sum_(i=1)^n lambda_i q_(i k)^2 = sum_(i=1)^n lambda_i c_i  $<3417>

其中$c_i = sum_(k=1)^ell q_(i k)^2 >=0,sum_(i=1)^n c_i = l$,我们这里要求$lambda_1>=lambda_2>=...>=lambda_d>0$,因此有$c_1=...=c_l = 1,c_(l+1) =... =  c_n=0$,这样才使得$tr(bold(Y^top Y))$最大,代回得到了$tilde(bold(U)) = bold(U)$,即为左奇异向量组成的矩阵.

=== 动态模态分解(DMD)

考虑一个线性动力系统:$dot(bold(x)) = bold(A x) $,这个方程的解析解可以表示为$bold(x) = e^(bold(A) t) bold(x_0) $,其中$bold(x_0)$为和时间无关的量,如果矩阵$bold(A)$可对角化,那么将其写成$bold(A = Phi Lambda Phi^(-1))$,其中$Phi = (bold(phi.alt_1),bold(phi.alt_2),...,bold(phi.alt_m)) in CC^(m times m)$,表示DMD中的模态,而$bold(Lambda) = "diag"(omega_1,omega_2,...,omega_m) in CC^(m times m)$,由此得到

$ bold(x)(t) = sum_(k=1)^n bold(phi.alt_k) e^(omega_k t) bold(b_k) = bold(Phi) e^(bold(Omega) t) bold(b) $<3421>

以上是对于连续系统的解析,下面考虑只有离散时间$Delta t$的情形@poplingher2019modal

$ bold(x_(k+1) )= bold(x)((k+1)Delta t) = e^(bold(cal(A)) (k+1) Delta t) bold(x_0) = e^(bold(cal(A)) Delta t) bold(x_k) $<3422>

这个系统可以被写成$bold(x)(t) = bold(Phi Lambda^k b)$,DMD就是用来寻找$bold(A)$的低阶近似,最小化时间推进的残差,假设存在两个连续的时间序列$bold(X)_m = (bold(x_1),bold(x_2),...,bold(x_m)),bold(X)_(m+1) = (bold(x_2),bold(x_3),...,bold(x_(m+1)))$,他们将满足$bold(X_(m+1)) = bold(A) bold(X)_m$,因此$bold(A)$的最佳估计为@3423,其中$(dot)^dagger$表示伪逆#footnote[定义$bold(A)^dagger = (bold(A)^H bold(A))^(-1)bold(A)^H$]:

$ bold(A) = X_(m+1) X_(m)^dagger $<3423>

由于$bold(X)$稠密,求解是不现实的.为此我们需要进行一些处理,我们对$bold(X)$进行奇异值分解,得到$bold(X) = bold(U Sigma V)^H $,其中$(dot)^H$表示共轭转置,随后截断前$ell$个奇异值,使得<3424>

$ bold(X) approx bold(U)_ell bold(Sigma)_ell bold(V)^H_ell $<3425>

其中,$bold(U) in CC^(n times ell),bold(Sigma) in CC^(ell times ell),bold(V) in CC^(m times ell)$,其中$bold(U)$蕴含了POD模态,对$bold(X_(m+1)) = bold(A) bold(X)_m$左乘$bold(U)^H$,右乘$bold(V) bold(Sigma)^dagger$得到:

$ bold(U)^H bold(X)_(m+1) bold(V Sigma)^dagger approx bold(U)^H bold(A) bold(U) bold(Sigma) bold(V)^H bold(V) bold(Sigma)^dagger = bold(U)^H bold(A) bold(U) = bold(tilde(A)) approx  bold(A)  $<3426>

我们利用$tilde(bold(A))$进行时间推进,不断求出各种$tilde(bold(x))_k$,对$bold(tilde(A))$进行特征值分解得到$bold(tilde(A) W) = bold(W Lambda_ell)$,其中$bold(Lambda)_ell="diag"(mu_1,mu_2,dots,mu_ell),bold(W) = (bold(omega_1),bold(omega_2),dots,bold(omega_ell))$,下面我们将把这些简化的结果转移到@3421 上.

首先考虑空间上的问题,上面的操作实际上已经完成了一次POD,所以要将特征向量恢复回去,于是有$bold(phi.alt)_i = bold(U) bold(omega)_i$.

下面我们重构@3421:

$ bold(x)(t) = sum_(j=1)^ell alpha_j e^(lambda_j t) bold(phi.alt_j) = sum_(j=1)^ell alpha_j bold(Phi)_j e^(-zeta_j omega_(n,j) t)(cos(omega_(d,h) t) + "i" sin(omega_(d,j) t)) $<3427>

考虑@3427 未定参数,由于$ bold(cal(A)) bold(phi.alt)_k = lambda_k bold(phi.alt)_k$,那么$bold(A) bold(phi.alt)_k = e^(bold(cal(A)) Delta t )bold(phi.alt)_k = e^(lambda_k Delta t)bold(phi.alt)_k=mu_k bold(phi.alt)_k $,这样就得到了

$ lambda_k = (ln(mu_k))/(Delta t) $<3428>

特征值$mu_k = |mu_k| angle mu_k$,所以上面可以改写成$lambda_k = (ln(|mu_k|))/(Delta t)+ "i" (angle mu_k)/(Delta t)$,与$lambda_k = -zeta_j omega_(n,j) +"i"omega_(d,j)$对齐,得到

$ omega_n = (|ln mu|)/(Delta t) ,zeta =-(ln |mu|)/(|ln mu|),omega_d = omega_n sqrt(1-zeta^2) $<3429>

带入初始状态$t=0$,得到$bold(x)_0 = sum_(j=1)^ell alpha_j bold(phi.alt_j) = bold(U) bold(W) bold(alpha)$,所以得到了向量$bold(alpha)$

$ bold(alpha) = bold(W)^(-1) bold(U)^H bold(x_0) $<34210>

我们同样注意到,以上模态都是共轭出现,也就是说,可以通过适当的排列组合,将@3427 复数部分抵消,得到实数的解

$ bold(x)(t) = sum_j 2 |alpha_j| |bold(Phi_j)| e^(-zeta_j omega_(n,j) t) cos(omega_(d,h) t + phi_(alpha_j) +bold(phi_(Phi_j))) $<34211>

这里将$alpha_j,bold(Phi_j)$全部角度化了,他们将作为相移的部分参与分析,正常情况下,我们只需要取这里能够增长的振动模态作为分析结果即可,也有人提出了考虑全局的算法@kou2017improved,当我们考虑有节律的流动失稳时,应当明确的时这是一个极限环(LCO),所以上面的衰减因子应为1.



#pagebreak()



#bibliography("biber.bib",style: "cell")