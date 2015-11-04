WebGL Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 6**

* Ratchpak (Dome) Pongmongkol
* Tested on: **Google Chrome 46.0.2490.71 (64-bit)** on Windows**, 2.4 GHz Intel Core i7, 16 GB 1600 MHz DDR3, NVIDIA GeForce GT 650M 1024 MB (rMBP 15" 2013)

### Demo Video
[![](img/video.PNG)](https://youtu.be/1gPLm1cwa8M)

### Features
This is a deferred Blinn-Phong shading with 3 g-buffers as follows 

          x     y     z     w 
    1 : pos.x pos.y pos.z  sExp 
    2 : nor.x nor.y nor.z sCoeff 
    3 : clr.x clr.y clr.z   0

when 
- pos = Position 
- nor = Normal (transformed by a bump map at the given fragment) 
- col = Color (pulled out from a texture map at the given fragment)
- sExp = Specular Exponent 
- sCoeff = Specular Coefficient

#### Effects (Each can be stacked on top of each other)
- **Toon Shading** : Ramp Shading + Sobel operator (for detecting edges)
- **2-pass Gaussian Blur Bloom** : use Gaussian function to multiply with color from neighbor pixels that has RGB components larger than 1.0
- **Screen Space Motion Blur** : For each pixel, convert back to world space, then use the viewProjection matrix of the previous frame to get the previous "screen space" position of each pixel. Calculate a velocity from that and use it to do motion blur.

### Optimization
##### Tile-based deferred shading

###  Acknowledgement
- Motion Blur : http://http.developer.nvidia.com/GPUGems3/gpugems3_ch27.html
- Bloom : http://http.developer.nvidia.com/GPUGems/gpugems_ch21.html
- Gaussian blur equation function : https://www.shadertoy.com/view/XdfGDH
- Sobel Operator for Edge Detection: https://en.wikipedia.org/wiki/Sobel_operator
