#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform vec3 u_camPos;

uniform float u_mode;

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;
	
    vec3 pos = gb0.xyz;
    vec3 geomnor = normalize(gb1.xyz);
    vec3 colmap = gb2.xyz;
    vec3 normap = gb3.xyz;
    vec3 nor = applyNormalMap(geomnor, normap);
	
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }
	
	vec3 lightVector = u_lightPos - pos;
	float attenuation = max (0.0, u_lightRad- length(lightVector));
	//float attenuation = clamp (0.0, u_lightRad - length(lightVector));
	
	lightVector = normalize(lightVector);
	vec3 lightReflectVector = reflect(-lightVector, nor);
	vec3 camVector = normalize(u_camPos - pos);
	
	if(u_mode == 1.0 && (dot(nor, camVector) < 0.1 && dot(nor, camVector) > -0.1))
	{
		//Make silhouettes pop
		gl_FragColor = vec4(vec3(0.0), 1.0);
			return;
	}

	vec3 H = normalize(lightVector + camVector);
		
	//Assuming Kspec = 0.01 and shininess = 0.01
	float spec = 0.001 * pow(clamp(dot(nor, H), 0.0, 1.0), 0.01);
	float diff =  max(0.0,dot(nor, lightVector));
	
	if(u_mode == 1.0)
	{
		//toon shading
		
		if(diff > 0.6)
			diff = 1.0;
		else if(diff > 0.58)
		{
			gl_FragColor = vec4(vec3(0.0), 1.0);
			return;
		}
		else if(diff > 0.2)
			diff = 0.2;
		else if(diff > 0.18)
		{
			gl_FragColor = vec4(vec3(0.0), 1.0);
			return;
		}
		else diff = 0.0;
	}

    gl_FragColor = vec4(attenuation * colmap * u_lightCol * (diff + spec), 1.0);
}
