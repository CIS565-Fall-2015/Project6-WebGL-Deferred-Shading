#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform int u_toon;

uniform vec3 u_cameraPos;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

uniform sampler2D u_lightsPR;
uniform sampler2D u_lightsC;

uniform sampler2D u_lightIndices;
uniform sampler2D u_tileOffsets;

uniform float u_tileIdx;
uniform float u_lightStep;

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
vec3 lightTerms(vec3 normal, vec3 pos, vec3 lightPos, float lightRad) {
    float lightDist = length(pos - lightPos);
    float falloff = max(0.0, lightRad - lightDist);

    vec3 camdir   = normalize(u_cameraPos - pos);
    vec3 lightdir = normalize(lightPos  - pos);

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

    vec3 pos = vec3(gb0); // worldspace positions
    vec3 color = vec3(gb2); // unlit surface color
    vec3 geomnor = vec3(gb1); // geometry normals
    vec3 normap = vec3(gb3); // normal map
    vec3 normal = applyNormalMap(geomnor, normap); // final normals

    vec4 tileOffsetPair = texture2D(u_tileOffsets, vec2(u_tileIdx, 0));
    int lightCount = int(tileOffsetPair.x);  // number of lights to consider
    float lightOffset = tileOffsetPair.y; // index to start at

    //gl_FragColor = vec4(vec3(float(lightCount) / 10.), 1);
    //return;
    //gl_FragColor = vec4(vec3(lightOffset * u_lightStep), 1);
    //return;

    if (depth == 1.0) {
        gl_FragColor = vec4(0);
        return;
    }

    vec3 fullColor = vec3(0);
    float offsetIdx = lightOffset * u_lightStep;
    for (int i = 0; i < 10; i++) {
        float lightIdx = texture2D(u_lightIndices, vec2(offsetIdx, 0)).x;

        vec4 lightPR = texture2D(u_lightsPR, vec2(lightIdx, 0));
        vec4 lightC  = texture2D(u_lightsC,  vec2(lightIdx, 0));

        vec3 lightCol = vec3(lightC);
        vec3 lightPos = lightPR.xyz;
        float lightRad = lightPR.w;

        vec3 terms = lightTerms(normal, pos, lightPos, lightRad);
        float diff = terms.x;
        float spec = terms.y;
        float atten = terms.z;
        vec3 lightColor = 0.4 * atten * color * lightCol * (diff + spec);

        fullColor += lightColor;
        offsetIdx += u_lightStep;

        if (i > lightCount) {
            break;
        }
    }

    //if (u_toon == 1) {
    //    diff = float(int(diff * TOON_STEPS)) / TOON_STEPS;
    //    float surroundingDepth = maxDepth(depth, v_uv);
    //    if (surroundingDepth > .001) {
    //        gl_FragColor = vec4(0, 0, 0, 1);
    //        return;
    //    }
    //}

    //vec3 fullColor = 0.4 * fall * color * u_lightCol * (diff + spec);
    gl_FragColor = vec4(fullColor, 1);
}
