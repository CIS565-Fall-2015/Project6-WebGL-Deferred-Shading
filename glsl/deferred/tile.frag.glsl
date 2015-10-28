#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform int u_toon;

uniform vec3 u_cameraPos;
uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;
uniform sampler2D u_lightsPR;
uniform sampler2D u_lightsC;

varying vec2 v_uv;

const float TOON_STEPS = 3.0;

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}

// vec3(diffuse, specular, falloff)
vec3 lightTerms(vec3 normal, vec3 pos) {
    float lightDist = length(pos - u_lightPos);
    float falloff = max(0.0, u_lightRad - lightDist);

    vec3 camdir   = normalize(u_cameraPos - pos);
    vec3 lightdir = normalize(u_lightPos  - pos);

    float diffuseTerm = clamp(dot(normal, lightdir), 0.0, 1.0);
    vec3 H_L = normalize(lightdir + camdir);
    float specularRV = clamp(dot(normal, H_L), 0.0, 1.0);
    float specularTerm = pow(specularRV, 10.0);

    return vec3(diffuseTerm, specularTerm, falloff);
}

float maxDepth(float depth, vec2 v_uv) {
    float u = v_uv.x;
    float v = v_uv.y;
    float d1 = texture2D(u_depth, vec2(u+(1./800.), v)).x;
    float d2 = texture2D(u_depth, vec2(u-(1./800.), v)).x;
    float d3 = texture2D(u_depth, vec2(u, (v+1./600.))).x;
    float d4 = texture2D(u_depth, vec2(u, (v-1./600.))).x;
    return max(
                max(
                    max(
                        abs(depth-d1), abs(depth-d2)),
                    abs(depth-d3)),
                abs(depth-d4)
            );
}

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;

    vec4 lightPosRad = texture2D(u_lightsPR, vec2(0, 0));
    vec4 lightc = texture2D(u_lightsC, vec2(0, 0));

    gl_FragColor = vec4(vec3(lightPosRad).xyz, 0);
    gl_FragColor = vec4(lightc);
    return;

    // worldspace positions
    vec3 pos = vec3(gb0);
    // unlit surface color
    vec3 color = vec3(gb2);

    // geometry normals
    vec3 geomnor = vec3(gb1);
    // normal map
    vec3 normap = vec3(gb3);
    // final normals
    vec3 normal = applyNormalMap(geomnor, normap);

    if (depth == 1.0) {
        gl_FragColor = vec4(0);
        return;
    }
    gl_FragColor = vec4(0, 0, 1, 1);

    vec3 terms = lightTerms(normal, pos);
    float diff = terms.x;
    float spec = terms.y;
    float fall = terms.z;

    if (u_toon == 1) {
        diff = float(int(diff * TOON_STEPS)) / TOON_STEPS;
        float surroundingDepth = maxDepth(depth, v_uv);
        if (surroundingDepth > .001) {
            gl_FragColor = vec4(0, 0, 0, 1);
            return;
        }
    }

    vec3 litColor = 0.4 * fall * color * u_lightCol * (diff + spec);
    gl_FragColor = vec4(litColor, 1);
}
