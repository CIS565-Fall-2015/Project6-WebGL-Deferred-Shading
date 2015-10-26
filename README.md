WebGL Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 6**

* Guan Sun
* Tested on: **Google Chrome 46.0.2490.80** on
  Windows 7, i7-4770 @ 3.40GHz 16GB, NVIDIA NVS 310 (Moore 100C Lab)

### Live Online

[![](img/1.png)](http://TODO.github.io/Project6-WebGL-Deferred-Shading)

### Demo Video

[![](img/2.png)](TODO)


## Project Description:
In this project, a a deferred shading pipeline is implemented using GLSL and WebGL.
The implemented features include,
* Effects:
  * Deferred Blinn-Phong shading (diffuse + specular) for point lights
  ![](img/1.png)

* Optimizations:
  * Scissor test optimization
  ![](img/9.png)

* Debug views
  * Depth
  ![](img/3.png)
  * Postiion
  ![](img/4.png)
  * Geometry normal
  ![](img/5.png)
  * Color map
  ![](img/6.png)
  * Normal map
  ![](img/7.png)
  * Surface normal
  ![](img/8.png)

## Performance & Analysis
The rendering performance with and without scissor test optimization are,
* Without scissor test optimization: 17 FPS
* With scissor test optimization: 35 FPS

With the scissor test optimization, the performance is approximatly twice better. The reason for this is, with the optimizaiton, when accumulating shading from each point light source, only the rectangle around the light is rendered.