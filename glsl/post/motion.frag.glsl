#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;

varying vec2 v_uv;

#define NUM_GBUFFERS 4
uniform mat4 u_prevPM;
uniform mat4 u_invMat;
uniform sampler2D u_depth;
uniform sampler2D u_worldPos;


const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
	vec4 color = texture2D(u_color, v_uv);
	vec2 texCoords = v_uv;
	float depth = texture2D(u_depth, v_uv).x;
	vec4 gb0 = texture2D(u_worldPos, v_uv);
	vec3 pos = gb0.xyz; // / gb0.w;
	vec4 H = vec4(v_uv.x*2.0 - 1.0, (v_uv.y) * 2.0 - 1.0, depth, 1.0);
	//vec4 D = u_invMat * H;
	//D = D / D.w;
	vec4 currentPos = H;

	vec4 prevPos =  (u_prevPM) * vec4(pos, 1.0);
	prevPos /= prevPos.w;

	vec2 velocity = (currentPos.xy - prevPos.xy) / 2.0;

	texCoords += velocity;

	for (int i = 0; i < 5; i++) {
		vec4 currentCol = texture2D(u_color, texCoords);
		color += currentCol;
		texCoords += velocity;
	}

	gl_FragColor = (color / 5.0);

	/*
	vec4 prevPos = u_prevPM * vec4(pos, 1.0);
	prevPos.xyz /= prevPos.w;
	prevPos.xy = prevPos.xy * 0.5 + 0.5;

	vec2 blurVec = prevPos.xy - v_uv;

	vec4 result = texture2D(u_color, v_uv);
	for (int i = 1; i < 5; ++i) {
	
	  	vec2 offset = blurVec * (float(i) / float(5.0 - 1.0) - 0.5);


	  	result += texture2D(u_color, v_uv + offset);
	}

	result /= 5.0;

	gl_FragColor = result;*/
}