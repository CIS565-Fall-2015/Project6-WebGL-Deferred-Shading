#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

uniform sampler2D u_colmap;
uniform sampler2D u_normap;

varying vec3 v_position;
varying vec3 v_normal;
varying vec2 v_uv;

void main() {

    //position
    gl_FragData[0] = vec4(v_position, 1.0);

    // color/albedo
    gl_FragData[1] = texture2D(u_colmap, v_uv);

    // surface normal
    gl_FragData[2] = texture2D(u_normap, v_uv);
}
