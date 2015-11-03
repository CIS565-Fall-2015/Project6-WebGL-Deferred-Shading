#version 100
precision highp float;
precision highp int;

uniform sampler2D u_depth;
uniform float u_width;
uniform float u_height;
varying vec2 v_uv;

void main() {
    
    float depth = texture2D(u_depth, v_uv).x;

 
   float difference = abs(texture2D(u_depth, v_uv + vec2(1.0/u_width), 0.0).x - depth)+
    				abs(texture2D(u_depth, v_uv - vec2(1.0/u_width, 0.0)).x - depth)+
    				abs(texture2D(u_depth, v_uv + vec2(0.0, 1.0/u_height)).x - depth)+
    				abs(texture2D(u_depth, v_uv - vec2(0.0, 1.0/u_height)).x - depth)+
    				abs(texture2D(u_depth, v_uv + vec2(1.0/u_width, 1.0/u_height)).x - depth)+
    				abs(texture2D(u_depth, v_uv - vec2(1.0/u_width, 1.0/u_height)).x - depth)+
    				abs(texture2D(u_depth, v_uv + vec2(1.0/u_width, -1.0/u_height)).x - depth)+
    				abs(texture2D(u_depth, v_uv - vec2(1.0/u_width, -1.0/u_height)).x - depth);

    if(difference >= 0.01) {
    	gl_FragColor = vec4(vec3(0.0), 1.0);
    	return;
    }  

    gl_FragColor = vec4(0.0);
}
