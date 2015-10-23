#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

uniform sampler2D u_colmap;
uniform sampler2D u_normap;

uniform float u_specExp;
uniform float u_remove;

varying vec3 v_position;
varying vec3 v_normal;
varying vec2 v_uv;

void main() {
    // Copy values into gl_FragData[0], [1], etc.
    gl_FragData[0] = vec4(v_position, 1.0);
    gl_FragData[1] = vec4(v_normal, u_specExp);
    gl_FragData[2] = vec4(texture2D(u_colmap, v_uv).rgb, u_remove);
    gl_FragData[3] = vec4(texture2D(u_normap, v_uv).rgb, 1.0);
}
