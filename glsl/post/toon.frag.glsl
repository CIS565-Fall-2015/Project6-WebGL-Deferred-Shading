#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform float u_bloom;
varying vec2 v_uv;

uniform vec2 u_resolution;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
	vec4 color = texture2D(u_color, v_uv);

    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }


    vec4 neighbor1 = texture2D(u_color, vec2(v_uv.x, v_uv.y - 1.0 / u_resolution.y));
    vec4 neighbor2 = texture2D(u_color, vec2(v_uv.x - 1.0 / u_resolution.x, v_uv.y - 1.0 / u_resolution.y));
    vec4 neighbor3 = texture2D(u_color, vec2(v_uv.x + 1.0 / u_resolution.x, v_uv.y - 1.0 / u_resolution.y));
    vec4 neighbor4 = texture2D(u_color, vec2(v_uv.x, v_uv.y + 1.0 / u_resolution.y));
    vec4 neighbor5 = texture2D(u_color, vec2(v_uv.x - 1.0 / u_resolution.x, v_uv.y + 1.0 / u_resolution.y));
    vec4 neighbor6 = texture2D(u_color, vec2(v_uv.x + 1.0 / u_resolution.x, v_uv.y + 1.0 / u_resolution.y));

    // Blend and perform edge ramping
    vec4 neighbors1 = (neighbor1 + neighbor2 + neighbor3) - (neighbor4 + neighbor5 + neighbor6);
    neighbors1 = vec4(vec3(max(max(neighbors1.x, neighbors1.y), neighbors1.z)), 1.0);
    vec4 neighbors2 = -(neighbor1 + neighbor2 + neighbor3) + (neighbor4 + neighbor5 + neighbor6);
    neighbors2 = vec4(vec3(max(max(neighbors2.x, neighbors2.y), neighbors2.z)), 1.0);
    vec4 outline;
    if(neighbors1.x > 0.2 || neighbors2.x > .2) {
        outline = vec4(0.0);
    }
    else {
        outline = vec4(vec3(1.0), 0.0);
    }

    gl_FragColor = (outline) * color;
}