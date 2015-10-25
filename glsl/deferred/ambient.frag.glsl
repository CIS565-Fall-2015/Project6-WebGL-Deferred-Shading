
#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 2

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

const vec4 SKY_COLOR = vec4(0.1, 0.14, 0.22, 0.1)*2.0;

varying vec2 v_uv;

// http://aras-p.info/blog/2009/07/30/encoding-floats-to-rgba-the-final/
// http://stackoverflow.com/questions/30242013/glsl-compressing-packing-multiple-0-1-colours-var4-into-a-single-var4-variab
vec4 unpackRGBA( float v ) {
    float a = floor(v*255.0/64.0)*64.0/255.0;
    v -= a;
    float b = floor(v*255.0/16.0)*16.0/255.0;
    v -= b;
    b *= 4.0;
    float c = floor(v*255.0/4.0)*4.0/255.0;
    v -= c;
    c *= 16.0;
    float d = v*255.0 * 64.0 / 255.0;
    return vec4(a,b,c,d)/0.75;
}


void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    //vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    //vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;

    vec3 colmap = unpackRGBA(gb0.w).xyz;  // The color map - unlit "albedo" (surface color)

    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0
        return;
    }

    gl_FragColor = SKY_COLOR*vec4(colmap, 1.0);
}
