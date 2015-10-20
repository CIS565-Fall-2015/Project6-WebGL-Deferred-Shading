#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

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

void main() {
    // Load properties from the g-buffers
    // TODO: change for optimized g-buffers
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;
    vec3 pos = gb0.xyz;
    vec3 geomnor = normalize(gb1.xyz);
    vec3 colmap = gb2.xyz;
    vec3 normap = gb3.xyz;
    vec3 nor = applyNormalMap(geomnor, normap);
    // ----

    if (u_debug == 0) {
        gl_FragColor = vec4(vec3(depth), 1.0);
    } else if (u_debug == 1) {
        gl_FragColor = vec4(abs(pos) * 0.1, 1.0);
    } else if (u_debug == 2) {
        gl_FragColor = vec4(abs(geomnor), 1.0);
    } else if (u_debug == 3) {
        gl_FragColor = vec4(colmap, 1.0);
    } else if (u_debug == 4) {
        gl_FragColor = vec4(normap, 1.0);
    } else if (u_debug == 5) {
        gl_FragColor = vec4(abs(nor), 1.0);
    } else {
        gl_FragColor = vec4(1, 0, 1, 1);
    }
}
