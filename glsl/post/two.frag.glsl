#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform sampler2D o_color;
uniform vec2 u_screen_inv;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

// Gaussian
const vec3 G = vec3(0.399, 0.242, 0.054);

void main() {
    vec4 color = texture2D(u_color, v_uv);
    vec4 color_o = texture2D(o_color, v_uv);

    if (color.a == 0.0) {
        color = SKY_COLOR;
    }

    vec4 T2 = texture2D(u_color,vec2(v_uv.x, v_uv.y-u_screen_inv.y*2.0));
    vec4 T1 = texture2D(u_color,vec2(v_uv.x, v_uv.y-u_screen_inv.y*1.0));
    vec4 B1 = texture2D(u_color,vec2(v_uv.x, v_uv.y+u_screen_inv.y*1.0));
    vec4 B2 = texture2D(u_color,vec2(v_uv.x, v_uv.y+u_screen_inv.y*2.0));

    // Add to original
    vec4 blend = color_o + T2*G.z+T1*G.y+color*G.x+B1*G.y+B2*G.z;

    // Tone mapping
    blend.x = 0.7*pow(blend.x, 1.0);
    blend.y = 0.7*pow(blend.y, 1.0);
    blend.z = 0.7*pow(blend.z, 1.0);
    blend.a = 0.7*pow(blend.a, 1.0);

    gl_FragColor = blend;
}
