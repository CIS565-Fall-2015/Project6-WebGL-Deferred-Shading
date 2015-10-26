#version 100
precision highp float;
precision highp int;

uniform sampler2D u_orig_color;
uniform sampler2D u_color;
uniform vec2 u_screen_inv;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
    vec4 color = texture2D(u_color, v_uv);
    vec4 orig_color = texture2D(u_orig_color, v_uv);

    if (color.a == 0.0) {
        color = SKY_COLOR;
    }

    vec4 top_color = texture2D(u_color, vec2(v_uv.x, v_uv.y - u_screen_inv.y));
    vec4 top_left_color = texture2D(u_color, vec2(v_uv.x - u_screen_inv.x, v_uv.y - u_screen_inv.y));
    vec4 top_right_color = texture2D(u_color, vec2(v_uv.x + u_screen_inv.x, v_uv.y - u_screen_inv.y));
    vec4 bottom_color = texture2D(u_color, vec2(v_uv.x, v_uv.y + u_screen_inv.y));
    vec4 bottom_left_color = texture2D(u_color, vec2(v_uv.x - u_screen_inv.x, v_uv.y + u_screen_inv.y));
    vec4 bottom_right_color = texture2D(u_color, vec2(v_uv.x + u_screen_inv.x, v_uv.y + u_screen_inv.y));

    // Blend and perform edge ramping
    vec4 blend = -top_color - top_left_color - top_right_color + bottom_color + bottom_left_color + bottom_right_color;
    blend = vec4(vec3(max(max(blend.x, blend.y), blend.z)), 1.0);
    if(blend.x <= 0.2) {
        blend = vec4(0.0, 0.0, 0.0, 1.0);
    }
    else {
        blend = vec4(1.0);
    }

    gl_FragColor = (1.0 - blend) * orig_color;
}
