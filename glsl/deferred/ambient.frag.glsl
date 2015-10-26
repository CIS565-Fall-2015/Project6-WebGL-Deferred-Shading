
#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;
uniform float u_ambientTerm;

varying vec2 v_uv;

void main() {
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    float depth = texture2D(u_depth, v_uv).x;

    vec3 colmap = vec3(gb2);

    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0
        return;
    }

    gl_FragColor = vec4(u_ambientTerm * colmap, 1);
}
