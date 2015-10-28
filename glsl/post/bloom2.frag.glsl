#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

uniform float u_width;
uniform float u_height;

varying vec2 v_uv;


void main() {
    vec4 color = texture2D(u_color, v_uv);
	
	
	
    if(color.a > 1.0)
	{
		//blur along x
		float dy = 1.0/u_height;
		vec4 color_1 = texture2D(u_color, vec2(v_uv.x ,v_uv.y-dy));
		vec4 color_2 = texture2D(u_color, vec2(v_uv.x ,v_uv.y+dy));
		vec4 color_3 = texture2D(u_color, vec2(v_uv.x ,v_uv.y-dy-dy));
		vec4 color_4 = texture2D(u_color, vec2(v_uv.x ,v_uv.y+dy+dy));

		gl_FragColor = (color_3 + color_4 + color_1*3.0 + color_2*3.0 + color*7.0 )/15.0;

		
		return;
	}
	
	
	gl_FragColor = color;
}
