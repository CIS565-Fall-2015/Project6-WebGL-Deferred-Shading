#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform sampler2D u_lightCol;
uniform sampler2D u_lightPos;
uniform sampler2D u_lightList;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

uniform float u_lightOffsetLength;
uniform float u_totalLight;

uniform int u_lightOffset;
uniform int u_lightNo;

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
    float depth = texture2D(u_depth, v_uv).x;
    
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }
    
    // TODO: Extract needed properties from the g-buffers into local variables
    vec3 pos        = gb0.xyz;                      // World-space position
    vec3 geomnor    = vec3(gb0.w, gb1.x, gb1.y);      // Normals of the geometry as defined, without normal mapping
    vec3 normap     = vec3(gb1.z, gb1.w, gb2.x);       // The color map - unlit "albedo" (surface color)
    vec3 col        = vec3(gb2.y, gb2.z, gb2.w);       // The raw normal map (normals relative to the surface they're on)
    vec3 nor        = applyNormalMap(geomnor, normap);     // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)
   
    gl_FragColor.a = 1.0;
    for(int i = 0; i < 1000; i++){
        if(i >= u_lightNo) return;
        
        float currLight = (float(u_lightOffset + i) + 0.5)/u_lightOffsetLength;
        float light_uv = texture2D(u_lightList, vec2(currLight,0.5)).x + 0.5;
        light_uv /= u_totalLight;
        
        vec4 lightPos = texture2D(u_lightPos, vec2(light_uv,0.5));
        vec4 lightcol = texture2D(u_lightCol, vec2(light_uv,0.5));
        
        vec3 lightDir = normalize(lightPos.xyz - pos);
        float lightDist = distance(lightPos.xyz, pos);
        float attenuation = max(0.0, lightcol.w - lightDist);
        float lambertian = clamp(dot(lightDir, nor), 0.0, 1.0);
        
        gl_FragColor.xyz += lambertian * col * lightcol.xyz * attenuation;
    }
}
