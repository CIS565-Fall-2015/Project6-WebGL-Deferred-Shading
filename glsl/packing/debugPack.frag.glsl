#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 2

uniform int u_debug;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;
uniform mat4 u_invCameraMat;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.66, 0.73, 1.0, 1.0);

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv); // texture mapped color
    vec4 gb1 = texture2D(u_gbufs[1], v_uv); // screen space position + compressed "final" normal
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables
    // These definitions are suggested for starting out, but you will probably want to change them.
    vec4 screenPos = vec4(gb1.xy, depth, 1.0);     // screen space position

    // reconstruct screen space position
    // https://mynameismjp.wordpress.com/2009/03/10/reconstructing-position-from-depth/
    screenPos.x = screenPos.x * 2.0 - 1.0;
    screenPos.y = (1.0 - screenPos.y) * 2.0 - 1.0;

    vec4 worldPos = u_invCameraMat * screenPos;

    vec3 pos = worldPos.xyz / worldPos.w;
    // reconstruct normal
    vec3 norm;
    norm.xy = gb1.zw;
    if (norm.x != 0.0 || norm.y != 0.0) {
        norm.z = 1.0;
        if (abs(norm.x) >= 1.0) {
            norm.z = -1.0;
            norm.x -= norm.x / abs(norm.x);
        }
        norm.z *= sqrt(1.0 - norm.x * norm.x - norm.y * norm.y);
    }

    if (u_debug == 0) {
        gl_FragColor = vec4(vec3(depth), 1.0);
    } else if (u_debug == 1) {
        gl_FragColor = vec4(abs(pos) * 0.1, 1.0);
    } else if (u_debug == 2) {
        gl_FragColor = vec4(abs(norm), 1.0);
    } else if (u_debug == 3) {
        gl_FragColor = vec4(gb0.rgb, 1.0);
    } else if (u_debug == 4) {
        gl_FragColor = vec4(norm, 1.0);
    } else if (u_debug == 5) {
        gl_FragColor = vec4(abs(norm), 1.0);
    } else {
        gl_FragColor = vec4(1, 0, 1, 1);
    }
}
