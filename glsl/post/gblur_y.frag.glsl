#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

uniform int u_height;

varying vec2 v_uv;

#define BLOOM_DISTANCE 5

//from https://www.shadertoy.com/view/XdfGDH
float gaussian(in float x, in float sigma){
	return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

void main() {
    vec4 color = texture2D(u_color, v_uv);

    float increment = 1.0/float(u_height);
    //scan y pixels leftward and rightward, check if the color is > 1
    float sigma = 7.0;
    for(int i = -BLOOM_DISTANCE; i < BLOOM_DISTANCE; i++){
        vec2 newPx = v_uv + vec2(0, float(i) * increment);
        if(newPx.y >= 0.0 && newPx.y <= 1.0){
            vec3 clr = texture2D(u_color, newPx).rgb;
            if(clr.x >= 1.0 || clr.y >= 1.0 || clr.z >= 1.0)
                color.rgb += gaussian(abs(float(i)), sigma) * clr;
        }
    }

    gl_FragColor = color;
}
