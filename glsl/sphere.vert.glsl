#version 100
precision highp float;
precision highp int;

attribute vec3 a_position;

uniform mat4 u_cameraMat;
uniform vec4 u_lightTrans; // [pos, radius]

varying vec2 v_uv;

void main() {

	float scale = u_lightTrans.w;
	vec3 translation = u_lightTrans.xyz;

    vec4 position = vec4( (a_position * scale) + translation, 1.0);

    gl_Position = u_cameraMat * position; // gl_Position should be in NDC coordinates

    v_uv = gl_Position.xy * 0.5 + 0.5;
}
