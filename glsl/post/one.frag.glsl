#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

uniform sampler2D u_glow;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
    vec4 color = texture2D(u_color, v_uv);

    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }

    vec4 glow = texture2D(u_glow, v_uv);
    
    gl_FragColor = color;
    //gl_FragColor = color + glow;
    //gl_FragColor = glow;
}
