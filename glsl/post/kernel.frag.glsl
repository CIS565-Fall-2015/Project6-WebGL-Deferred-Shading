#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
//uniform sampler2D u_depthTex;

uniform vec2 u_texSize;

varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

vec4 applyKernel(vec2 onePixel,mat3 kern)
{
    vec4 color = vec4 (0.0,0.0,0.0,0.0);//texture2D(u_color, v_uv);
	
	color += texture2D(u_color, v_uv + onePixel * vec2(-1, -1))*kern[0][0];
	color += texture2D(u_color, v_uv + onePixel * vec2(-1,  0))*kern[0][1];
	color += texture2D(u_color, v_uv + onePixel * vec2(-1,  1))*kern[0][2];
	
	color += texture2D(u_color, v_uv + onePixel * vec2( 0, -1))*kern[1][0];
	color += texture2D(u_color, v_uv + onePixel * vec2( 0,  0))*kern[1][1];
	color += texture2D(u_color, v_uv + onePixel * vec2( 0,  1))*kern[1][2];
		
	color += texture2D(u_color, v_uv + onePixel * vec2( 1, -1))*kern[2][0];
	color += texture2D(u_color, v_uv + onePixel * vec2( 1,  0))*kern[2][1];
	color += texture2D(u_color, v_uv + onePixel * vec2( 1,  1))*kern[2][2];
	
	return color;
}

float discrete(float inCol,int level)
{
	inCol = clamp(inCol,0.0,1.0);
	if(inCol>=0.9) return 0.9;
	if(inCol>=0.6) return 0.6;
	if(inCol>=0.2) return 0.2;
	return inCol;
}

void main() {
	
	vec2 oneP = vec2(1.0,1.0)/u_texSize;
	
	mat3 edgeX = mat3(
		-1.0,  0.0,  1.0,
		-2.0,  0.0,  2.0,
		-1.0,  0.0,  1.0);
	mat3 edgeY = mat3(
		-1.0, -2.0, -1.0,
		 0.0,  0.0,  0.0,
		 1.0,  2.0,  1.0);	
	vec4 color = applyKernel(oneP,edgeX);
	color += applyKernel(oneP,edgeY);
	
	color = abs(color);
	color.a = 1.0;
	if(length(color.rgb)>0.05)	color.rgb = vec3(0,0,0);
	else color.rgb = vec3(1,1,1);
	
	vec4 origCol = texture2D(u_color, v_uv);
	origCol.r = discrete(origCol.r,3);	
	origCol.g = discrete(origCol.g,3);
	origCol.b = discrete(origCol.b,3);
	origCol.a = discrete(origCol.a,3);
	
    gl_FragColor = color*origCol;
	
	//gl_FragColor = texture2D(u_color, v_uv);
}
