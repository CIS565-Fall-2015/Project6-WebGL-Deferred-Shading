
#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform int u_enableToon;
uniform vec3 u_camPos;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

float contourStep(float angle){
	if(angle<0.0) return 0.0;
	angle/=0.1;
	//if(angle<1.0) return 0.0;
	if(angle<2.0) return 0.0;
	//if(angle<3.0) return 0.2;
	if(angle<4.0) return 0.25;
	//if(angle<5.0) return 0.4;
	if(angle<6.0) return 0.5;
	//if(angle<7.0) return 0.6;
	if(angle<8.0) return 0.75;
	//if(angle<9.0) return 0.8;
	return 1.0;
}

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

	if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0
        return;
    }

    if(u_enableToon==1){
		vec3 geomnor=gb1.xyz;  // Normals of the geometry as defined, without normal mapping
		vec3 colmap=gb2.xyz;  // The color map - unlit "albedo" (surface color)
	    vec3 normap=gb3.xyz;
		vec3 nor=applyNormalMap(geomnor,normap);
		vec3 cameraDir=normalize(u_camPos-gb0.xyz);
		float angle=dot(nor,cameraDir);
		angle=contourStep(angle);
		gl_FragColor=vec4(angle,angle,angle,1);
	}
	else{
		vec3 colmap=gb2.xyz;
		gl_FragColor = 0.2*gb2;
	}
}
