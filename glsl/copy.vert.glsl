#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

uniform mat4 u_cameraMat;
uniform vec3 u_camPos;

attribute vec3 a_position;
attribute vec3 a_normal;
attribute vec2 a_uv;

varying vec3 v_position;
varying vec3 v_normal;
varying vec3 c_position;
varying vec2 v_uv;

void main() {
    gl_Position = u_cameraMat * vec4(a_position, 1.0);
    v_position = a_position;
	c_position = u_camPos;
    v_normal = a_normal;
    v_uv = a_uv;
}
