#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

varying vec2 v_uv;

void main() {
    vec4 color = texture2D(u_color, v_uv);
    gl_FragColor = color;
}
