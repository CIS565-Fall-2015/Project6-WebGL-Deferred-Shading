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

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}

// http://aras-p.info/blog/2009/07/30/encoding-floats-to-rgba-the-final/
// http://stackoverflow.com/questions/30242013/glsl-compressing-packing-multiple-0-1-colours-var4-into-a-single-var4-variab
float packRGBA( vec4 rgba ) {
  return dot( floor(rgba*255.0/64.0), vec4(64.0, 16.0, 4.0, 1.0) )/255.0;
}

void main() {
    // Copy values into gl_FragData[0], [1], etc.
    gl_FragData[0] = vec4(v_position, packRGBA(texture2D(u_colmap, v_uv)));
    gl_FragData[1] = vec4(applyNormalMap(v_normal, texture2D(u_normap, v_uv).rgb), u_specExp);
    //gl_FragData[2] = vec4(texture2D(u_colmap, v_uv).rgb, u_remove);
}
