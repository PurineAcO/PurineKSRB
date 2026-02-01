#import "lib.typ": *



#show : project.with(
  title:[Hydromechanics],
  abstract: [Hydromechanics is the study of the mechanics of fluids, including their behavior under different conditions. It encompasses topics such as fluid flow, stress, and deformation.],
  keywords: ("Hydromechanics", "Fluid Flow", "Stress", "Deformation"),
)

#pagebreak()

= Model I

== Solar Motion Model

To accurately determine the Sun's directional vector under specific spatiotemporal conditions on Earth, this study establishes a _Solar Position Calculator_ (SPC) model. 

As is shown in @1, the Julian day number $n$ is introduced to calculate the declination angle $delta$,which characterizes the Sun's north-south variation due to Earth's revolution:

$ delta = 23.45 degree times sin (360 degree times (n + 284) / 365) $<1>


As is shown in @2, the local solar hour angle $omega$ is derived from the observation site's geographic longitude $alpha$,which reflects the Sun's east-west variation caused by Earth's rotation:

$ omega = (alpha/(360 degree) times 24 -12)times 15 degree $<2>

#figure(image("assets/image.png",width:60%),caption: [the angles which describe the Sun's position])<F1>

We use solar elevation angle $theta$ and solar azimuth angle $Phi$ to describe the Sun's position.$theta$ describes the Sun's elevation above the horizontal plane, and $Phi$ denotes the Sun's directional position within the horizontal plane.Those are showed in @F1 and calculated by @3 and @4.

$ sin theta= sin phi sin delta + cos phi  cos delta  cos omega $<3>
$ cos Phi=(sin theta sin phi-sin delta)/(cos theta cos phi) $<4>


As shown in @5, the solar position at the observation site can be expressed as the unit direction vector $arrow(S)$, which provides a unified, intuitive mathematical description for subsequent solar radiation calculations, shading analysis, and building energy performance evaluation:

$ arrow(S) = vec(cos theta sin Phi, sin theta cos Phi, sin theta) $<5>

Since all buildings are assumed to be in the Northern Hemisphere, the included angle between south-facing building facades and solar rays corresponds to the second component of $arrow(S)$.@F2 shows the instrument for observing solar position and the corresponding observed solar trajectory.

#figure(image("assets/image-2.png",width:80%),caption: [Instrument for observing solar position and solar trajectory])<F2>



= Dynamics

== Rigid Body Dynamics




