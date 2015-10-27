#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);
int samples = 25;

void main() {
    
    vec4 color = texture2D(u_color, v_uv);
    
    if(color.a == 0.0)
    {
        gl_FragColor = SKY_COLOR;
        return;
    }  

   int diff = 2;//(samples-1)/2;
   vec2 sizeFactor = vec2(1.0/800.0, 1.0/600.0);

   vec4 bloom = vec4(0.0);

   for(int i= -2; i<= 2; i++){
        for(int j= -2; j<= 2; j++){
            vec2 offset = vec2(i,j) * sizeFactor;
            bloom += 0.04*texture2D(u_color, v_uv + offset);
        }
   }
    
    gl_FragColor = clamp((bloom + color), 0.0, 1.0);
    
    //gl_FragColor = vec4(1.0);
    
   
}