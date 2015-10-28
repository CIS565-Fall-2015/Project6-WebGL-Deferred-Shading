
#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

void main() {
    // pos
    vec4 gb0 = texture2D(u_gbufs[0], v_uv); 
    // col
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    // surface normal
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    float depth = texture2D(u_depth, v_uv).x;

    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0
        return;
    }

    gl_FragColor = vec4(0.2 * gb1.xyz, 1);  
}
