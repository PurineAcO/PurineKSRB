#import "lib.typ": *

#set footnote(numbering: (..args) => {
  args.pos().at(0) * "†"
})


#let header-style(heading) = {

  if int(counter(page).display())>=3 {
  set text(font: config.header-font)
  let title = "Team #2618556"
  grid(
    columns: (1fr, 1fr),
    align(left, title), align(right, heading),
  )

  v(-1.2em)
  v(0.5em)
  line(stroke: 1pt + black, length: 100%)
}}

#let prev-header = context {

  if(int(counter(page).display()) < 3 ) {
    return
  }
  let heading = "page " + counter(page).display() + " of " + str(counter(page).final().at(0))
  header-style(heading)
}

#let f-header-style() = {

  if int(counter(page).display())==1{
  set par(spacing: 0.1em)
  table(
      columns: (1fr, 1fr, 1fr),
      align: center,
      stroke:none,
      [
        #text(12pt, weight: "bold")[Problem Chosen]
        #linebreak()
        #text(20pt, fill: black, weight: "bold")[E]
      ],
      [
        #align(center)[*2026*]
        #linebreak()
        #align(center)[*MCM/ICM*]
        #linebreak()
        #align(center)[*Summary Sheet*]
      ],
      [
        #text(12pt, weight: "bold")[Team Control Number]
        #linebreak()
        #text(20pt, fill: black, weight: "bold")[2618556]
      ]
    )
  }

  v(0.5em)
  line(stroke: 2pt,length:100%)


}

#let f-header=context{f-header-style()}

#set page(header-ascent: -20pt,header: f-header)

#show : project.with(
  title:[Multi-Physics Field-Based Design Model for Intelligent Passive Solar Shading Systems in Buildings],
  abstract: [To address the collaborative optimization of building shading and daylighting in regions of different latitudes and achieve energy conservation, consumption reduction, and thermal comfort improvement throughout the building life cycle, it is necessary to construct a *Passive Solar Shading (PSS)* system. This study develops a* multi-physics field coupling model* integrating solar kinematics, shading efficiency, radiation-fluid-solid coupling heat transfer, and indoor daylighting, which can support the design of passive shading systems across the globe.


Based on the fundamental laws of thermodynamics and optics, the model combines geographic coordinates and meteorological data, introduces the calculation method of *thermal capacity-thermal resistance differential equation*, and establishes the geometric-radiative causal relationship of the passive solar shading system. It realizes the annual dynamic optimization of shading panel length and inclination angle via the *NSGA-II multi-objective genetic algorithm*. Taking Sungrove University in low-latitude regions and Borealis University in high-latitude regions as case studies respectively, the research completes the retrofit design of existing building shading systems and the scheme planning of a new student union building, providing comprehensive recommendations covering building configuration, materials, and the geometric configuration of shading systems. Results show that after applying the PSS scheme guided by this model, *indoor temperature fluctuations are reduced by 43% in tropical regions and 39% in frigid regions. The balance between daylighting and thermal insulation performance is achieved, and the system can well adapt to climate fluctuations.*


With favorable universality and stability, this model can provide theoretical support and technical solutions for green building design in different climate zones.],
  keywords: ("Passive Solar Shading","Multi-Physics Field","NSGA-II Algorithm","Thermal Resistance and Capacity"),
)

#pagebreak()
#set page(header-ascent: 30%+0pt,header: prev-header)


#text(
  size: 12pt,       // 本页字体大小
  font: ("Times New Roman","Source Han Serif SC"),
  
)[
#set outline(depth: 2, indent: auto)
#show outline: set align(center)

#let outline-title(s) = text(size: 20pt, s.clusters().intersperse(h(0em)).join())
#show outline.entry.where(
  level: 1
): it => {
  v(16pt, weak: true)
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
#outline(title: outline-title("Contents"))

#pagebreak()
]


= Introduction

== Problem Background

_Passive Solar Shading_ (PSS) architecture represents a design paradigm that relies fundamentally on the strategic orientation of the building and the rational layout of its surrounding environment. By integrating refined morphological design---both internally and externally---with the judicious selection of materials, this approach achieves the autonomous acquisition, modulation, and utilization of solar energy. By significantly reducing energy consumption during the operational phase, passive solar shading systems offer a distinct advantage in mitigating the emission of greenhouse gases and harmful refrigerants such as chlorofluorocarbons (CFCs), thereby serving as a cornerstone for the advancement of green building practices and sustainable development.

== Restatement of the Problem

Considering the background information and restricted conditions identified in the problem statement, we need to solve the following problems:

- *Task 1*: Develop a passive solar heat transfer model for the Academic Hall North at Sungrove University, to analyze passive solar shading regulation on building cooling and heating loads across seasons, and establish an annual shading retrofit model for better summer cooling and winter thermal insulation.
- *Task 2*: Extend the shading model from Task 1 to Borealis University, accounting for its geography, building geometry, envelope thermophysical properties and glass curtain walls, with emphasis on improving winter solar heat gain and thermal mass utilization.
- *Task 3*: Propose a site-specific passive solar shading strategy to maintain indoor thermal comfort, balancing solar heat gain, material thermal conductivity and daylighting performance.
- *Task 4*: Compose an official advisory letter for universities, introducing the shading retrofit model in Task 1 and the strategy in Task 3, and recommending energy-saving measures for heating and cooling systems.

== Our work

First, based on astronomical knowledge and the most basic laws of thermodynamics and optics, we established four models including solar kinematics, shading efficiency, radiation-fluid-solid coupling heat transfer, and daylighting, and integrated them together. Next, we used Bangkok and Reykjavik as representative cities to customize seasonally adaptive passive shading systems for the two existing buildings of Sungrove University and Borealis University respectively. Finally, we selected Sungrove University and designed a student union building featuring full utilization of light energy and reliance on passive solar shading systems, and analyzed the rationality and superiority of the design.The flow chart of our work is showed in @0.

#figure(image("assets/cf021a3292e768e52f6d8964cf446527.png",width: 100%),caption: [The flow chart of our work])<0>

= Preparation work

== Assumptions

- *Assumption 1*: Both Sungrove University and Borealis University are assumed to be located in the Northern Hemisphere.
$arrow$ *Justification*: This assumption reduces directional ambiguity in solar geometry calculations and improves model consistency without affecting the generality of the results.

- *Assumption 2*: Extreme weather conditions are neglected, and the selected Typical Meteorological Year (TMY) data are assumed to represent the long-term climatic characteristics of the study region.

$arrow$ *Justification*: Excluding extreme events allows the model to focus on typical operating conditions and improves the robustness and general applicability of the simulation results.

- *Assumption 3*: Terrain-induced shading effects are neglected, and solar altitude angle, azimuth angle, and declination angle are assumed to be accurately calculated using standard astronomical models.

$arrow$ *Justification*: Standard solar geometry models are widely validated and provide sufficient accuracy for building-scale performance evaluation.

- *Assumption 4*: Local atmospheric disturbances such as pollution and haze are neglected, and atmospheric transmittance is assumed to be spatially uniform across the study area.

$arrow$ *Justification*: This simplification reduces model complexity while retaining the dominant characteristics of solar radiation attenuation.

- *Assumption 5*: Structural deformation and thermal expansion are neglected, and the shading devices are assumed to remain perfectly rigid during operation.

$arrow$ *Justification*: The structural stiffness of shading components ensures that geometric parameters remain stable, allowing the thermal and daylighting effects to be analyzed independently of mechanical behavior.

- *Assumption 6*: Multiple reflection and coupling effects are neglected, and solar radiation is assumed to undergo only single-surface reflection on building envelopes.

$arrow$ *Justification*: Considering only first-order reflections captures the primary radiative contribution while avoiding excessive computational complexity.


== Notations

#show table:three-line-table

#figure(table(columns:2,[Symbol],[Definition],[$Theta$],[Solar azimuth angle],[$Phi$],[Solar elevation angle],[$l$],[Passive solar shading panel length],[$theta$],[Passive solar shading panel inclination angle],[$Delta h$],[Effective shading height of the shading panel]))


= Model <C2>

== Solar Motion Model

To accurately determine the Sun's directional vector under specific spatiotemporal conditions on Earth, this study establishes a _Solar Position Calculator_ (SPC) model. 

As is shown in @1, the Julian day number $n$ is introduced to calculate the declination angle $delta$,which characterizes the Sun's north-south variation due to Earth's revolution#footnote[from https://www.suncalc.org/]:

$ delta = 23.45 degree times sin (360 degree times (n + 284) / 365) $<1>


As is shown in @2, the local solar hour angle $omega$ is derived from the observation site's geographic longitude $alpha$,which reflects the Sun's east-west variation caused by Earth's rotation:

$ omega = (alpha/(360 degree) times 24 -12)times 15 degree $<2>

#figure(image("assets/image.png",width:50%),caption: [The angles which describe the Sun's position])<F1>

We use solar elevation angle $Theta$ and solar azimuth angle $Phi$ to describe the Sun's position.$Theta$ describes the Sun's elevation above the horizontal plane, and $Phi$ denotes the Sun's directional position within the horizontal plane.Those are showed in @F1 and calculated by @3 and @4.

$ sin Theta= sin phi sin delta + cos phi  cos delta  cos omega $<3>
$ cos Phi=(sin theta sin phi-sin delta)/(cos theta cos phi) $<4>


As shown in @5, the solar position at the observation site can be expressed as the unit direction vector $arrow(S)$, which provides a unified, intuitive mathematical description for subsequent solar radiation calculations, shading analysis, and building energy performance evaluation:

$ arrow(S) = vec(cos Theta sin Phi, sin Theta cos Phi, sin Theta) $<5>

Since all buildings are assumed to be in the Northern Hemisphere, the included angle between south-facing building facades and solar rays corresponds to the second component of $arrow(S)$.@F2 shows the instrument for observing solar position and the corresponding observed solar trajectory.

#figure(image("assets/image-2.png",width:70%),caption: [Instrument for observing solar position and solar trajectory])<F2>


== Passive Solar Shading Causal Geometric-Radiative Model

Passive solar shading has been widely applied since the 1970s to improve residential livability and indoor daylighting without compromising architectural function or aesthetics. Current approaches typically employ insulated glass envelopes for solar heat control, shading louvers to block direct radiation, or green façades to reduce cooling demand. @F3.2 shows some good examples.


#figure(image("assets/image-10.png",width:100%),caption: [Passive solar shading examples])<F3.2>



This study proposes a passive solar shading system based on a rotating-axis folding-panel structure. As showed in @F3, this structure's length $L$ and $theta$ is adjustable. The three-fold panels adapt to varying solar incidence throughout the year, while the rotational mechanism enhances flexibility to satisfy diverse daylighting and shading requirements. Compared with conventional louvers and green façade systems, the proposed design offers broader applicability and avoids additional maintenance costs, demonstrating strong engineering feasibility and practical potential.

In @F3, we assume that $phi$ denotes the angle between the sun's rays and the outward normal of the illuminated building facade. 

#figure(image("assets/image-5.png",width:60%),caption:[The structure of adjustable passive solar shading system])<F3>

The shading height $Delta h$ corresponding to the obstruction of direct solar radiation can be determined through geometric relations. $Delta h$ follows a definite trigonometric relationship with $phi$, the shading device length $L$, and the angle $theta$ between the shading device and the vertical wall. The mathematical expression of this relationship is given in @5.1. 

$ Delta h =(L cos(theta-phi))/(cos phi) $ <5.1>

With the shading height $Delta h$ obtained, the direct solar radiation intensity under the corresponding conditions is further calculated, thereby establishing a quantitative relationship between the total solar radiation intensity and the degree of shading, which provides a foundation for the subsequent evaluation of shading performance and parameter optimization.

== Solar Radiation-FSI Heat Transfer Model

This model is a coupled analysis tool that integrates solar radiation energy input with fluid-solid heat transfer processes. It simulates heat transfer and temperature responses induced by solar radiation across media such as air, walls, and glass, typically applied in building thermal environment studies.

To evaluate the impacts of various factors on building interior temperature and heat transfer, a scaled-down model is established. To characterize their influence on temperature variation, the indoor space is initially assumed to be stable at a specific temperature ($approx$23 °C) with all temperature regulation systems shut down. The net indoor temperature variation $Delta T$ is evaluated  to quantify the relationship between illuminance intensity $I$ and $Delta T$. Then we will consider how season and date influence the model.

#pagebreak()

=== Solar Radiatio

#let FEP=$"FEP"$

The radiative heat transfer model proposed in this paper is based on the radiosity-irradiation theory, used to quantitatively describe the energy balance of building surfaces under solar radiation.

#figure(image("assets/image-6.png",width:55%),caption: [Multiple radiation sources of the glass window])<F4.1>

For a building surface $i$, the effective radiosity $J_i$ (total radiant energy emitted outward per unit area) is the sum of the surface's own radiation and reflected incident radiation, as expressed in @11. 

$ J_i=epsilon_i e_b (T) FEP_i (T)+rho_(d,i)G_i $<11>

The first term on the right-hand side is the surface's emission power at temperature $T$, where $epsilon_i$ reflects radiation emission capacity, $e_b (T)$ is blackbody radiation power, and fractional emissive power $FEP_i (T)$ denotes the radiant energy proportion in a specific wavelength range to reflect material spectral selectivity. The second term is reflected incident radiation, with diffuse reflectivity $rho_(d,i)$  and total incident irradiance $G_i$ .

As @12 showed,the total irradiance $G_i$ incident on surface $i$ is a linear superposition of multiple radiation sources, including mutual radiation $G_(m,j)$ from other building surfaces, ambient background radiation $G_("amb",i)$ (e.g., sky, ground), and external direct radiation $G_("ext",i)$ (e.g., solar radiation). This model is illustrated by @F4.1.

$ G_i=G_(m,i)+G_("amb",i)+G_("ext",i) $<12>

$G_("amb",i)$ is calculated using the view factor visible proportion of the environment from surface $F_("amb",i)$ as shown in @13, where $epsilon_("amb")$ and $T_("amb")$ are the emissivity and temperature of the ambient background.

$ G_("amb",i)=F_("amb",i) epsilon_("amb")e_b (T_("amb")) FEP_i (T_("amb")) $<13>

The blackbody radiation power $e_b(T)$ follows the Stefan-Boltzmann law and is corrected by medium refractive index $n$ for non-vacuum radiative transfer @14. 

$ e_b (T)=n^2 sigma T^4 $<14>

To enhance the description of material spectral selectivity, $FEP_i (T)$ (a dimensionless integral form of Planck's radiation law) is introduced @15. 

$ FEP_i (T)=15/pi^4 integral_(C_2/(lambda_(i-1) T))^(C_2/(lambda_(i) T))(x^3)/(1-e^x) dif x $<15>

With $C_2$ as the second radiation constant, the integral calculates the radiant energy proportion in a specific wavelength interval, characterizing material energy distribution across spectral bands.

Finally, according to Kirchhoff's law and energy conservation for opaque surfaces, $epsilon_i$ and $rho_{d,i}$ satisfy the constraint in @16, ensuring the physical consistency and theoretical rigor of the model.

$ epsilon_i+rho_(d,i) equiv 1 $<16>


=== Solid Heat Conduction & Gas Heat Convection

As @F6 showed,In the building model, heat transfer involves not only solid media such as walls and glass but also air inside and outside the building, which follow two distinct heat conduction mechanisms. This model comprehensively integrates radiation, conduction, convection, and the greenhouse effect to establish a detailed algorithm. 

the solid heat transfer model is showed in @6

$ rho C_p (partial T)/(partial t)-nabla dot (k nabla T)=Q $<6>

where $rho$ denotes density, $C_p$ is the specific heat capacity at constant pressure

the fluid heat transfer model is showed in @7

$ rho C_p (partial T)/(partial t)+rho C_p bold(arrow(u)) dot nabla T+nabla dot bold(arrow(q))=Q+Q_p+Q_(v d) $<7>

where $Q_p$ and $Q_("vd")$ are fluid-specific heat source terms. By capturing convective heat transfer driven by fluid motion and incorporating additional fluid-specific heat sources, this equation characterizes the temperature distribution and evolution of air and other fluid media inside and outside the building. 

Together, these two equations form a coupled heat transfer framework that separately models the thermal behavior of solid and fluid media while ensuring consistent heat exchange at solid-fluid interfaces, enabling accurate simulation of the building's overall thermal environment.

#figure(image("assets/image-7.png",width:75%),caption: [The heat transfer model])<F6>



To reduce the computational complexity of the model, @8\~@10 present a convection characterization method based on heat correction. 

$ bold(arrow(q))=-k N_u nabla T $<8>

$ N_u=0.069 H dot P^0.074_r dot  root(3,(rho^2 g |alpha_p| C_p)/(mu k) Delta T) $<9>

$ alpha_p=-1/rho ((partial rho)/(partial T))_p $<10>

Empirical correlations are employed to calculate the Nusselt number $N_ u$, comprehensively accounting for the Prandtl number $P_r$ and the Rayleigh number effect driven by fluid density gradients. This method also reflects the combined influences of gravitational acceleration $g$, characteristic length $H$, and characteristic temperature difference $Delta T$ on the intensity of natural convection heat transfer.

=== Greenhouse Effect


The greenhouse effect induced by glass originates from its inherent "shortwave transmittance and longwave trapping" characteristic. Solar shortwave radiation (0.3\~3 $mu$m) penetrates glass efficiently into the indoor environment, where it is absorbed by walls, floors, and other surfaces to be converted into internal energy, thereby elevating the indoor temperature. In contrast, longwave thermal radiation (3\~50 $mu$m) emitted by indoor objects (at 20\~30 °C) is strongly absorbed by glass components such as SiO₂, with minimal outward transmittance. As @F7 (a) showed, a fraction of the absorbed heat is conducted through the glass to the exterior, while the majority is reflected back into the room, resulting in energy accumulation. This process ultimately leads to an indoor temperature higher than the outdoor ambient temperature, a phenomenon defined as the greenhouse effect.

#figure(image("assets/image-9.png",width:100%),caption: [Greenhouse effect model])<F7>

The greenhouse effect can be effectively simulated by adjusting the opacity of glass to light with different wavelengths. For the case of a glass box, it is observed that the greenhouse effect significantly enhances the temperature rise of the box under illumination, as illustrated in @F7 (b).

== Indoor Daylighting Evolution Model

To accurately evaluate the visual performance of passive shading systems, a multi-level transmission model was established to link extraterrestrial solar radiation to effective indoor illuminance.

=== Outdoor Combined Irradiance 

The first stage of light transfer considers the attenuation of solar radiation in the atmosphere. According to the Beer-Lambert law, the direct irradiance reaching the ground surface Edircan be expressed as @18:



$ E_("dir")=A exp(-beta/(sin Theta)) $<18>

$A$ is the total solar illuminance, which varies with geographical location @Z4. @9.0 shows the global distribution of the value of $A$. $beta$ is the atmospheric extinction coefficient, and $Theta$ denotes the solar elevation angle.

#figure(image("assets/078b749b64fddf4e0ef3bf204be70968.png",width:90%),caption: [Global distribution of total solar illuminance])<9.0>

The total radiation incident on the ground surface consists of both direct and diffuse components. For a building facade with a specific orientation, the outdoor combined irradiance $E_("out")$ follows geometric projection and sky-scattering principles.It can be expressed as @19:

$ E_("out")=E_("dir") cos Theta sin Phi +E_("dif")⋅r_("sky") $<19>

Here, the solar elevation angle $Theta$ and azimuth $Phi$ project the direct flux onto the building surface, $E_("dif")$ represents the diffuse sky radiation, and $r_("sky")$ accounts for atmospheric obstruction.

=== Indoor Effective Illuminance Transmission and Gain 

The effective indoor illuminance Einresults from the combined effects of shading devices, glazing interfaces, and multiple interior reflections, expressed as @20 @Z2:

$ E_("in")=E_("out") dot tau_g dot r_w dot C_U dot sqrt(rho_("mean")) dot (1-F_s) dot C_("atm") dot C_("snow") $<20>

These parameters are defined as the following @T1:

// #show table :three-line-table

#figure(table(columns: 2,[parameter],[meaning],[$tau_g$],[Glass transmittance],[$r_w$],[window-to-wall ratio],[$C_U$],[Utilization coefficient],[$rho_("mean")$],[Mean reflectance],[$F_s$],[Blocking factor],[$C_("atm")$],[Atmospheric transparency],[$C_("snow")$],[Ground snow reflection]),caption: [the parameters of the illuminance model])<T1>

= Solution For Sungrove University <C3>

== Problem analysis

Sungrove University is located in a low-latitude, high-solar-exposure region, where frequent heatwaves have increased cooling load. In the design of the passive solar shading retrofit for Sungrove University, Bangkok's geographical coordinates and annual climatic and seasonal variations were considered to determine the year-round optimal shading configuration.The North Academic Building, a rectangular east-west-oriented structure with a 45% window-to-wall ratio, is planned for renovation using passive solar shading to balance annual heating and cooling loads.

Using the solar motion, radiation, and heat conduction models from @C2, Simulations were conducted under full-sun and no-sun conditions to obtain indoor temperature distributions with the help of software _COMSOL_. @F9 showed some temperature trends#footnote[the temperature outside the room is from https://www.tmd.go.th/].

#figure(image("assets/image-14.png",width:90%),caption: [Indoor temperature distribution under different illuminance conditions])<F9>

Results show an approximately linear relationship between solar radiation and indoor temperature. Based on this, an objective function Jis formulated to quantitatively evaluate the performance of the proposed passive solar shading design.

== Passive solar shading-daylighting optimization model

Analysis of the above heat transfer models indicates that a building's thermal exchange characteristics are closely related to the physical properties of construction materials, as well as the geometric length and installation angle of shading devices. Meanwhile, indoor daylighting performance is also constrained by the geometry of shading elements and spatial configuration.


In practice, thermal performance and visual comfort often exhibit a trade-off: enhancing shading can reduce summer cooling loads but may lower indoor illumination. Therefore, a multi-objective optimization model is required to balance daylighting and solar heat gains.

=== Establishment of the Comprehensive Evaluation Model

To quantitatively evaluate the overall performance of the shading system, the following objective function is defined in this study (@21):

$ J=lambda_1 e_E+lambda_2 e_Q arrow^(d a y) 0 $<21>

This model allows for performance trade-offs at different priority levels by adjusting the relationship between the weighting coefficients $lambda_1$ and $lambda_2$, in accordance with specific geographic location, climate zone, and building functional requirements. The allocation of weights is primarily determined by the economic costs associated with temperature regulation and artificial lighting. In the passive solar shading scheme designed for Sungrove University in this section, the reduction of summer heat radiation transfer is the primary consideration, resulting in values of $lambda_1 = 1/6$ and $lambda_2 = 5/6$.


The daylighting evaluation index $e_E$ and the heat transfer evaluation index $e_Q$ are calculated using the following dimensionless formulations @22 and @23.


$ e_E=(|E−E_0|)/E_0 $<22>

$ e_Q=(|Delta T_E|)/T_0 $<23>

$T_0$ means a reference temperature used to normalize the heat transfer evaluation index $e_Q$ and $E_0$ means a reference illuminance used to normalize the daylighting evaluation index $e_E$.

=== NSGA-Ⅱ Multi-Objective Genetic Algorithm Computation

_NSGA-II_ (Non-dominated Sorting Genetic Algorithm II) is a multi-objective optimization algorithm based on the concept of the Pareto-optimal solution set. @F10 show how it works.

Compared with the traditional Non-dominated Sorting Genetic Algorithm (NSGA), NSGA-II introduces several significant improvements in both algorithmic structure and performance, which can be summarized as follows:

- A fast non-dominated sorting scheme is proposed, which significantly reduces the computational complexity of the sorting process and thereby improves the overall computational efficiency of the algorithm;
- An elitist strategy is incorporated, ensuring that high-quality individuals are preserved and participate in subsequent generations, effectively preventing the loss of superior solutions during evolution and enhancing the convergence accuracy of the final solution set;
- A crowding distance and its corresponding comparison operator are employed as key criteria for individual selection, enabling solutions on the approximate Pareto front to be uniformly distributed across the entire Pareto domain. This mechanism enhances population diversity while maintaining convergence toward the Pareto-optimal front.

#figure(image("assets/image-12.png",width:90%),caption: [The flowchart of NSGA-II])<F10>


=== Results of Passive Solar Shading Retrofit

Within the framework of the aforementioned algorithm, the comprehensive evaluation objective function $J$ and the geometric parameters of the sunshade panels are taken as the optimization variables and input into the NSGA-II algorithm. A joint optimization is performed on the inclination angle $theta$ and extension length $l$ of the sunshade panels for different periods throughout the year, with the expectation that $J$ converges to zero as a function of date. Through the solution process, a year-round passive solar shading optimization scheme that balances daylighting performance and thermal regulation performance is ultimately obtained, and the results are presented in the @F11.

#figure(image("assets/image-17.png",width:100%),caption: [Year-round passive solar shading optimization results])<F11>

== Our Solution

According to the optimization results, the data for several typical periods throughout the year are listed in the @T2 below. 

#figure(table(columns: 5,[date],[2025-3-22],[2025-6-22],[2025-9-22],[2025-12-22],[$l$(m)],[1.0],[1.5],[1.0],[0.5],[$theta(degree)$],[40.09],[20.66],[39.12],[48.93]),caption: [Passive solar shading optimization results on 4 days])<T2>

From @T2 and @F11, it can be observed that the shading demand is the strongest in summer, requiring a greater length of the sunshade panels, whereas the opposite is true in winter. In the control-variable simulation tests, the length $l$ of the sunshade panels exerts a significant influence on the shading ratio and the value of $J$, while the effect of the angle $theta$ is relatively minor. In the simulations, $theta$ tends to converge toward the direction of solar radiation incident on the building facade at that specific date. Consequently, from an annual perspective, $theta$ exhibits periodic variation characteristics approximately analogous to a sine function.

These results can provide instructive insights for engineering design. Given that the shading facilities are to be retrofitted onto existing buildings, modifications to the buildings should be minimized as much as possible. For this purpose, we have designed a *tri-fold sunshade panel* composed of three planar sections, each with a width of 50 cm and manufactured from lightweight materials. The number of unfolded panel sections can be adjusted either manually or automatically in response to seasonal changes, thereby realizing the regulation of the effective shading length.


= Solution for Borealis University

== Problem analysis

Borealis University lies in a high-latitude region with year-round low solar altitudes and weak solar radiation. Winters bring extremely short daylight, long nights and even polar nights, while summers have long days but highly scattered radiation, leading to inadequate indoor daylighting.

Such regions experience sustained low temperatures and frequent cold waves in winter, raising demand for building thermal insulation and heating. External cold readily lowers indoor temperatures, and building envelopes (external walls, windows, roofs) are heat-loss sensitive. Thus, heating load control and energy-efficient design are key to thermal comfort and energy conservation. Pronounced diurnal and seasonal temperature variations in summer also impose stricter demands on indoor temperature control and daylighting design.

For practical relevance, we choose Reykjavík, a city close to the Arctic Circle, as the example to analyze this problem.

== Thermal mass analysis

As shown in @12,Thermal resistance is a material's ability to impede heat transfer—higher resistance means slower heat transfer. In buildings, materials like insulation cotton, rock wool, and foam plastic have high thermal resistance, used in external walls, roofs, and windows to reduce indoor-outdoor heat exchange, lower energy consumption, and stabilize indoor temperatures@Z5@Z1. Thermal capacity, by contrast, is a material's resistance to temperature changes when absorbing or releasing heat; higher capacity allows more heat storage or release. Heavy building materials such as concrete, masonry, and bricks have high thermal capacity, forming the building's thermal mass to moderate temperature fluctuations, achieve passive temperature regulation, and enhance comfort while saving energy. In building thermal design, thermal resistance and capacity work synergistically: resistance blocks rapid heat transfer to reduce loads, while capacity buffers temperature changes via thermal mass, optimizing the indoor thermal environment—especially suitable for high-latitude Northern Hemisphere buildings to achieve both energy conservation and comfort.

#figure(image("assets/acdbd8720d7e218cbb0075fd4e0eb3b2.png",width:90%),caption: [Thermal resistance and thermal capacity])<F12>

The transient thermal response of building envelope structures follows the thermal resistance-thermal capacity series coupling equation, which is essentially an integration of the law of conservation of energy and Fourier's law. Its core form is expressed as @24: 

$ C(dif T_(i"in"))/(dif t)=(T_"out"-T_(i"in"))/R+Q_("in") $<24>

As shown in @F13, internal heat sources mainly consist of heat dissipation from human activities, electrical equipment, lighting systems, and heating devices, which collectively constitute the thermal mass in the simulation analysis.

#figure(image("assets/image-18.png",width:100%),caption: [Internal heat sources])<F13>

By solving this differential equation, concise results can be obtained to support subsequent optimization work. We analyzed these analytical results alongside those derived from _COMSOL_ simulation software, and the outcomes showed good agreement. This confirms that thermal mass analysis is an effective approach.

== Optimization

The weighting parameters $lambda_1$ and $lambda_2$ were evaluated following the method described in @C3. Specifically, we recalculated the economic costs required for heating and lighting, and updated the values of these weighting parameters accordingly to align with the actual operational costs of the classroom in high-latitude regions.

The NSGA-II algorithm was employed for optimization, yielding the variation trend of the sunshade length L as illustrated in the figure below.

#figure(image("assets/image-15.png",width:100%),caption: [Year-round passive solar shading optimization results])<F14>

== Our Solution

Reykjavik, the location under consideration, is situated in a high-latitude region with distinct characteristics. As the city is close to the Arctic Circle, it experiences polar nights in winter, resulting in extremely low daily illuminance—thus, there is no need for sunshading during this season. In summer, however, the angle between solar rays and the building facade is relatively large, making glare prone to occur, which is detrimental to indoor daylighting. Therefore, sunshading in this context primarily serves the purpose of optimizing daylighting conditions.



Similar to the scenario elaborated in @C3, the sunshade length $l$ exerts a significant influence, far greater than that of the angle $theta$. Due to the generally low solar altitude angles throughout the year, the value of $theta$ remains relatively fixed and holds relatively little optimization significance.

To achieve thermal insulation, installing thermal insulation materials on the building is of greater importance. Additionally, the window-to-wall ratio ranks as the second most significant influencing factor. @T3 illustrates the impacts of using different types of exterior wall materials.

#figure(table(columns: 4,[],[0%],[30%],[45%],[Concrete],[11℃],[11.5℃],[10℃],[XPS],[11.3℃],[11.9℃],[10.6℃],[XPS&Low-E Glass],[12.7℃],[13.7℃],[12℃]),caption: [Impacts of Different Materials and Window-to-Wall Ratios on Indoor Temperature])<T3>

As can be seen from the results, the combined use of materials with high thermal resistance and thermal capacity, along with low-emissivity glass, contributes to the building's thermal insulation@Z3. Meanwhile, designing an appropriate window-to-wall ratio can enhance the thermal insulation effect. An increase in window area allows for more solar radiation, but excessively large window areas conversely increase heat loss—this is a trade-off that requires careful balancing.

= Design for Student Union Building of Sungrove University

We conduct architectural design for the new Student Union Building of Sungrove University, which is located in a low-latitude region with high solar radiation exposure. Through the proper integration of passive solar shading strategies, we aim to achieve year-round indoor thermal comfort, reduce cooling loads, and balance shading and daylighting under seasonal variations throughout the year.

Providing a design scheme for the new building requires a comprehensive consideration of architectural geometry, material selection, and key parameters of shading components, so as to improve the heating and cooling performance of the building while ensuring coordination between shading and daylighting.

Compared with the models described previously, we first take the architectural form, which has the most significant impact, into account. The building shape is initially set as a regular polygon with a variable number of sides $n$. Temperature simulations are performed on the _COMSOL_ platform with the window-to-wall ratio as a variable to obtain new thermal environment data. The simulation results are input into the previously constructed objective function and the identical NSGA-Ⅱ algorithm model, so as to obtain the optimized shading parameter data.

Interestingly, the number of sides $n$ eventually diverges to infinity, which indicates that a circular building structure better meets the design objectives. A circular building can be regarded as a continuous integration of facades with different orientations, leading to smoother variations in optical and thermal conditions, which is beneficial for subsequent design. Such a natural optimization result is also consistent with a variety of sustainable architectural design principles.

Based on the analysis of simulation and optimization results, reducing the window-to-wall ratio to 40% is proven to be the optimal choice to maintain high cooling efficiency of the new building. The analysis of shading panel parameters shows that the shading panel length $l$ and inclination angle $θ$ are mainly affected by the building's geographical location and the calculated solar elevation angle, resulting in small variation ranges across different seasons of the year. Among them, $θ$ exhibits an obvious periodic sinusoidal pattern, while the shading panel length can be adjusted seasonally.

= Model Analysis

== Universality of the Model

Based on basic thermophysical constraints and the law of conservation of energy, the model does not rely on region-specific parameters. Only by inputting basic information such as longitude, latitude, date, and building dimensions can it output a passive shading optimization scheme suitable for the local area, which is applicable to different latitudes and climate regions around the world. It also takes into account both daily average and extreme meteorological conditions, can adapt to various design needs, has strong interpretability, and can adapt to future climate change scenarios by adjusting input parameters.

== Stability of the Model

The stability of the model is the core premise for its engineering application, which is mainly reflected in three aspects: first, strong parameter robustness, which can resist the interference of input parameter measurement errors and meteorological parameter fluctuations; second, high computational convergence, relying on the collaborative calculation of NSGA-Ⅱ algorithm and _COMSOL_ simulation, it can converge quickly without falling into local optimum; third, good result consistency, small deviation in repeated calculations, and high consistency with measured data, ensuring the reliability of output results.

== Weakness

- Relatively complex model formulation leads to cumbersome calculations and high algorithmic time cost;
- Modeling based on commercial software fails to fully account for unknown factors;
- Incomplete geographic information results in inaccurate estimations.

#pagebreak()
= A Letter to the Sungrove University Leadership

#set par(first-line-indent: 0em)
#align(left)[Dear Members of the Sungrove University Leadership,]
#set par(first-line-indent: 2em)

Greetings!

We sincerely appreciate your commitment to campus energy-efficient transformation, particularly the renovation of Academic Hall North and the construction of the new Student Activity Center under the “2040 Net-Zero Cooling” goal. In response to your low-latitude climate, high solar exposure, and frequent summer heatwaves, our team proposes integrated passive solar shading strategies to balance daylighting and shading while reducing cooling demand and glare.

For Academic Hall North, we propose a tri-fold shading system with seasonally adjustable length and angles preset using sinusoidal functions, supported by light-sensor calibration. The system adopts lightweight, corrosion-resistant wall-mounted brackets, with buffered contact surfaces to minimize structural impact. PVC-coated polyester panels with sealed folding joints ensure durability and weather resistance.


For the new Student Activity Center, based on algorithmic analysis, we recommend a circular building form integrated with a dynamic shading system. Shading length and tilt respond to seasonal solar altitude changes, using semi-transparent frosted panels that visually merge with the façade when retracted, achieving both passive energy performance and architectural unity.

Guided by principles of climate adaptability, low intervention, and high efficiency, our approach integrates shading systems with building form and intelligent parameter control, achieving simultaneous reductions in energy consumption and improvements in user comfort without altering architectural identity.

Our team will provide full technical support throughout implementation. We sincerely thank Sungrove University for its commitment to sustainable development and look forward to contributing to a greener, more energy-efficient campus environment.

#align(right)[Yours sincerely,]

#align(right)[Team #2618556]


#pagebreak()

#bibliography("biber.bib",full:true,style:"cell")

#pagebreak()
// #set text(size:18pt)
#align(center)[#text(size:18pt)[*Report on Use of AI*]]
#set text(size:12pt)

*GPT-5.2*

Query 1:What are the distinct characteristics of sunlight and climate in low-latitude regions and high-latitude regions?

Output:Low-latitude regions receive sunlight at a high, nearly vertical angle throughout the year, so solar energy is concentrated and relatively consistent. As a result, these regions are generally warm or hot year-round, with little seasonal temperature variation, and climates are often characterized by persistent warmth and, in many areas, frequent rainfall. In contrast, high-latitude regions receive sunlight at a much lower angle, causing the energy to be spread over a larger surface area and weakened by reflection and atmospheric scattering. This leads to much lower overall solar input, strong seasonal differences in daylight length, and climates that are generally cold, with long winters, short summers, and large seasonal temperature contrasts.

Query 2:Please generate an image of radiation sources from the glass window.

Output:[@F4.1: Multiple radiation sources of the glass window]

Query 3:Provide me with a schematic diagram showing the optimized results of passive solar shading throughout the year.

Output:[@F12: Year-round passive solar shading optimization result]

Query 4:What are some common passive shading materials?

Output:Common passive shading materials include wood, bamboo, stone, concrete, brick, metal screens, fabric meshes, and glass with low-emissivity coatings; these materials are used in overhangs, louvers, pergolas, and façades to reduce direct sunlight, control glare, and moderate indoor temperatures without active energy use.

Query 5:After winter blizzards blanket the ground, does the high reflectivity of accumulated snow cause solar radiation to be secondarily reflected onto building facades, thereby increasing solar heat gain through non-south-facing windows?

Output:Yes, after heavy snow covers the ground in winter, the high reflectivity of snow (0.8\~0.9) can cause significant secondary reflection of solar radiation onto building façades, which may increase solar heat gain through non-south-facing windows, especially those that receive indirect or reflected sunlight.

