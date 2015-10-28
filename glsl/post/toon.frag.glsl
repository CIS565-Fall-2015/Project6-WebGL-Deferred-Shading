#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

uniform float u_width;
uniform float u_height;

varying vec2 v_uv;


void main() {
    vec4 color = texture2D(u_color, v_uv);
	
	
	if(color.r > 0.5) 
	{
		color.r = 0.75;
	}
	else
	{
		color.r = 0.25;
	}

	if(color.g > 0.5) 
	{
		color.g = 0.75;
	}
	else
	{
		color.g = 0.25;
	}

	if(color.b > 0.5) 
	{
		color.b = 0.75;
	}
	else
	{
		color.b = 0.25;
	}
   
	
	
	gl_FragColor = color;
}
