#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform vec3 u_cameraPos;
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

    vec3 std_normal=applyNormalMap(gb1.xyz, gb3.xyz);
	
	vec3 I = normalize(u_lightPos-gb0.xyz);
	vec3 outray =normalize(u_cameraPos-gb0.xyz);
    vec3 H=normalize(I+outray);

    float hdot=dot(H,std_normal);
    vec3 specular_color = max(pow(hdot,u_lightRad),0.0)* u_lightCol;
	float diffuse= dot(std_normal, I);//0-1;
	vec3 diffuse_color=vec3(diffuse);

    vec3 phong_color= 0.6*specular_color+0.4*diffuse_color;//where is ambient light?
    phong_color = phong_color;//* u_lightCol;//clamp(0,1.0);
 
	

//	vec3 phong_color=vec3(1.0,0.0,0.0);
    gl_FragColor = vec4(phong_color.xyz, 1);  // TODO: perform lighting calculations
   
	}
