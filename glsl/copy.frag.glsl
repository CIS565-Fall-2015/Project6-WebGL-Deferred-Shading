#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

uniform sampler2D u_colmap;
uniform sampler2D u_normap;

varying vec3 v_position;
varying vec3 v_normal;
varying vec2 v_uv;

uniform vec3 u_spec;

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}
void main() {
    // TODO: copy values into gl_FragData[0], [1], etc.
	
    vec3 normal=applyNormalMap(v_normal.xyz, texture2D(u_normap, v_uv).xyz);
	
	gl_FragData[0] =  vec4(v_position,u_spec.x);
	
    vec4 colordata= texture2D(u_colmap, v_uv); 
	float t=colordata.x*255.0+colordata.y*10000.0;
	gl_FragData[1] =  vec4(normal.xyz,t);
    gl_FragData[2] = colordata;
	
}
