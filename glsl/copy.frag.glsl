#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

uniform sampler2D u_colmap;
uniform sampler2D u_normap;

varying vec3 v_position;
varying vec3 v_normal;
varying vec2 v_uv;

#define NUM_GBUFFERS 4

void main() {
    vec3 normap = texture2D(u_normap, v_uv).xyz;
    vec3 colmap = texture2D(u_colmap, v_uv).xyz;
    gl_FragData[0] = vec4(v_position, colmap.x);
    gl_FragData[1] = vec4(v_normal, colmap.y);
    gl_FragData[2] = vec4(normap, colmap.z);
}
