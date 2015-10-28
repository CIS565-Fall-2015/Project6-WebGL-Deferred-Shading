#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 3

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform vec3 u_cameraPos;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;
uniform int u_toon;
//uniform int u_bloom;

varying vec2 v_uv;
const vec3 offset = vec3( 0.0, 2.0, 4.0);
const float width=800.0;
const float height=600.0;

const vec3 offset_g = vec3( 0.0, 1.0, 2.0);//35,21,7,1 :sum:126
const vec3 weight= vec3(0.48, 0.31, 0.17); //guess weight: 0.2778, 0.1667, 0.0556: to make it brighter it should be bigger than 1

float _clampf(float t)
{
if(t>1.0)t=1.0;
if(t<0.0)t=0.0;
return t;
}

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
  
    float depth = texture2D(u_depth, v_uv).x;
  
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }

    //vec3 std_normal=applyNormalMap(gb1.xyz, gb3.xyz);
	vec3 std_normal=gb1.xyz;
    
	vec3 position=gb0.xyz;
	//vec3 position=vec3(gb0.xy,depth);
	vec3 lightray = normalize(u_lightPos-position);

	vec3 basec=gb2.xyz;
	float dis=length(u_lightPos-position);
	vec3 eyeray =normalize(u_cameraPos-position);
    vec3 H=normalize(lightray+ eyeray);
    float attenuation = max(0.0, u_lightRad - dis);
	vec3 light;
	float diffuse= _clampf(dot(lightray,std_normal));
	float specular= _clampf(pow(max(0.0, dot(lightray,H)), gb0.w));
	//https://en.wikibooks.org/wiki/GLSL_Programming/Unity/Toon_Shading
    if(u_toon>0)
	{//ramp
	float a=0.2;
	float b=0.5;
	float c=0.9;
	float d=1.0;
	
	if(diffuse<a){diffuse=0.0;specular=0.0;}
	else if(diffuse<b) {diffuse=a;specular=a;}
	else if(diffuse<c) {diffuse=b;specular=d;}
	else {diffuse=d;specular=d;}
    basec=vec3(1.0,1.0,1.0);
	}
	vec3 color;
    vec3 phong_color= (diffuse+specular)*u_lightCol*attenuation*basec;
  
	gl_FragColor = vec4(phong_color,1.0);
	//if(gb2.x>0.5)gl_FragColor=vec4(1.0,0.0,0.0,1.0);
	//else gl_FragColor=vec4(0.0,1.0,0.0,1.0);
}