#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform sampler2D u_pos;
//uniform sampler2D u_depthTex;

uniform mat4 u_cameraMat;
uniform mat4 u_prevMat;


uniform vec3 u_crntEye;
uniform vec3 u_prevEye;
	
uniform vec2 u_texSize;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {
	
	vec2 oneP = vec2(1.0,1.0)/u_texSize;

	vec4 origCol = texture2D(u_color, v_uv);

	vec4 testM = vec4(0.5,0.5,0.5,1.0);
	if(u_crntEye==u_prevEye) testM.r = 0.7;
	//if(u_cameraMat==u_prevMat) testM.r = 0.7;
	else testM.g = 0.7;
	
	vec3 vel = u_prevEye-u_crntEye;
	vec3 pos = texture2D(u_pos, v_uv).xyz;
	vec3 newPos = pos+vel;
	
	vec2 sc_pos = (vec4(pos,1.0)*u_prevMat).xy;
	vec2 sc_newPos = (vec4(newPos,1.0)*u_cameraMat).xy;
	
	vec2 uv_vel = (sc_newPos-sc_pos).xy*0.5;
	
	origCol = vec4(0.0,0.0,0.0,0.0);//origCol*(1.0/11.0);
	//v_uv += vel.xy*oneP;  
	
	for(int i = 0; i < 10; ++i)  
	{   
	   vec4 tempCol = texture2D(u_color, v_uv + float(i)*oneP*uv_vel);    
	   origCol += tempCol/10.0;  
	} 

	
	gl_FragColor = origCol;//*testM;
	
	//gl_FragColor = texture2D(u_color, v_uv);
}
