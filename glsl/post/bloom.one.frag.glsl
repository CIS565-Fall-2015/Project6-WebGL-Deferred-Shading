#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform vec2 u_screen_inv;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);
const vec3 gauss = vec3(0.4, 0.25, 0.05);

void main() {
    vec4 color = texture2D(u_color, v_uv);

    if (color.a == 0.0) {
        color = SKY_COLOR;
    }

    vec4 left0_color = texture2D(u_color, vec2(v_uv.x - u_screen_inv.x, v_uv.y));
    left0_color *= left0_color.a;
    vec4 left1_color = texture2D(u_color, vec2(v_uv.x - u_screen_inv.x * 2.0, v_uv.y));
    left1_color *= left1_color.a;
    vec4 right0_color = texture2D(u_color, vec2(v_uv.x + u_screen_inv.x, v_uv.y));
    right0_color *= right0_color.a;
    vec4 right1_color = texture2D(u_color, vec2(v_uv.x + u_screen_inv.x * 2.0, v_uv.y));
    right1_color *= right1_color.a;

    color *= color.a;

    gl_FragColor = left1_color * gauss.z + left0_color * gauss.y + color * gauss.x
        + right0_color * gauss.y + right1_color * gauss.z;
}
