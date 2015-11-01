WebGL Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 6**

* Sanchit Garg
* Tested on: Safari Version 9.0.1 on
  Mac OSX 10.10.4, i7 @ 2.4 GHz, GT 650M 1GB (Personal Computer)

### Live Online

[![](images/basicImage.png)](http://sanchitgarg.github.io/Project6-WebGL-Deferred-Shading/)

### Demo Video

[![](images/blinnPhong.png)](https://youtu.be/QB3VgeCDwlk)

### Deferred Shader

Implemented the scissor test, toon shader, sphere proxy in WebGL.

#### Debug Views

<img src="images/depth.png" height="150" width="200">
<img src="images/points.png" height="150" width="200">
<img src="images/colormap.png" height="150" width="200">
<img src="images/normalMap.png" height="150" width="200">
<img src="images/geomNorm.png" height="150" width="200">
<img src="images/surfaceNormals.png" height="150" width="200">

#### Performance Analysis

I used the default scissor test. It gives a speed up of arounf 2x.

<img src="analysis/scissorTest.png">

Looking at the impact of number of lights, we see that as we increse the number of lights, the FPS drops. A comparison of the FPS between with scissor test and without can be seen below.

<img src="analysis/ImpactOfNumLight.png">

