#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform vec2 u_screen_inv;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
    vec4 color = texture2D(u_color, v_uv);

    // https://en.wikipedia.org/wiki/Sobel_operator

    vec4 L1 = texture2D(u_color,vec2(
        v_uv.x-u_screen_inv.x,
        v_uv.y));
    vec4 L1T = texture2D(u_color,vec2(
        v_uv.x-u_screen_inv.x,
        v_uv.y-u_screen_inv.y));
    vec4 L1B = texture2D(u_color,vec2(
        v_uv.x-u_screen_inv.x,
        v_uv.y+u_screen_inv.y));

    vec4 R1 = texture2D(u_color,vec2(
        v_uv.x+u_screen_inv.x,
        v_uv.y));
    vec4 R1T = texture2D(u_color,vec2(
        v_uv.x+u_screen_inv.x,
        v_uv.y-u_screen_inv.y));
    vec4 R1B = texture2D(u_color,vec2(
        v_uv.x+u_screen_inv.x,
        v_uv.y+u_screen_inv.y));

    gl_FragColor = -L1*1.0-L1T*1.0-L1B*1.0+R1*1.0+R1T*1.0+R1B*1.0;
}
