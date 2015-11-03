#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

uniform int u_width;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

#define BLOOM_DISTANCE 5

//from https://www.shadertoy.com/view/XdfGDH
float gaussian(in float x, in float sigma){
	return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

void main() {
    vec4 color = texture2D(u_color, v_uv);

    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }
    
    float increment = 1.0/float(u_width);
    //scan x pixels leftward and rightward, check if the color is > 1
    float sigma = 7.0;
    for(int i = -BLOOM_DISTANCE; i < BLOOM_DISTANCE; i++){
        vec2 newPx = v_uv + vec2(float(i) * increment, 0);
        if(newPx.x >= 0.0 && newPx.x <= 1.0){
            vec3 clr = texture2D(u_color, newPx).rgb;
            if(clr.x >= 1.0 || clr.y >= 1.0 || clr.z >= 1.0)
                color.rgb += gaussian(abs(float(i)), sigma) * clr;
        }
    }

    gl_FragColor = color;
}
