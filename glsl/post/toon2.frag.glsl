#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform sampler2D u_color_1;
varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
    vec4 color = texture2D(u_color, v_uv);
    vec4 color_1 = texture2D(u_color_1, v_uv);
	
	if(color.a == 0.0)
    {
        gl_FragColor = SKY_COLOR;
        //return;
    }  
	
	vec2 sizeFactor = vec2(1.0/800.0, 1.0/600.0);
	
	vec4 T1 = texture2D(u_color, v_uv + sizeFactor * vec2(0.0,-1.0));
	vec4 T2 = texture2D(u_color, v_uv + sizeFactor * vec2(-1.0,-1.0));
	vec4 T3 = texture2D(u_color, v_uv + sizeFactor * vec2(1.0,-1.0));
	vec4 B1 = texture2D(u_color, v_uv + sizeFactor * vec2(0.0,1.0));
	vec4 B2 = texture2D(u_color, v_uv + sizeFactor * vec2(-1.0,1.0));
	vec4 B3 = texture2D(u_color, v_uv + sizeFactor * vec2(1.0,1.0));

    vec4 blend = -T1-T2-T3+B1+B2+B3;

    blend = vec4(vec3(max(max(blend.x, blend.y), blend.z)), 1.0);

    if (blend.x <= 0.2){
        blend = vec4(vec3(0.0), 1.0);
    } else {
        blend = vec4(1.0);
    }

    gl_FragColor = (1.0-blend) * color_1;
}
