#version 100
precision highp float;
precision highp int;

uniform float u_lightOffsetX;
uniform float u_totalLight;

varying vec2 v_uv;

void main() {
    gl_FragColor.x += u_lightOffsetX / u_totalLight;
}
