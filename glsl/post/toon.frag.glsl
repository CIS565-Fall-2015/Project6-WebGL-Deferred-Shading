#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
    vec4 color = texture2D(u_color, v_uv);

	if(color.a == 0.0)
    {
        gl_FragColor = SKY_COLOR;
        //return;
    }  
	
	vec2 sizeFactor = vec2(1.0/800.0, 1.0/600.0);
	
	vec4 L1 = texture2D(u_color, v_uv + sizeFactor * vec2(-1.0,0.0));
	vec4 L2 = texture2D(u_color, v_uv + sizeFactor * vec2(-1.0,-1.0));
	vec4 L3 = texture2D(u_color, v_uv + sizeFactor * vec2(-1.0,1.0));
	vec4 R1 = texture2D(u_color, v_uv + sizeFactor * vec2(1.0,0.0));
	vec4 R2 = texture2D(u_color, v_uv + sizeFactor * vec2(1.0,-1.0));
	vec4 R3 = texture2D(u_color, v_uv + sizeFactor * vec2(1.0,1.0));
	
	gl_FragColor = -L1-L2-L3+R1+R2+R3;
}
