#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

uniform float u_width;
uniform float u_height;
uniform vec4 u_settings;

uniform float u_kernel[5];

void main() {
    vec4 color = texture2D(u_color, v_uv);

    // Separable filter

    gl_FragColor = clamp(color, 0.0, 1.0);
}
