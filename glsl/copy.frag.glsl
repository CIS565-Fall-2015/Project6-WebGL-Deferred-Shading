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

	 // color/albedo
    gl_FragData[0] = texture2D(u_colmap, v_uv);

    // position
    gl_FragData[1] = vec4(v_position, 1.0);

    // surface normal
    gl_FragData[2] = texture2D(u_normap, v_uv);

    // normal
    gl_FragData[3] = vec4(v_normal, 1.0);
}
