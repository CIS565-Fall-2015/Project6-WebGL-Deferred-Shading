
#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

const int lineCheckRadius = 5;
const float lineCheckStep = 0.001;
const float lineCheckDepthRange = 0.01;
const float lineCheckAngleRange = 0.5;

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;
    vec3 norm = gb2.xyz;     // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)

    vec3 colmap = gb0.xyz;  // The color map - unlit "albedo" (surface color)

    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0
        return;
    }

    vec3 color = vec3(colmap / 5.0);

    // use convolution to add outline based on depth change edge detect
    vec2 sampleUV = v_uv - vec2(lineCheckStep * (5.0 / 2.0));
    float numPixelSamples = 1.0;
    for (int x = 0; x < lineCheckRadius; x++) {
        for (int y = 0; y < lineCheckRadius; y++) {

            float sampleDepth = texture2D(u_depth, sampleUV).x;

            // if sampleDepth is sufficiently different from this fragment's depth,
            // darken this pixel as an edge
            if (abs(sampleDepth - depth) > lineCheckDepthRange) {
                color = vec3(0.0, 0.0, 0.0);
            }

            vec3 sampleNorm = texture2D(u_gbufs[2], sampleUV).xyz;
            if (dot(sampleNorm, norm) < lineCheckAngleRange) {
                color = vec3(0.0, 0.0, 0.0);
            }

        }
        sampleUV.y = v_uv.y - lineCheckStep * 5.0 / 2.0;
        sampleUV.x += lineCheckStep;        
    }

    gl_FragColor = vec4(color, 1); 
}
