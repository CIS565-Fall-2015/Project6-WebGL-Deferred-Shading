#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;
uniform int u_toon;
uniform vec3 u_cameraPos;

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
	
	// If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }
	
    // TODO: Extract needed properties from the g-buffers into local variables

    vec3 pos = gb0.xyz;     // World-space position
    vec3 geomnor = gb1.xyz;   // Normals of the geometry as defined, without normal mapping
    vec3 colmap = gb2.xyz;  // The color map - unlit "albedo" (surface color)
    vec3 normap = gb3.xyz;  // The raw normal map (normals relative to the surface they're on)
    vec3 nor = applyNormalMap(geomnor, normap);

    vec3 temp = u_lightPos - pos;
    float dist = length(temp);
    vec3 light = normalize(temp);
    vec3 cam = normalize(u_cameraPos - pos);
    
    float att = clamp(1.0 - dist/u_lightRad, 0.0, 1.0);
    
    float diff = max(dot(light, nor), 0.0);   
    float spec = max(dot(-light + 2.0 * dot(light,nor) * nor, cam), 0.0);
	spec = pow(spec, 50.0);
	
	if(u_toon == 1){
		diff = float(floor(diff/0.2)) * 0.2;
		spec = float(floor(spec/0.2)) * 0.2;
	}

    gl_FragColor = vec4( clamp((diff+spec)*att*colmap*u_lightCol, 0.0, 1.0), 1.0);

    //gl_FragColor = vec4(0, 0, 1, 1);  // TODO: perform lighting calculations
}
