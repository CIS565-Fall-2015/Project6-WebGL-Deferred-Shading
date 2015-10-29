#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform int u_debugScissor;
uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform vec3 u_camPos;
uniform float u_specCoff;
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
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables

    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }

	vec3 geomnor=gb1.xyz;  // Normals of the geometry as defined, without normal mapping
    vec3 colmap=gb2.xyz;  // The color map - unlit "albedo" (surface color)
    vec3 normap=gb3.xyz;
	vec3 nor=applyNormalMap(geomnor,normap);
	vec3 cameraDir=normalize(u_camPos-gb0.xyz);
	vec3 lightDir=normalize(gb0.xyz-u_lightPos);
	vec3 ref=normalize(lightDir-2.0*nor*dot(lightDir,nor));
	
	vec3 diff=u_lightCol*dot(nor,cameraDir);
    vec3 spec=u_lightCol*pow(max(0.0,dot(ref,cameraDir)),u_specCoff);

	vec3 color=0.5*diff+0.5*spec;

	float len=length(u_lightPos-gb0.xyz);
	if(u_debugScissor==1&&len<2.0*u_lightRad){
		gl_FragColor=vec4(color+vec3(0.2,0,0),1);
	}
	else if(len<u_lightRad){
		gl_FragColor=vec4(color,1)*(u_lightRad-len)/u_lightRad;
	}
	else gl_FragColor=vec4(0,0,0,1);
}
