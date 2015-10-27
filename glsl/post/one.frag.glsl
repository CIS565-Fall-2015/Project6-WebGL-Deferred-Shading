#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

uniform float u_width;
uniform float u_height;
uniform vec4 u_settings;

uniform float u_kernel[5];

void main() {
    vec4 color = texture2D(u_color, v_uv);

    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }

    // Naive 1-pass bloom filter
    if (u_settings.x==1.0){
	    vec2 n_uv;
	    vec4 n_color;

	    for (int i=-2; i <= 2; i++){
	    	for (int j=-2; j <= 2; j++){
	    		n_uv = v_uv + vec2(float(i)/800.0, float(j)/600.0);
	    		n_color = texture2D(u_color, n_uv);
	    		color.r += (0.01)*n_color.r;
	    		color.g += (0.01)*n_color.g;
	    		color.b += (0.01)*n_color.b;
	    	}
	    }
    }

    gl_FragColor = clamp(color, 0.0, 1.0);
}
