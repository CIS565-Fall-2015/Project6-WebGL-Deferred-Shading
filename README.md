WebGL Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 6**

* Kangning Li
* Tested on: **Google Chrome 46.0.2490.80** on
  Ubuntu 14.04, i5-3320M @ 2.60GHz 8GB, Intel HD 4000 (Personal laptop)

### Live Online

[![](img/thumb.png)](http://likangning93.github.io/Project6-WebGL-Deferred-Shading)

### Demo Video

[![](img/video.png)](TODO)

This repository contains a WebGL deferred shader with the following features:
- deferred shading using WEBGL_draw_buffers
- a toggleable "compressed g-buffer" pipeline
- toggleable scissor testing for both the compressed and uncompressed pipelines
- a tile-based lighting pipeline
- toon shading
- bloom as a post-processing effect

Running the demo above requires support for `OES_texture_float`, `OES_texture_float_linear`, `WEBGL_depth_texture`, and `WEBGL_draw_buffers`. You can check your support on [WebGL Report](http://webglreport.com/).

### Deferred Shading Overview
The standard deferred shader in this project renders data (position, normals, sampled color, depth, etc.) about what is visible in the scene to a set of WebGL textures referred to as g-buffers. These can be viewed in the debugView settings in the demo. These textures are then passed to a lighting shader that only performs lighting calculations on what is visible in the scene.

### G-buffer compression
The default pipeline uses 4 g-buffers of vec4s to pass scene information to the lighting shader, along with a buffer for depth:
- position
- normal provided by the scene geometry
- texture mapped color
- texture mapped normal

The "compressed" pipeline instead uses 2 g-buffers along with depth:
- texture mapped color
- "compressed" 2-component normal vector (computed from texture mapped and geometry)

This compression and decompression of the normal depends on the normal being unit length, which lets the lighting shader compute the magnitude of the normal`s `z` component from its `x` and `y` components. The cardinality of the `z` component is sent as part of the `y` component by padding. If the `z` component is negative , the `y` component is "padded" with a constant so that its magnitude is greater than 1. The lighting shader then only needs to assess the `y` component`s magnitude to determine the `z` component`s cardinality and correctly rebuild the `y` component.

The lighting shader also reconstructs the world position of a pixel from its depth and screen coordinates with the current view`s camera matrix. More details on the technique can be found [here](https://mynameismjp.wordpress.com/2009/03/10/reconstructing-position-from-depth/) and [here](http://stackoverflow.com/questions/22360810/reconstructing-world-coordinates-from-depth-buffer-and-arbitrary-view-projection).

Using "compressed" g-buffers is essentially a tradeoff between memory access and computation, which is usually ideal for GPU applications as GPUs are better at compute than memory access. Even in this imperfect case, in which the 2-component normals are still stored in a vec4 texture, reducing the number of g-buffers still leads to a noticeable improvement in performance. This performance improvement is apparent even as the number of lights increases, as the both pipelines run the lighting shader once per light.

![](img/charts/gbufs.png)

### Scissor test

Both the "compressed" and "uncompressed" g-buffer pipelines can restrict the render area of each light using a scissor test, which in most cases speeds up the lighting shader computation for each light. This scissor test also allows us to skip lighting for lights that couldn't possibly be visible in the viewport, which is likely a large part of the performance boost. However, the scissor test is only really useful for the "general" case, where a light's influence covers a relatively small area of the screen. In the case that a light is very close to the camera, the scissor test becomes less beneficial as the light pass for that particular light will essentially span the entire screen.

![](img/charts/scissor.png)

### Tile based lighting


