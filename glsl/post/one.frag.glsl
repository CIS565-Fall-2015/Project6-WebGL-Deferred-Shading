#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform vec2 u_screen_inv;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

// Gaussian
const vec3 G = vec3(0.399, 0.242, 0.054);

void main() {
    vec4 color = texture2D(u_color, v_uv);

    if (color.a == 0.0) {
        color = SKY_COLOR;
    }

    vec4 L2 = texture2D(u_color,vec2(v_uv.x-u_screen_inv.x*2.0,v_uv.y));
    vec4 L1 = texture2D(u_color,vec2(v_uv.x-u_screen_inv.x*1.0,v_uv.y));
    vec4 R1 = texture2D(u_color,vec2(v_uv.x+u_screen_inv.x*1.0,v_uv.y));
    vec4 R2 = texture2D(u_color,vec2(v_uv.x+u_screen_inv.x*2.0,v_uv.y));

    color = color*color.a;
    L2 = L2*L2.a;
    L1 = L1*L1.a;
    R1 = R1*R1.a;
    R2 = R2*R2.a;

    gl_FragColor = L2*G.z+L1*G.y+color*G.x+R1*G.y+R2*G.z;
}
