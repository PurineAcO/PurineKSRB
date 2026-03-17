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

- *对双圆柱体的离散化求解*



== 运动与时域推进

由于不考虑整个过程中的变形,这将是一个刚体动力学问题.时域推进的方法可以分为显式动力学和隐式动力学,前者基于显含时间的力学定律进行运动的描述,后者基于不显含时间的若干微分方程组描述运动.

隐式动力学方法中,我们使用四元数进行描述.@zhang2021arrestinghal

=== 隐式动力学方法

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

#pagebreak()



#bibliography("biber.bib",style: "cell")