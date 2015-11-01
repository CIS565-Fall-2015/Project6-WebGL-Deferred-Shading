#version 100
precision highp float;
precision highp int;

#define OUTLINE_DEPTH 0.05

uniform sampler2D u_color;
uniform sampler2D u_depth;

uniform int u_width;
uniform int u_height;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

vec3 SobelOperator(mat3 kernel){
    vec3 clr = vec3(0.0);
    vec4 ctmp = vec4(0.0);
    
    float xPixel = 2.0/float(u_width);
    float yPixel = 2.0/float(u_height);
    
    for(int i = 0; i < 3; i++){
        for(int j = 0; j < 3; j++){
            ctmp = texture2D(u_depth, 
                vec2(v_uv.x + float(i-1) * xPixel, v_uv.y + float(j-1) * yPixel));
            clr += kernel[i][j] * ctmp.xyz;
        }
    }
    
    return clr;
}

void main() {
    vec4 color = texture2D(u_color, v_uv);
    float depth = texture2D(u_depth, v_uv).x;

    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }
    
    //edge detection
    mat3 Gx = mat3(
		-1.0,  0.0,  1.0,
		-2.0,  0.0,  2.0,
		-1.0,  0.0,  1.0);
	mat3 Gy = mat3(
		-1.0, -2.0, -1.0,
		 0.0,  0.0,  0.0,
		 1.0,  2.0,  1.0);
    if(distance(SobelOperator(Gx), SobelOperator(Gy)) > OUTLINE_DEPTH){
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    
    //ramp shading
    float step1 = 0.3;
    float step2 = 0.6;
    float step3 = 0.9;
    
    for(int i = 0; i < 3; i++){
        if(color[i] < step1) color[i] = 0.1;
        else if(color[i] < step2) color[i] = step1;
        else if(color[i] < step3) color[i] = step2;
        else color[i] = step3;
        
    }
    
    gl_FragColor = color;
}
