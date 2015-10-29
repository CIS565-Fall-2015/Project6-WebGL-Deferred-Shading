#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 3

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;
uniform vec3 u_cameraPos;
uniform float u_toon;
//uniform float u_width;
//uniform float u_height;

varying vec2 v_uv;



void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    
    float depth = texture2D(u_depth, v_uv).x;


    // TODO: Extract needed properties from the g-buffers into local variables
    vec3 pos = gb0.xyz;
    
    vec3 colmap = gb2.xyz;
    float spec = gb1.w;
   

    vec3 normal = normalize(gb1.xyz);
    vec3 lightDir = normalize((u_lightPos - pos)); // / length(u_lightPos - pos);

    if (length(u_lightPos - pos) > u_lightRad) {
        gl_FragColor = vec4(0, 0, 0, 1.0);
        return;
    }   
    float lambertian = min(max(dot(lightDir,normal), 0.0), 1.0);
    float specular = 0.0;
    
    vec3 viewDir = normalize(u_cameraPos - pos);
    vec3 halfDir = normalize(lightDir + viewDir);
    float specAngle = max(dot(halfDir, normal), 0.0);

    
    specular = pow(specAngle, spec);       
    
    
    vec3 color = lambertian * colmap * u_lightCol * (u_lightRad - length(u_lightPos - pos)) + specular*vec3(1.0);

    if (u_toon > 0.5) {
        //diffuse values
        if (lambertian < 0.5) {
            lambertian = .2;
        }
        else {
            lambertian = 1.0;
        }
        
        //specular highlight
        if (specAngle > .75) {
            specular = pow(1.0, spec);
        }
        else {
            specular = 0.0;
        }

        //fade from center of light
        float fade;
        if (u_lightRad - length(u_lightPos - pos) < .5) fade = .25;
        else fade = .75;

        //check silhouette
        
        color = lambertian * colmap * u_lightCol * fade + specular*vec3(1.0);
    }


    
    gl_FragColor =  vec4(color, 1.0);
  
}
