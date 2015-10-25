#version 100
precision highp float;
precision highp int;

uniform sampler2D u_orig_color;
uniform sampler2D u_color;
uniform vec2 u_screen_inv;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);
const vec3 gauss = vec3(0.4, 0.25, 0.05);

void main() {
    vec4 color = texture2D(u_color, v_uv);
    vec4 orig_color = texture2D(u_orig_color, v_uv);

    if (color.a == 0.0) {
        color = SKY_COLOR;
    }

    vec4 top0_color = texture2D(u_color, vec2(v_uv.x, v_uv.y - u_screen_inv.y));
    vec4 top1_color = texture2D(u_color, vec2(v_uv.x, v_uv.y - u_screen_inv.y * 2.0));
    vec4 bottom0_color = texture2D(u_color, vec2(v_uv.x, v_uv.y + u_screen_inv.y));
    vec4 bottom1_color = texture2D(u_color, vec2(v_uv.x, v_uv.y + u_screen_inv.y * 2.0));

    vec4 blend = orig_color + top1_color * gauss.z + top0_color * gauss.y + color * gauss.x
        + bottom0_color * gauss.y + bottom1_color * gauss.z;
    gl_FragColor = 0.65 * blend;
}
