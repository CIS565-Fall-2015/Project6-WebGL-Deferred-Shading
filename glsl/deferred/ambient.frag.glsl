
#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

void main() {
    //vec4 gb0 = texture2D(u_gbufs[0], v_uv);//posision
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);//normal
    //vec4 gb2 = texture2D(u_gbufs[2], v_uv);//colormap
    //vec4 gb3 = texture2D(u_gbufs[3], v_uv);//normalmap
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables

    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0
        return;
    }
//gb2.xyz
    gl_FragColor = vec4(gb2.xyz*0.2, 1.0);  // ambient:0.2,diffuse:0.3,specular:0.6

	}
