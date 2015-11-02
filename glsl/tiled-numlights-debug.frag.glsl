#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 6

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

uniform int u_width;
uniform int u_height;
uniform int u_tileSize;
uniform int u_numLightsMax;

uniform sampler2D u_light_list_indices; // an alpha buffer, so need to mul values by 100 and clamp
//uniform sampler2D u_light_lists; // an alpha buffer, so need to mul values by 100 and clamp

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
    vec4 gb0 = texture2D(u_gbufs[0], v_uv); // texture mapped color
    vec4 gb1 = texture2D(u_gbufs[1], v_uv); // world space position
    vec4 gb2 = texture2D(u_gbufs[2], v_uv); // geometry normal
    vec4 gb3 = texture2D(u_gbufs[3], v_uv); // mapped normal
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables
    // These definitions are suggested for starting out, but you will probably want to change them.
    vec3 pos = gb1.xyz;     // World-space position
    vec3 geomnor = gb2.xyz;  // Normals of the geometry as defined, without normal mapping
    vec3 colmap = gb0.xyz;  // The color map - unlit "albedo" (surface color)
    vec3 normap = gb3.xyz;  // The raw normal map (normals relative to the surface they're on)
    vec3 nor = normalize(applyNormalMap(geomnor, normap));     // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)

    gl_FragColor = vec4(vec3(depth), 1.0);

    //gl_FragColor = texture2D(u_gbufs[4], v_uv);
}