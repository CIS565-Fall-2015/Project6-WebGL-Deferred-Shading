#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

uniform sampler2D u_colmap;
uniform sampler2D u_normap;

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

/*
vec4 EncodeFloatRGBA( float v ) {
    float4 enc = float4(1.0, 255.0, 65025.0, 160581375.0) * v;
    enc = frac(enc);
    enc -= enc.yzww * float4(1.0/255.0,1.0/255.0,1.0/255.0,0.0);
    return enc;
}
float DecodeFloatRGBA( vec4 rgba ) {
    return dot( rgba, float4(1.0, 1/255.0, 1/65025.0, 1/160581375.0) );
}
*/


void main() {
    // TODO: copy values into gl_FragData[0], [1], etc.
    
    /*
    vec3 nor = applyNormalMap (v_normal, texture2D(u_normap,v_uv).rgb);
    vec4 col = texture2D(u_colmap, v_uv);
    
    
    gl_FragData[0] = vec4( v_position,  Decode(col));
    gl_FragData[1] = vec4( nor.xyz, 1.0);
    */
    
    
    
    // naive 4 gbuffers
    gl_FragData[0] = vec4( v_position,1.0 );
    gl_FragData[1] = vec4( v_normal.xyz,1.0);
    gl_FragData[2] = texture2D(u_colmap, v_uv);
    gl_FragData[3] = texture2D(u_normap,v_uv);
    
}
