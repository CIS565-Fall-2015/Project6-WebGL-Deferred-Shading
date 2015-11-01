#version 100
precision highp float;
precision highp int;

attribute vec3 a_position;

uniform mat4 u_viewMatrix;
uniform mat4 u_modelMatrix;
uniform mat4 u_projMatrix;

uniform float u_scale;
uniform vec3 u_pos;

varying vec2 v_uv;

void main() {

    gl_Position = u_projMatrix * u_viewMatrix * u_modelMatrix * vec4(a_position, 1.0);
	//gl_Position = vec4(1.1*a_position, 1.0);
	//gl_PointSize = u_scale;
    v_uv = gl_Position.xy * 0.5 + 0.5;
}
