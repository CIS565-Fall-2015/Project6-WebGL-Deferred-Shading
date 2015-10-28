WebGL Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 6**

* Xinyue Zhu
* Tested on: **Google Chrome  46.0.2490.71 m** on
  Windows 10, i5-5200U @ 2.2GHz 8.00GB, GTX 960M 222MB 

### Live Online

[![](img/thumb.png)](http://Zhuxinyue909.github.io/Project6-WebGL-Deferred-Shading)

### Demo Video

[![](img/video.png)](https://www.youtube.com/watch?v=z_TlmlxQoGs)

========================
### Feature
Features:
<p>1.Blinn-Phong shading for point lights.</p>
<p>2.scissor test and debug view.</p>
<p>3.bloom shading using Gaussian blur.</p>
<p>4.Optimized g-buffer.</p> 
Extra:
<p>5.Toon shading, the width of the outline is changed due to the distance to the viewer, more like comic.</p>
<p>6.Allow variability in additional material properties. add extra cube.since all the texture I find for the cow makes it look wired.</p>
<p>7.Optimized 2 pass Gaussian bloom.</p>
<p>8.AABB box for light.</p>
##the toon effect
<p><img src="img/toon1.png"  width="330" height="200"><img src="img/toon2.png"  width="330" height="200"></p> 
Happy Helloween!
<p><img src="img/creepy.png"  width="330" height="200"><img src="img/blood.png"  width="330" height="200"></p> 
### Performance & Analysis

<p>1.The number of the light increase the memory usead is increase, and the FPS is decrease.</p>
<p>In the bloom effect, I choose 5*5 simples, int the toon I only calculate the left and top three samples, but their performace do not make much difference. However in the bloom effect, I devide Gaussian matrix into two passes, x and y pass. I think that's why it is a little faster. I think I should change the toon into x y pass to get a more accurate result. </p>
Increasing the number of the models, makes the program much slower.
<p><img src="img/chart1.png"  width="520" height="300"><p>
<p>these are the g-buffers improvment I made. First only disable the buffer do not make much difference.
<p>note: M1: pack the specular parameter into posision.w</p>
<p>M2:apply normal map before</p>
<p>M3:if I do not use the specular parameter in g-buffer and take the color value apart and reduce the number of g-buffer to 2.</p>
<p>Since I have to use the specular component, so I use the 3 buffers in the end. But reducing the number of g-buffers accelerate the program dramatically. </p>
<p><img src="img/chart2.png"  width="330" height="120"><p>
<p><img src="img/chart3.png"  width="360" height="200"> <img src="img/chart4.png"  width="360" height="200"><p>
<p>The debug view of the original bounding box</p>
<p><img src="img/debug2.png"  width="360" height="200">
<p>The debug view of the current bounding box. I calculate is as a "box" not a plane so the length of the box maybe bigger </p>
<img src="img/debug2.png"  width="360" height="200"><p>

When calculating the boundingbox, I was plan to buil a box with 6 point and apply transform an projection matrix on it and it is very slow so I did not use that method.


