#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 3

uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform vec3 u_cameraPos;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;
uniform int u_toon;

varying vec2 v_uv;

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables
    vec3 position = gb0.xyz;
    vec3 normal = normalize(gb1.xyz);
    vec3 color_map = gb2.xyz;
    float specular_exp = gb1.w;

    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0.0);
        return;
    }

    vec3 light_difference = u_lightPos - position;
    vec3 light_direction = normalize(light_difference);
    vec3 camera_direction = normalize(u_cameraPos - position);
    float light_distance = length(light_difference);
    vec3 H = normalize(light_direction + camera_direction);

     if (light_distance > u_lightRad){
         gl_FragColor = vec4(0.0);
         return;
     }

    float falloff = 1.0 / pow(light_distance, 2.0);
    float diffuse = max(0.0, dot(normal, light_direction));
    float specular = pow(max(0.0, dot(normal, H)), specular_exp);
    // Toon ramp shading
    // http://prideout.net/blog/?p=22
    if(u_toon == 1) {
        float steps = 3.0;
        diffuse = ceil(diffuse * steps) / steps;
        specular = ceil(specular * steps) / steps;
        falloff = ceil(falloff * steps) / steps;
    }

    gl_FragColor = falloff * vec4(u_lightCol * diffuse * specular * color_map * max(0.0, u_lightRad - light_distance), 1.0);
}
