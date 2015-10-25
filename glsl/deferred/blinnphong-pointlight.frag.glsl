#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 2

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform vec3 u_camPos;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

uniform int u_toon;

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
vec4 unpackRGBA( float v ) {
    float a = floor(v*255.0/64.0)*64.0/255.0;
    v -= a;
    float b = floor(v*255.0/16.0)*16.0/255.0;
    v -= b;
    b *= 4.0;
    float c = floor(v*255.0/4.0)*4.0/255.0;
    v -= c;
    c *= 16.0;
    float d = v*255.0 * 64.0 / 255.0;
    return vec4(a,b,c,d)/0.75;
}

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    //vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    //vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;
    // Extract needed properties from the g-buffers into local variables
    vec3 pos = gb0.xyz;     // World-space position
    //vec3 geomnor = gb1.xyz;  // Normals of the geometry as defined, without normal mapping
    vec3 colmap = unpackRGBA(gb0.w).xyz;  // The color map - unlit "albedo" (surface color)
    vec3 nor = gb1.xyz;  // The raw normal map (normals relative to the surface they're on)
    //vec3 nor = applyNormalMap(geomnor, normap);     // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)
    float specExp = gb1.w;
    //float removeChannel = gb2.w;

    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }

    float dist = length(pos-u_lightPos);
    if (dist > u_lightRad){
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }

    // Camera at (0,0,0)
    vec3 V = normalize(u_camPos-pos);
    vec3 L = normalize(u_lightPos-pos);
    vec3 H = normalize(L+V);

    //float specExp = 10.0;
    float diffIntense = max(dot(nor, L), 0.0);
    float specIntense = pow(max(dot(nor, H), 0.0), specExp);
    float falloff = (1.0-dist/u_lightRad)/pow(dist/u_lightRad, 0.7);
/*
    if (removeChannel == 0.0) colmap.x = 0.0;
    if (removeChannel == 1.0) colmap.y = 0.0;
    if (removeChannel == 2.0) colmap.z = 0.0;
*/
    // Toon ramping
    // Concept: http://prideout.net/blog/?p=22#toon
    if (u_toon == 1){
        float steps = 4.0;
        diffIntense = ceil(diffIntense*steps)/steps;
        specIntense = ceil(specIntense*steps)/steps;
        falloff = ceil(falloff*steps)/steps;
        gl_FragColor = vec4(falloff*(diffIntense*colmap*u_lightCol+specIntense*vec3(1.0)), falloff);
    } else {
        gl_FragColor = vec4(falloff*(diffIntense*colmap*u_lightCol+specIntense*vec3(1.0)), falloff);
    }
}
