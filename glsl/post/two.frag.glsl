#version 100
#define N 5.0
#define COFF 0.8
precision highp float;
precision highp int;

uniform mat4 u_previousMat;
uniform mat4 u_currentMat;
uniform int u_mode;
uniform sampler2D u_color;
uniform sampler2D u_depth;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

vec4 accumulateY(vec2 v_uv,sampler2D u_gbuf){
	vec4 result=texture2D(u_gbuf,v_uv);
	for(float i=1.0;i<=N;++i){ 
		vec4 v=pow(COFF,i)*texture2D(u_gbuf,vec2(v_uv.x,v_uv.y+0.005*i));
		if(length(v.xyz)>0.8)
			result+=v;
		else result+=pow(COFF,i)*texture2D(u_gbuf,v_uv);
	}
	for(float i=1.0;i<=N;++i){ 
		vec4 v=pow(COFF,i)*texture2D(u_gbuf,vec2(v_uv.x,v_uv.y-0.005*i));
		if(length(v.xyz)>0.8)
			result+=v;
		else result+=pow(COFF,i)*texture2D(u_gbuf,v_uv);
	}
	return result;
}

float getNum(){
	float result=1.0+2.0*(1.0-pow(COFF,N));
	result=result+2.0*result*(1.0-pow(COFF,N));
	return result;
}

void main() {
	vec4 color;
	color=accumulateY(v_uv,u_color);
	color/=getNum();

    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }

    gl_FragColor = 1.0*color;
}
