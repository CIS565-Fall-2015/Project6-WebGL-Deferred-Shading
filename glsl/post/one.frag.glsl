#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform float u_bloom;
varying vec2 v_uv;
uniform float u_dir;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
    vec4 color = texture2D(u_color, v_uv);

    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }

    
    gl_FragColor = color;
}
