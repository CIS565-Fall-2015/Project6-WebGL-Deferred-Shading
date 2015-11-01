#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4
#define OUTLINE_DEPTH 0.001

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

uniform int u_width;
uniform int u_height;

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
    
    // TODO: Extract needed properties from the g-buffers into local variables
    vec3 pos        = gb0.xyz;                      // World-space position
    vec3 geomnor    = vec3(gb0.w, gb1.x, gb1.y);      // Normals of the geometry as defined, without normal mapping
    vec3 normap     = vec3(gb1.z, gb1.w, gb2.x);       // The color map - unlit "albedo" (surface color)
    vec3 col        = vec3(gb2.y, gb2.z, gb2.w);       // The raw normal map (normals relative to the surface they're on)
    vec3 nor        = applyNormalMap(geomnor, normap);     // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)

    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }
    
    float xPixel = 2.0/float(u_width);
    float yPixel = 2.0/float(u_height);
    
    //edge detection
    if(abs(texture2D(u_depth, vec2(v_uv.x + xPixel, v_uv.y)).x - depth) > OUTLINE_DEPTH ||
       abs(texture2D(u_depth, vec2(v_uv.x - xPixel, v_uv.y)).x - depth) > OUTLINE_DEPTH || 
       abs(texture2D(u_depth, vec2(v_uv.x, v_uv.y + yPixel)).x - depth) > OUTLINE_DEPTH ||
       abs(texture2D(u_depth, vec2(v_uv.x, v_uv.y - yPixel)).x - depth) > OUTLINE_DEPTH ){
        gl_FragColor = vec4(0, 0, 0, 1);
        return;
    }
    
    vec3 lightDir = normalize(u_lightPos - pos);
    float lightDist = distance(u_lightPos, pos);
    float attenuation = max(0.0, u_lightRad - lightDist);
    float lambertian = clamp(dot(lightDir, nor), 0.0, 1.0) * attenuation;
    
    //ramp shading
    float step1 = 0.25;
    float step2 = 0.5;
    float step3 = 0.75;
    
    if(lambertian < step1) lambertian = 0.0;
    else if(lambertian < step2) lambertian = step1;
    else if(lambertian < step3) lambertian = step2;
    else lambertian = step3;
    
    gl_FragColor.xyz = lambertian * col * u_lightCol;
}
