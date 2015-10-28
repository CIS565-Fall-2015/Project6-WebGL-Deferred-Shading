WebGL Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 6**

* Levi Cai
* Tested on: **Google Chrome** on
  Windows 8, i7-5500U @ 2.4GHz, 12GB, NVidia GeForce 940M 2GB

### Live Online

[![](img/thumb.png)](http://arizonat.github.io/Project6-WebGL-Deferred-Shading/)

### Demo Video

[![](img/video.png)](TODO)

### Features and Optimizations

All features turned on at once:

![](img/all.PNG)

## Toon Shading (with Ramp Shading option)

![](img/toon_shading.PNG)

## Naive Bloom Effect

![](img/bloom.PNG)

## Bloom Effect with 2 Pass Separable Filter

![](img/bloom_post2.PNG)

## Sphere vs. Box Scissor Testing Optimization

![](img/debug_scissor.PNG)

![](img/debug_spheres.PNG)

### Debug Views

![](img/depth.PNG)

![](img/position.PNG)

![](img/surface_normal.PNG)

### Analysis

g-buffer size of 3

![](img/fps_lights.png)

![](img/fps_scissor_fragments.png)
