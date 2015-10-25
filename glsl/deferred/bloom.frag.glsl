#version 100
precision highp float;
precision highp int;

#define BLOOM_THRESHOLD 0.9

#define GAUSSIAN_R 3

uniform float u_width;
uniform float u_height;

uniform int u_axis;

uniform sampler2D u_color;

varying vec2 v_uv;




//float weight[3] = float[3]( 0.33333333, 0.33333333, 0.33333333 );

void main() {
    
    vec2 offset = vec2( u_axis==0 ? 1.0/u_width : 0.0 
                        , u_axis==1 ? 1.0/u_height : 0.0);
    vec3 color = texture2D(u_color, v_uv).rgb;
    vec3 bloom = vec3(0.0);
    
    for(int i = -1 ; i <= 1; i++)
    {
        
        vec3 cur_color = texture2D(u_color, v_uv + float(i) * offset ).rgb;
        
        //bloom += weight[i+1] * ( cur_color - vec3(BLOOM_THRESHOLD) );
        bloom += 0.333333 * ( max(cur_color - vec3(BLOOM_THRESHOLD),0.0) );
    }
    
    
    
    
    gl_FragColor = vec4(bloom,1.0);
    
    gl_FragColor = vec4(1.0);
    
   
}
