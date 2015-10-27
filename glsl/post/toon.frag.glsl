#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform sampler2D u_depthTex;

uniform vec2 u_texSize;
//uniform float u_thresh;
varying vec2 v_uv;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

vec4 applyKernel(vec2 onePixel,mat3 kern)
{
    vec4 color = vec4 (0.0,0.0,0.0,0.0);//texture2D(u_color, v_uv);
	
	color += texture2D(u_depthTex, v_uv + onePixel * vec2(-1, -1))*kern[0][0];
	color += texture2D(u_depthTex, v_uv + onePixel * vec2(-1,  0))*kern[0][1];
	color += texture2D(u_depthTex, v_uv + onePixel * vec2(-1,  1))*kern[0][2];
	
	color += texture2D(u_depthTex, v_uv + onePixel * vec2( 0, -1))*kern[1][0];
	color += texture2D(u_depthTex, v_uv + onePixel * vec2( 0,  0))*kern[1][1];
	color += texture2D(u_depthTex, v_uv + onePixel * vec2( 0,  1))*kern[1][2];
		
	color += texture2D(u_depthTex, v_uv + onePixel * vec2( 1, -1))*kern[2][0];
	color += texture2D(u_depthTex, v_uv + onePixel * vec2( 1,  0))*kern[2][1];
	color += texture2D(u_depthTex, v_uv + onePixel * vec2( 1,  1))*kern[2][2];
	
	return color;
}

float discrete(float inCol,int level)
{
	inCol = clamp(inCol,0.0,1.0);
	if(inCol>=0.9) return 0.9;
	if(inCol>=0.6) return 0.6;
	if(inCol>=0.2) return 0.2;
	return inCol;
	/*
	int temp = int(inCol*float(level));
	temp =temp - (temp/level)*level;
	return float(temp);
	*/
}

void main() {
	//edge
	//http://www.greenbushlabs.com/ThreeJS/examples/webgl_postprocessing2.html
	//https://en.wikipedia.org/wiki/Cel_shading#Process	
	vec2 oneP = vec2(1.0,1.0)/u_texSize;
	
	mat3 edgeX = mat3(
		-1.0,  0.0,  1.0,
		-2.0,  0.0,  2.0,
		-1.0,  0.0,  1.0);
	mat3 edgeY = mat3(
		-1.0, -2.0, -1.0,
		 0.0,  0.0,  0.0,
		 1.0,  2.0,  1.0);
		 
	vec4 edgeCol = applyKernel(oneP,edgeX);
 	edgeCol += applyKernel(oneP,edgeY);
	
	edgeCol = abs(edgeCol);
	if(length(edgeCol.rgb)>0.05) edgeCol = vec4(0,0,0,1);
	else edgeCol = vec4(1,1,1,1);
	
    vec4 color = texture2D(u_color, v_uv);
	
	color.r = discrete(color.r,3);	
	color.g = discrete(color.g,3);
	color.b = discrete(color.b,3);
	color.a = discrete(color.a,3);

	gl_FragColor = edgeCol*color;
	
}
