#version 100
precision highp float;
precision highp int;

uniform mat4 u_cameraMat;
uniform mat4 u_transformMat;

attribute vec3 a_position;


varying vec2 v_uv;

void main() {
    
    vec4 tmp = u_cameraMat * u_transformMat * vec4(a_position, 1.0);
    gl_Position = tmp;
    
    
    
    //v_uv = a_position.xy * 0.5 + 0.5;
    
    v_uv = tmp.xy * 0.5 + 0.5;
    
}
