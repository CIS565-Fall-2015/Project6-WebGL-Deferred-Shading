#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

const int bloomRadius = 5;
const float bloomStep = 0.001;

void main() {
    vec4 color = texture2D(u_color, v_uv);

    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }

    // box blur for bloom
    vec2 sampleUV = v_uv - vec2(bloomStep * (5.0 / 2.0));
    vec4 bloomColor = vec4(0.0);
    float numPixelSamples = 1.0;
    for (int x = 0; x < bloomRadius; x++) {
    	for (int y = 0; y < bloomRadius; y++) {
    		vec4 sampleColor = texture2D(u_color, sampleUV);
		    if (sampleColor.r > 1.0 && sampleColor.g > 1.0 && sampleColor.b > 1.0) {
		    	bloomColor += sampleColor;
		    }
		    numPixelSamples += 1.0;
		    sampleUV.y += bloomStep;
    	}
    	sampleUV.y = v_uv.y - bloomStep * 5.0 / 2.0;
		sampleUV.x += bloomStep;    	
    }
    // add bloom color
    color.xyz += bloomColor.xyz / numPixelSamples;

    gl_FragColor = color;
}
