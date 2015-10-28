
#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 3

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

void main() {
    
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);//colormap 
    float depth = texture2D(u_depth, v_uv).x;
  

    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0
        return;
    }
    gl_FragColor = vec4(gb2.xyz*0.2, 1.0);  // ambient:0.2,diffuse:0.3,specular:0.6

	}
