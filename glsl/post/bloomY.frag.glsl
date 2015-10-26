#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform vec2 u_texSize;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
	
	vec2 onePixel = vec2(1.0,1.0)/u_texSize;
	vec4 gauss = vec4 (10.0,8.0,5.0,2.0) ;
	gauss*=(1.0/25.0);
    vec4 color = vec4 (0.0,0.0,0.0,0.0);//texture2D(u_color, v_uv);
	
	color += texture2D(u_color, v_uv + onePixel * vec2(0, 0))*gauss[0];
	
	color += texture2D(u_color, v_uv + onePixel * vec2(0, 1))*gauss[1];
	color += texture2D(u_color, v_uv + onePixel * vec2(0, 2))*gauss[2];
	color += texture2D(u_color, v_uv + onePixel * vec2(0, 3))*gauss[3];
	
	color += texture2D(u_color, v_uv + onePixel * vec2(0, -1))*gauss[1];
	color += texture2D(u_color, v_uv + onePixel * vec2(0, -2))*gauss[2];
	color += texture2D(u_color, v_uv + onePixel * vec2(0, -3))*gauss[3];
	

    gl_FragColor = color;
	
	//gl_FragColor = texture2D(u_color, v_uv);
}
