#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform vec3 u_camPos;
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
    // Extract needed properties from the g-buffers into local variables
    vec3 pos = gb0.xyz;     // World-space position
    vec3 geomnor = gb1.xyz;  // Normals of the geometry as defined, without normal mapping
    vec3 colmap = gb2.xyz;  // The color map - unlit "albedo" (surface color)
    vec3 normap = gb3.xyz;  // The raw normal map (normals relative to the surface they're on)
    vec3 nor = applyNormalMap(geomnor, normap);     // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)

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

    float specExp = 10.0;
    float diffIntense = max(dot(nor, L), 0.0);
    float specIntense = pow(max(dot(nor, H), 0.0), specExp);
    float falloff = 1.0/pow(dist, 2.0);

    gl_FragColor = vec4(falloff*(diffIntense*colmap*u_lightCol+specIntense*vec3(1.0)), falloff);
}
