#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform vec3 u_cameraPos;

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables
    
    //TODO:optimize gbuffer structure
    vec3 pos = gb0.xyz;
    vec3 geomnor = gb1.xyz;
    vec3 colmap = gb2.xyz;
    vec3 normap = gb3.xyz;
    
    vec3 nor = applyNormalMap(geomnor, normap);

    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }
    
    vec3 l = u_lightPos - pos;
    
    float drop = 1.0/length(l);
    
    l = l*drop;
    
    vec3 diffuse = u_lightRad * max(dot(l,nor),0.0) * u_lightCol * colmap;
    
    vec3 v = normalize(u_cameraPos - pos);
    vec3 r = -l + 2.0 * dot(l,nor) * nor;
    vec3 specular = u_lightRad * pow(max(dot(r,v),0.0), 32.0) * u_lightCol * colmap;
    
    gl_FragColor = vec4 (clamp( drop*drop *(diffuse + specular) , 0.0, 1.0 ) , 1.0);
}
