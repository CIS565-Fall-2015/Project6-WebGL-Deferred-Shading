#version 100
precision highp float;
precision highp int;

#define NUM_SAMPLES 5

uniform sampler2D u_color;
uniform sampler2D u_depth;

uniform mat4 u_previousVProj;
uniform mat4 u_inverseVProj;

varying vec2 v_uv;

//from http://http.developer.nvidia.com/GPUGems3/gpugems3_ch27.html

void main() {
    //get position of each pixel
    float zOverW = texture2D(u_depth, v_uv).x; 
    vec4 viewportPos = vec4(v_uv.x * 2.0 - 1.0, v_uv.y * 2.0 - 1.0,  zOverW, 1.0); 
    
    vec4 prevViewportPos = u_inverseVProj * viewportPos;   //get world pos
    prevViewportPos = u_previousVProj * prevViewportPos;   //convert back to viewport
    prevViewportPos = prevViewportPos / prevViewportPos.w;
    
    //now you have pixel speed
    vec2 velocity = (viewportPos.xy - prevViewportPos.xy) / (float(NUM_SAMPLES) * 3.0);
    
    //now we do the blur!
    vec4 color = texture2D(u_color, v_uv);
    vec2 texCoord = v_uv;
    for(int i = 0; i < NUM_SAMPLES; i++){
        texCoord += velocity;
        color += texture2D(u_color, texCoord);
    }
    gl_FragColor = color / float(NUM_SAMPLES + 1);
}
