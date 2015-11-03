#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform sampler2D u_lightCol;
uniform sampler2D u_lightPos;
uniform sampler2D u_lightList;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

uniform int u_lightOffsetLength;
uniform float u_lightOffsetY;
uniform float u_totalLight;
uniform vec3 u_viewPos;

varying vec2 v_uv;

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    float depth = texture2D(u_depth, v_uv).x;
    
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }
    
    vec3 pos            = gb0.xyz;                     
    vec3 nor            = gb1.xyz;  
    vec3 col            = gb2.xyz;      
    float specularExp   = gb0.w;   
    float specularCoeff   = gb1.w;   
   
    gl_FragColor.a = 1.0;
    for(int i = 0; i < 2000; i++){
        if(i >= u_lightOffsetLength) return;
        
        float currLight = (float(i) + 0.5)/float(u_lightOffsetLength);
        float light_uv = texture2D(u_lightList, vec2(currLight,u_lightOffsetY)).w + 0.5;
        light_uv /= u_totalLight;
        
        //gl_FragColor.x = u_lightOffsetY;
                
        vec4 lightPos = texture2D(u_lightPos, vec2(light_uv,0.5));
        vec4 lightcol = texture2D(u_lightCol, vec2(light_uv,0.5));
        vec3 lightDir = normalize(lightPos.xyz - pos);
        
//lambert
        float lambertian = clamp(dot(lightDir, nor), 0.0, 1.0);
        
//specular
        vec3 halfVector = normalize(lightDir + normalize(u_viewPos - pos));
        float specular = pow(max(dot(nor, halfVector), 0.0), specularExp);
        
        float lightDist = distance(lightPos.xyz, pos);
        float attenuation = max(0.0, lightcol.w - lightDist);
        
        gl_FragColor.xyz += ((lambertian * col * lightcol.xyz) + 
                             (specularCoeff * specular * vec3(1.0)))
                             * attenuation;
    }
}
