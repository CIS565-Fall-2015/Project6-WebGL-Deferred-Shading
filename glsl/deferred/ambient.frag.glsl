
#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

void main() {
    
    vec4 gb0 = texture2D(u_gbufs[0], v_uv); 
    float depth = texture2D(u_depth, v_uv).x;

    vec3 colmap = gb0.xyz;  // The color map - unlit "albedo" (surface color)
   

    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0
        return;
    }

    gl_FragColor = vec4(0.3 * colmap, 1);  
}
