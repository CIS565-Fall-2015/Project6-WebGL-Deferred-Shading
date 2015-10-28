#version 100
precision highp float;
precision highp int;

uniform float u_xmin;
uniform float u_xmax;
uniform float u_ymin;
uniform float u_ymax;

varying vec2 v_uv;

void main() {
    
	if(v_uv.x<=u_xmax && v_uv.x>=u_xmin && v_uv.y<=u_ymax && v_uv.y>=u_ymin)
	{
		gl_FragColor = vec4(1, 0, 0, 0.1);
	}
	
}
