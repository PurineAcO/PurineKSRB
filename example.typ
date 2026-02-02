#import "lib.typ": *



#show : project.with(
  title:[Hydromechanics],
  abstract: [Hydromechanics is the study of the mechanics of fluids, including their behavior under different conditions. It encompasses topics such as fluid flow, stress, and deformation.],
  keywords: ("Hydromechanics", "Fluid Flow", "Stress", "Deformation"),
)

#pagebreak()


= Introduction

== Problem Background

_Passive Solar Shading_ (PSS) architecture represents a design paradigm that relies fundamentally on the strategic orientation of the building and the rational layout of its surrounding environment. By integrating refined morphological design---both internally and externally---with the judicious selection of materials, this approach achieves the autonomous acquisition, modulation, and utilization of solar energy. By significantly reducing energy consumption during the operational phase, passive solar shading systems offer a distinct advantage in mitigating the emission of greenhouse gases and harmful refrigerants such as chlorofluorocarbons (CFCs), thereby serving as a cornerstone for the advancement of green building practices and sustainable development.

== Restatement of the Problem

Considering the background information and restricted conditions identified in the problem statement, we need to solve the following problems:

- *Task 1*: Develop a passive solar heat transfer model for the Academic Hall North at Sungrove University, to analyze passive solar shading regulation on building cooling and heating loads across seasons, and establish an annual shading retrofit model for better summer cooling and winter thermal insulation.
- *Task 2*: Extend the shading model from Task 1 to Borealis University, accounting for its geography, building geometry, envelope thermophysical properties and glass curtain walls, with emphasis on improving winter solar heat gain and thermal mass utilization.
- *Task 3*: Propose a site-specific passive solar shading strategy to maintain indoor thermal comfort, balancing solar heat gain, material thermal conductivity and daylighting performance.
- *Task 4*: Compose an official advisory letter for universities, introducing the shading retrofit model in Task 1 and the strategy in Task 3, and recommending energy-saving measures for heating and cooling systems.


= Model

== Solar Motion Model

To accurately determine the Sun's directional vector under specific spatiotemporal conditions on Earth, this study establishes a _Solar Position Calculator_ (SPC) model. 

As is shown in @1, the Julian day number $n$ is introduced to calculate the declination angle $delta$,which characterizes the Sun's north-south variation due to Earth's revolution:

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

To evaluate the impacts of various factors on building interior temperature and heat transfer, a scaled-down model is established. For classrooms and offices in two universities, , which is showed in @F3.1.

#figure(image("assets/326707bda0851d04b1ea4cbbb17fbdde.png",width:75%),caption: [Factors that influence the heat transfer in the room])<F3.1>

To characterize their influence on temperature variation, the indoor space is initially assumed to be stable at a specific temperature ($approx$23 °C) with all temperature regulation systems shut down. The net indoor temperature variation $Delta T$ is evaluated  to quantify the relationship between illuminance intensity $I$ and $Delta T$. Then we will consider how season and date influence the model.

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

$ e_b(T)=n^2 sigma T^4 $<14>

To enhance the description of material spectral selectivity, $FEP_i (T)$ (a dimensionless integral form of Planck's radiation law) is introduced @15. 

$ FEP_i(T)=15/pi^4 integral_(C_2/(lambda_(i-1) T))^(C_2/(lambda_(i) T))(x^3)/(1-e^x) dif x $<15>

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

=== Atmospheric Attenuation

The first stage of light transfer considers the attenuation of solar radiation in the atmosphere. According to the Beer-Lambert law, the direct irradiance reaching the ground surface Edircan be expressed as @18:


$ E_("dir")=A exp(-beta/(sin Theta)) $<18>

where $A$ is the solar constant at the top of the atmosphere, $beta$ is the atmospheric extinction coefficient, and $Theta$ denotes the solar elevation angle.

=== Outdoor Combined Irradiance 

The total radiation incident on the ground surface consists of both direct and diffuse components. For a building facade with a specific orientation, the outdoor combined irradiance $E_("out")$ follows geometric projection and sky-scattering principles.It can be expressed as @19:

$ E_("out")=E_("dir") cos Theta sin Phi +E_("dif")⋅r_("sky") $<19>

Here, the solar elevation angle $Theta$ and azimuth $Phi$ project the direct flux onto the building surface, $E_("dif")$ represents the diffuse sky radiation, and $r_("sky")$ accounts for atmospheric obstruction.

=== Indoor Effective Illuminance Transmission and Gain 

The effective indoor illuminance Einresults from the combined effects of shading devices, glazing interfaces, and multiple interior reflections, expressed as @20:

$ E_("in")=E_("out") dot tau_g dot r_w dot C_U dot sqrt(rho_("mean")) dot (1-F_s) dot C_("atm") dot C_("snow") $<20>

These parameters are defined as the following @T1:

#show table :three-line-table

#figure(table(columns: 2,[parameter],[meaning],[$tau_g$],[Glass transmittance],[$r_w$],[window-to-wall ratio],[$C_U$],[Utilization coefficient],[$rho_("mean")$],[Mean reflectance],[$F_s$],[Blocking factor],[$C_("atm")$],[Atmospheric transparency],[$C_("snow")$],[Ground snow reflection]),caption: [the parameters of the illuminance model])<T1>

= P2

#figure(image("assets/image-4.png",width:90%),caption: [the solar radiation model])<F9>

= P3

