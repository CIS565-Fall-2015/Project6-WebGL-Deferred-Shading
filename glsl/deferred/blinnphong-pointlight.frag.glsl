#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 2

#define TOON_STEP 0.2
#define TOON_DEPTH_THRESHOLD 1.0

uniform bool u_toonShading;

uniform vec3 u_cameraPos;

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

/*
vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}
*/

vec4 EncodeFloatRGBA( float v ) {
    vec4 enc = vec4(1.0, 255.0, 65025.0, 160581375.0) * v;
    enc = fract(enc);
    enc -= enc.yzww * vec4(1.0/255.0,1.0/255.0,1.0/255.0,0.0);
    return enc;
    
}


void main() {

    vec2 uv = vec2(gl_FragCoord.x / 800.0, gl_FragCoord.y / 600.0);
    
    vec4 gb0 = texture2D(u_gbufs[0], uv);
    vec4 gb1 = texture2D(u_gbufs[1], uv);
    
    float depth = texture2D(u_depth, uv).x;

    

/*
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    
    float depth = texture2D(u_depth, v_uv).x;
    */
    // TODO: Extract needed properties from the g-buffers into local variables
    
    //TODO:optimize gbuffer structure
    vec3 pos = gb0.xyz;
    vec3 geomnor = gb1.xyz;
    //vec3 colmap = EncodeFloatRGBA(gb0.w).rgb;
    vec3 colmap = vec3(gb1.z,gb1.w,gb0.w);
    
    vec3 nor = gb1.xyy;
    nor.z = sqrt(1.0 - nor.x*nor.x - nor.y*nor.y);
    
    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }
    
    
    
    vec3 l = u_lightPos - pos;
    
    float dist = length(l);
    
    l = l / dist;
    
    float attenuation = clamp(1.0 - dist/u_lightRad, 0.0, 1.0);
    
    float diffuse_cos = max(dot(l,nor),0.0);
    if(u_toonShading)
    {
        diffuse_cos = TOON_STEP * float(floor(diffuse_cos/TOON_STEP));
    }
    
    
    vec3 diffuse = diffuse_cos * u_lightCol * colmap;
    
    vec3 v = normalize(u_cameraPos - pos);
    vec3 r = -l + 2.0 * dot(l,nor) * nor;
    float specular_cos = max(dot(r,v),0.0);
    if(u_toonShading)
    {
        specular_cos = TOON_STEP * float(floor(specular_cos/TOON_STEP));
    }
    
    vec3 specular = pow( specular_cos, 32.0) * u_lightCol * colmap;
    
    gl_FragColor = vec4 (   attenuation * (diffuse + specular) , 1.0);
   
    //gl_FragColor = vec4(v_uv,0.0,1.0);
}
