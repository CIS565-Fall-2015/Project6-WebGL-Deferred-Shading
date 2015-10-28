WebGL Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 6**

* Ziye
* Tested on: Google Chrome 41.0.2272.89 m on Windows 10, i7-4710MQ @ 2.50GHz 32GB, AMD HD8970M (Personal Laptop)


### Demo Video

[![](img/video.png)](https://youtu.be/maYqPVo_w_U)


##Progress
======================
###Debug View

Here I generate the simple debug view by visualize the data pass from the copy shader, which use different properties (depth, color, position, normal, etc.) as different texture to pass for later processing.

* Depth Map
![](img/debug_img/depth_1025.png)
* Color Map
![](img/debug_img/colormap_1025.png)
* Position Map
![](img/debug_img/position_1025.png)
* Normal Map
![](img/debug_img/normap_1025.png)
* Geometry Normal
![](img/debug_img/geonormal_1025.png)
* Surface Normal Map
![](img/debug_img/surfacenormal_1025.png)

### Lightning
* Ambient Light

I am using the global light with distance attenuation to generate the ambient light effect. As can be seen from the image below, the farther the distance, the darker it is.

![](img/light/ambient_1025.png)
* Bling Phong
![](img/light/blinnphong_1025.png)

### Special Effects
* Bloom
![](img/light/bloom.png)
* Toon
![](img/light/toon.png)

### Optimization
* Without G-Buffer Optimization
![](img/profile/wo_g_buffer_optimization.png)

* With G-Buffer Optimization
![](img/profile/w_g_buffer_optimization.png)

*Scissor test
![](img/debug_img/Sc_debug.png)

