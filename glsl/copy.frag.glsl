#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

uniform sampler2D u_colmap;
uniform sampler2D u_normap;
uniform float u_material;

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


void main() {
    // TODO: copy values into gl_FragData[0], [1], etc.
    gl_FragData[0] = vec4(v_position, 1.0);
    vec4 gnorm = vec4(normalize(v_normal), 0.0);
    gl_FragData[2] = texture2D(u_colmap, v_uv);
    vec4 norm = texture2D(u_normap, v_uv);
    gl_FragData[1].xyz = applyNormalMap(vec3(gnorm), vec3(norm));
    gl_FragData[1].w = u_material;
}
