#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

const float shininess = 20.0;
const vec3 specular_col = vec3 (1.0,1.0,1.0);


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


	vec3 pos = vec3(gb0);
    vec3 geomnor = vec3(gb1);
    vec3 colmap = vec3(gb2);
    vec3 normap = vec3(gb3);
    vec3 nor = applyNormalMap(geomnor, normap);


    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }

    float attenuation = max(0.0, u_lightRad - distance(u_lightPos ,pos))/u_lightRad;
	
	if(attenuation == 0.0)
	{
		//gl_FragColor = vec4(0, 0, 0, 1);
        return;
	}



	
	
	vec3 lightDir = normalize(u_lightPos - pos);




	vec3 diffuse_col = vec3( colmap[0] * u_lightCol[0],colmap[1] * u_lightCol[1],colmap[2] * u_lightCol[2]);
	
	//vec3 diffuse_col = vec3(colmap[0],0.0,0.0);
	

	 float lambertian = max(dot(lightDir,nor), 0.0);
	 float specular = 0.0;

	 if(lambertian > 0.0) 
	 {

			vec3 viewDir = normalize(-pos);

			// this is blinn phong
			vec3 halfDir = normalize(lightDir + viewDir);
			float specAngle = max(dot(halfDir, nor), 0.0);
			specular = pow(specAngle, shininess);
       
	}


	
	
	 vec3 final_col = attenuation*lambertian*diffuse_col + attenuation*specular*specular_col ;  // TODO: perform lighting calculations
	
	// vec3 final_col = lambertian*diffuse_col + specular*specular_col;

	// gl_FragColor  = vec4(0.5,0.5,0.5,1.0);
	 gl_FragColor = vec4(final_col,1.0);
}
