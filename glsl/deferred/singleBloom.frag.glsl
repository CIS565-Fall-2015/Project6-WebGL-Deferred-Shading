#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

const vec3 offset = vec3( 0.0, 1.0, 2.0);//35,21,7,1 :sum:126
const vec3 weight= vec3(0.48, 0.31, 0.17);
const float width=800.0;
const float height=600.0;
const float sp=0.20;
void main() {
    vec4 color = texture2D(u_color, v_uv);
    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }
	if(color.x>sp||color.y>sp||color.z>sp){
	vec4 FragmentColor = texture2D( u_color, vec2(v_uv)) * weight.x;
	FragmentColor += texture2D( u_color,  vec2(v_uv)+ vec2(offset.y,0.0 )/width )*weight.y;
	FragmentColor += texture2D( u_color,  vec2(v_uv)- vec2(offset.y,0.0 )/width )*weight.y;
    FragmentColor += texture2D( u_color,  vec2(v_uv)+ vec2(offset.z,0.0 )/width )*weight.z;
	FragmentColor += texture2D( u_color,  vec2(v_uv)- vec2(offset.z,0.0 )/width )*weight.z;
	
	FragmentColor += texture2D( u_color,  vec2(v_uv)+ vec2(0.0, offset.y )/height)*weight.y;
	FragmentColor += texture2D( u_color,  vec2(v_uv)- vec2(0.0, offset.y )/height)*weight.y;
    FragmentColor += texture2D( u_color,  vec2(v_uv)+ vec2(0.0, offset.z )/height)*weight.z;
	FragmentColor += texture2D( u_color,  vec2(v_uv)- vec2(0.0, offset.z )/height)*weight.z;
    gl_FragColor = FragmentColor;
	}
	else {
	gl_FragColor=vec4(color.xyz,1.0);
	}
	
}
