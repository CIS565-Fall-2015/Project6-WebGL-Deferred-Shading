#version 100
precision highp float;
precision highp int;

uniform vec3 u_lightCol;

void main() {
    gl_FragColor = vec4(u_lightCol * .05, 1);
}
