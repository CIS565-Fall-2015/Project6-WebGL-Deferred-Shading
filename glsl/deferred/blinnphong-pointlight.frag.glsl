#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform bool u_toon;
uniform vec3 u_camPos;
uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
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
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);	//pos
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);	//nor
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);	//colmap
    vec4 gb3 = texture2D(u_gbufs[3], v_uv);	//normap
    float depth = texture2D(u_depth, v_uv).x;
    // TO_DO: Extract needed properties from the g-buffers into local variables
    vec3 pos = gb0.xyz;
    vec3 geomnor = gb1.xyz;
    vec3 diff = gb2.xyz;
    vec3 normap = gb3.xyz;
    vec3 nor = applyNormalMap(geomnor,normap); 
	
	vec3 lightDir = normalize(u_lightPos - pos);
	vec3 reflDir = reflect(-lightDir,nor);
	vec3 viewDir = normalize(u_camPos - pos);
	
    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }
	//http://www.mathematik.uni-marburg.de/~thormae/lectures/graphics1/code/WebGLShaderLightMat/ShaderLightMat.html
    // TO_DO: perform lighting calculations
	
	float attenuation = max(0.0, u_lightRad - length(pos-u_lightPos));
	attenuation*=attenuation;
	float lamb = max(dot(lightDir,nor),0.0);
	float spec = 0.0;
	if(lamb>0.0)
	{
		float specAngle = max(dot(reflDir,viewDir),0.0);
		spec = pow(specAngle,4.0);
	}
	if(u_toon)//toon
	{
		//lamb = lamb>0.5?1.0:0.0;
		if(lamb<0.1) lamb = 0.0;
		else if(lamb<0.6) lamb = 0.6;
		else lamb = 1.0;
		spec = spec>0.5?1.0:0.0;
	}
	gl_FragColor = vec4(attenuation*(lamb+spec)*diff*u_lightCol, 1.0);
}
