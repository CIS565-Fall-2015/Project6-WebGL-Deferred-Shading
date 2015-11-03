#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

uniform sampler2D u_colmap;
uniform sampler2D u_normap;

uniform int u_specularExp;
uniform float u_specularCoeff;

varying vec3 v_position;
varying vec3 v_normal;
varying vec2 v_uv;

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    if(length(normap) == 0.0) return geomnor;
    
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}

void main() {
    vec4 clr = texture2D(u_colmap, v_uv);
    vec4 normap = texture2D(u_normap, v_uv);
    
    vec3 normal = applyNormalMap(v_normal.xyz, normap.xyz);
    
    gl_FragData[0] = vec4(v_position.x, v_position.y, v_position.z, u_specularExp);
    gl_FragData[1] = vec4(normal.x, normal.y, normal.z, u_specularCoeff);
    gl_FragData[2] = vec4(clr.x, clr.y, clr.z, 0);
}
