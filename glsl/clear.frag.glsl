#version 100
#extension GL_EXT_draw_buffers: enable
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

void main() {
    for (int i = 0; i < NUM_GBUFFERS; i++) {
        gl_FragData[i] = vec4(0.0);
    }
}
