#version 100
precision highp float;
precision highp int;

uniform mat4 u_cameraMat;
uniform mat4 u_transformMat;

attribute vec3 a_position;

varying vec3 v_position;

varying vec2 v_uv;

void main() {
    //gl_Position = vec4(a_position, 1.0);
    //v_uv = a_position.xy * 0.5 + 0.5;
    
    
    gl_Position = u_cameraMat * u_transformMat * vec4(a_position, 1.0);
    v_uv = a_position.xy * 0.5 + 0.5;
    
    v_position = a_position;
}
