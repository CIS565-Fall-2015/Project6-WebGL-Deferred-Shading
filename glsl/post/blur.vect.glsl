#version 100
precision highp float;
precision highp int;

varying vec2 v_uv

void main() {
	v_uv = uv;
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}