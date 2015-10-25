#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 2

uniform int u_debug;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.66, 0.73, 1.0, 1.0);

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
    return vec4(a,b,c,d);
}

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    //vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    //vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables
    // These definitions are suggested for starting out, but you will probably want to change them.
    vec3 pos = gb0.xyz;     // World-space position
    //vec3 geomnor = gb1.xyz;  // Normals of the geometry as defined, without normal mapping
    vec3 colmap = unpackRGBA(gb0.w).xyz;  // The color map - unlit "albedo" (surface color)
    //vec3 normap = gb3.xyz;  // The raw normal map (normals relative to the surface they're on)
    //vec3 nor = applyNormalMap(geomnor, normap);     // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)
    vec3 nor = gb1.xyz;

    if (u_debug == 0) {
        gl_FragColor = vec4(vec3(depth), 1.0);
    } else if (u_debug == 1) {
        gl_FragColor = vec4(abs(pos) * 0.1, 1.0);
    } else if (u_debug == 2) {
        //gl_FragColor = vec4(abs(geomnor), 1.0);
        gl_FragColor = vec4(abs(nor), 1.0);
    } else if (u_debug == 3) {
        gl_FragColor = vec4(colmap, 1.0);
    } /*else if (u_debug == 4) {
        gl_FragColor = vec4(normap, 1.0);
    } else if (u_debug == 5) {
        gl_FragColor = vec4(abs(nor), 1.0);
    }*/ else {
        gl_FragColor = vec4(1, 0, 1, 1);
    }
}
