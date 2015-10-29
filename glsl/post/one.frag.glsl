#version 100
#define COFF 0.8
#define N 32.0
precision highp float;
precision highp int;

uniform mat4 u_previousMat;
uniform mat4 u_currentMat;
uniform int u_mode;
uniform sampler2D u_color;
uniform sampler2D u_depth;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

vec4 getBlur(vec2 v_uv,sampler2D u_gbuf){//old method
	vec4 result=texture2D(u_gbuf,v_uv);
	vec4 v00,v01,v02,v10,v11,v12,v20,v21,v22;
	v00=texture2D(u_gbuf,vec2(v_uv.x-0.001,v_uv.y+0.001))*1.2;
	v01=texture2D(u_gbuf,vec2(v_uv.x,v_uv.y+0.001))*1.2;
	v02=texture2D(u_gbuf,vec2(v_uv.x+0.001,v_uv.y+0.001))*1.2;
	v10=texture2D(u_gbuf,vec2(v_uv.x-0.001,v_uv.y))*1.2;
	v11=result;
	v12=texture2D(u_gbuf,vec2(v_uv.x+0.001,v_uv.y))*1.2;
	v20=texture2D(u_gbuf,vec2(v_uv.x-0.001,v_uv.y-0.001))*1.2;
	v21=texture2D(u_gbuf,vec2(v_uv.x,v_uv.y-0.001))*1.2;
	v22=texture2D(u_gbuf,vec2(v_uv.x+0.001,v_uv.y-0.001))*1.2;
	if(length(v00.xyz)<0.5) v00=result;
	if(length(v01.xyz)<0.5) v01=result;
	if(length(v02.xyz)<0.5) v02=result;
	if(length(v10.xyz)<0.5) v10=result;
	if(length(v12.xyz)<0.5) v12=result;
	if(length(v20.xyz)<0.5) v20=result;
	if(length(v21.xyz)<0.5) v21=result;
	if(length(v22.xyz)<0.5) v22=result;
	result=1.0/16.0*(v00+v02+v20+v22)+2.0/16.0*(v01+v10+v12+v21)+4.0/16.0*v11;
	return result;
}

vec4 accumulateX(vec2 v_uv,sampler2D u_gbuf){
	vec4 result=texture2D(u_gbuf,v_uv);
	for(float i=1.0;i<=N;++i){ 
		vec4 v=pow(COFF,i)*texture2D(u_gbuf,vec2(v_uv.x+0.005*i,v_uv.y));
		if(length(v.xyz)>0.8)
			result+=v;
		else result+=pow(COFF,i)*texture2D(u_gbuf,v_uv);
	}
	for(float i=1.0;i<=N;++i){ 
		vec4 v=pow(COFF,i)*texture2D(u_gbuf,vec2(v_uv.x-0.005*i,v_uv.y));
		if(length(v.xyz)>0.8)
			result+=v;
		else result+=pow(COFF,i)*texture2D(u_gbuf,v_uv);
	}
	return result;
}

void main() {
	float depth = texture2D(u_depth, v_uv).x;
	vec4 H = vec4(v_uv.x*2.0-1.0,(1.0-v_uv.y)*2.0-1.0,depth,1.0); 
	vec4 D = u_currentMat*H;
	vec4 worldPos=D/D.w;
	vec4 currentPos=H;
	vec4 previousPos=u_previousMat*worldPos;
	previousPos=previousPos/previousPos.w;
	vec2 v=(currentPos.xy - previousPos.xy)/2.0;  

	vec4 color1,color2,color;
    if(u_mode==0) color1 = texture2D(u_color, v_uv);
	else color1 = accumulateX(v_uv,u_color);
	
	v=0.05*v+1.0*v_uv;
	if(u_mode==0) color2 = texture2D(u_color, v);
	else color2 = accumulateX(v,u_color);

	color=color1+color2;
	color/=2.0;
    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }

    gl_FragColor = color;
}
