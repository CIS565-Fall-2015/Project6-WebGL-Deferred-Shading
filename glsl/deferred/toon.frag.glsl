#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform sampler2D u_depth;
uniform sampler2D u_color;
varying vec2 v_uv;

const vec3 offset = vec3( 0.0, 2.0, 4.0);
const float width=800.0;
const float height=600.0;

void main() {

    float depth = texture2D(u_depth, v_uv).x;
	vec4 color=texture2D(u_color, vec2(v_uv));
   //https://www.shadertoy.com/view/4slSWf
    float Fc= texture2D( u_depth,  vec2(v_uv)+ vec2(0.0,offset.x) /height ).x; 
	float Fc1 = texture2D( u_depth,  vec2(v_uv)+ vec2(0.0,offset.z) /height ).x;
	float Fc2 = texture2D( u_depth,  vec2(v_uv)+ vec2(offset.z,0.0) /width ).x;
	 
	float e=max(abs(Fc-Fc1),abs(Fc-Fc2));
	
	
	if(e>0.05)gl_FragColor=vec4(0.1,0.1,0.1,1.0);//draw outline
	else gl_FragColor = vec4(0.1,0.1,0.1,0.3);
	//gl_FragColor=vec4(0.0,0.0,0.0,1.0);
}