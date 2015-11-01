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
    // TODO: copy values into gl_FragData[0], [1], etc.
    vec4 clr = texture2D(u_colmap, v_uv);
    vec4 normap = texture2D(u_normap, v_uv);
    
    gl_FragData[0] = vec4(v_position.x, v_position.y, v_position.z, v_normal.x);
    gl_FragData[1] = vec4(v_normal.y, v_normal.z, normap.x, normap.y);
    gl_FragData[2] = vec4(normap.z, clr.x, clr.y, clr.z);
}
