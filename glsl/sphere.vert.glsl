#version 100
precision highp float;
precision highp int;

attribute vec3 a_position;

uniform mat4 u_cameraMatrix;

uniform float u_scale;
uniform vec3 u_pos;

varying vec2 v_uv;

void main() {

	gl_Position = u_cameraMatrix * vec4(a_position * u_scale + u_pos, 1.0);
	
    v_uv = gl_Position.xy * 0.5 + 0.5;
}
