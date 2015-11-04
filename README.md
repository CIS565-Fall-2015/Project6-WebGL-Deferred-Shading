WebGL Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 6**

* Sally Kong
* Tested on: Google Chrome 46, Macbook Air 2014, 1.4 GHz Intel Core i5, ntel HD Graphics 5000 1536 MB (Personal)


### Live Online

[![](img/thumb.png)](http://kongsally.github.io/Project6-WebGL-Deferred-Shading/)

### Demo Video

![](img/deferredShading.gif)

###Toon Shading
* With Ramp Shading and Outlines
![](img/toonShading.png)


### Debug Images

|Depth | Position | Geometry Normal|
|:-------------:|:-------------:|:-------------:|
|![](img/depth.png) | ![](img/position.png) | ![](img/geom_normal.png)|
|Color Map | Normal Map | Surface Normal|
|![](img/color_map.png) | ![](img/normal_map.png) | ![](img/surface_normal.png)|

## Performance Analysis

* Enabling the Scissor Test almost quadrupled the FPS
![](img/FPSChart.png)

* It reduced rendering time by about half

 | With Scissor Test | Without Scissor Test | 
 |:-------------:|:-------------:|
 | 0~11 MS| 0~20 MS|

* Scissor Test Screenshot

![](img/scissor_test.png)
