#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

uniform sampler2D u_colmap;
uniform sampler2D u_normap;

varying vec2 v_position;
varying vec3 v_normal;
varying vec2 v_uv;

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}

void main() {
    // TODO: copy values into gl_FragData[0], [1], etc.
    gl_FragData[0] = texture2D(u_colmap, v_uv);
    gl_FragData[1].xy = v_position;

    // compress the normal
    vec3 mappedNormal = normalize(applyNormalMap(v_normal, texture2D(u_normap, v_uv)));
    // the normal is normalized, which means no element has magnitude greater than 1
    // the fact that it's normalized also means given x and y we can compute z: x ^ 2 + y ^ 2 = 1.0 - z ^ 2
    // so we'll introduce a new invariant: if abs(x) > 1.0, z is negative. else, z is positive.
    if (mappedNormal.z < 0.0) mappedNormal.x += mappedNormal.x / abs(mappedNormal.x);
    gl_FragData[1].zw = mappedNormal.xy;
}
