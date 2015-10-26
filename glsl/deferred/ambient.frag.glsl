
#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv); //pos
    vec4 gb1 = texture2D(u_gbufs[1], v_uv); //geomnor
    vec4 gb2 = texture2D(u_gbufs[2], v_uv); //colormap
    vec4 gb3 = texture2D(u_gbufs[3], v_uv); //normap
    float depth = texture2D(u_depth, v_uv).x; //depth
    // TODO: Extract needed properties from the g-buffers into local variables




    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0 used for post processing
        return;
    }

    gl_FragColor = vec4(0.8*(1.0-depth)*vec3(gb2),1.0);//vec4(0.1, 0.1, 0.1, 1);  // TODO: replace this
}
