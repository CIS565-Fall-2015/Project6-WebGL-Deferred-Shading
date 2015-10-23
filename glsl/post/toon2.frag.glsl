#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform sampler2D o_color;
uniform vec2 u_screen_inv;

varying vec2 v_uv;

void main() {
    vec4 color = texture2D(u_color, v_uv);
    vec4 color_o = texture2D(o_color, v_uv);

    vec4 T1 = texture2D(u_color,vec2(
        v_uv.x,
        v_uv.y-u_screen_inv.y));
    vec4 T1L = texture2D(u_color,vec2(
        v_uv.x-u_screen_inv.x,
        v_uv.y-u_screen_inv.y));
    vec4 T1R = texture2D(u_color,vec2(
        v_uv.x+u_screen_inv.x,
        v_uv.y-u_screen_inv.y));

    vec4 B1 = texture2D(u_color,vec2(
        v_uv.x,
        v_uv.y+u_screen_inv.y));
    vec4 B1L = texture2D(u_color,vec2(
        v_uv.x-u_screen_inv.x,
        v_uv.y+u_screen_inv.y));
    vec4 B1R = texture2D(u_color,vec2(
        v_uv.x+u_screen_inv.x,
        v_uv.y+u_screen_inv.y));

    vec4 blend = -T1*1.0-T1L*1.0-T1R*1.0+B1*1.0+B1L*1.0+B1R*1.0;

    // Edge ramping
    blend = vec4(vec3(max(max(blend.x, blend.y), blend.z)), 1);

    if (blend.x <= 0.3){
        blend = vec4(vec3(0.0), 1);
    } else {
        blend = vec4(1.0);
    }
    
    blend = (1.0-blend) * color_o;

    gl_FragColor = blend;
}
