#import "lib.typ": *

#v(0.5fr)

#align(center)[#text(size: 36pt, font: ("New Computer Modern","Source Han Serif SC"),)[
*_Hydromechanics_*]]

#v(1fr)

#align(center+horizon)[#text(size: 18pt, font: ("New Computer Modern","Source Han Serif SC"),)[
_This page is blank intentionally._]]

#v(1fr)



#v(0.5fr)
#pagebreak()

#text(
  size: 12pt,       // 本页字体大小
  font: ("New Computer Modern","Source Han Serif SC"),
  
)[
#set outline(depth: 3, indent: auto)
#show outline: set align(center)

#let outline-title(s) = text(size: 20pt, s.clusters().intersperse(h(0.005em)).join())
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
#outline(title: outline-title("Contents"))

#pagebreak()]

#show : project.with(
  title:[_Hydromechanics_],
  abstract: [Hydromechanics is the study of the mechanics of fluids, including their behavior under different conditions. It encompasses topics such as fluid flow, stress, and deformation.],
  keywords: ("Hydromechanics", "Fluid Flow", "Stress", "Deformation"),
)

= Kinematics

== Unit Vector's Differential and Derivative

Unit *vectors* are essential in _kinematics_ for #underline[describing] directions. With a magnitude of 1, their derivatives and differentials are critical for analyzing curvilinear motion where velocity or acceleration directions change.


= Dynamics

== Rigid Body Dynamics

Rigid body dynamics studies objects with fixed inter-particle distances, accounting for translational (center of mass motion) and rotational motion, and the forces/torques causing them, based on Newton’s laws and momentum conservation.

1. Key Motions

- Translational Motion: All particles follow parallel paths; velocities/accelerations match the center of mass (COM).

- Rotational Motion: Motion about fixed/moving axes; particles have different linear velocities but same angular velocity/acceleration.

- General plane motion (e.g., rolling ball) combines translation and rotation.

2. Center of Mass (COM)

- COM is the point where the total mass of a body is concentrated.

- COM moves with translational motion but not rotational motion.

- COM velocity/acceleration is the same as the body’s if no external force/torque acts.


