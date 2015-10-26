#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {

    vec4 org_color = texture2D(u_color, v_uv);
	vec4 color = clamp(org_color,0.0,1.0);
	float colMag = color.r*color.r+color.g*color.g+color.b*color.b;
	colMag*=color.a*color.a;
    
	//gl_FragColor = color;
	//return;
	
	if (colMag>2.5)//TODO: later,uniform
	{
        gl_FragColor = org_color;
    }
	else
		gl_FragColor = vec4(0,0,0,0);
}
