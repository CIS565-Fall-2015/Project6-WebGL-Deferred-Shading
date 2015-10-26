#version 100
precision highp float;
precision highp int;

uniform float u_width;
uniform float u_height;
uniform int u_axis;
uniform sampler2D u_color;
varying vec2 v_uv;

int samples = 21;


void main() {
    
    vec4 color = texture2D(u_color, v_uv).rgba;
    
    if(color.a == 0.0)
    {
        gl_FragColor = color;
        return;
    }  

   int diff = 10;//(samples-1)/2;
   vec2 sizeFactor = vec2(1.0/u_width, 1.0/u_height);

   vec3 bloom = vec3(0.0);

   for(int i= -10; i<= 10; i++){
        for(int j= -10; j<= 10; j++){
            vec2 offset = vec2(i,j) * sizeFactor;
            bloom += 0.01*texture2D(u_color, v_uv + offset).rgb;
        }
   }
    
    gl_FragColor = vec4( color.rgb +(bloom), 1.0);
    
    //gl_FragColor = vec4(1.0);
    
   
}