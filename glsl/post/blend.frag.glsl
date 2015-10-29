#version 100
precision highp float;
precision highp int;


varying vec2 v_uv;

uniform sampler2D scene;
uniform sampler2D bloomBlur;
uniform float exposure;

void main()
{             
    const float gamma = 2.2;
    vec3 hdrColor = texture(scene, v_uv).rgb;      
    vec3 bloomColor = texture(bloomBlur, v_uv).rgb;
    hdrColor += bloomColor; // additive blending
    // tone mapping
    vec3 result = vec3(1.0) - exp(-hdrColor * exposure);
    // also gamma correct while we're at it       
    result = pow(result, vec3(1.0 / gamma));
    gl_FragColor = vec4(result, 1.0f);
}  