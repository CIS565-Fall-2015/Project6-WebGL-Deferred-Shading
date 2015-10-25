#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform vec4 u_settings;

uniform vec3 u_cameraPos;
uniform vec3 u_lightCol;
uniform vec3 u_lightPos;

uniform float u_camera_width;
uniform float u_camera_height;

uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

varying vec2 v_uv;

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv);
    vec4 gb1 = texture2D(u_gbufs[1], v_uv);
    vec4 gb2 = texture2D(u_gbufs[2], v_uv);
    vec4 gb3 = texture2D(u_gbufs[3], v_uv);
    float depth = texture2D(u_depth, v_uv).x;

    vec3 pos = gb0.xyz; // World-space position
    vec3 geomnor = gb1.xyz; // Normals of the geometry as defined, without normal mapping
    vec3 color = vec3(gb0.w,gb1.w,gb2.w);  // The color map - unlit "albedo" (surface color)
    vec3 normap = gb2.xyz;  // The raw normal map (normals relative to the surface they're on)
    vec3 nor = applyNormalMap(geomnor, normap); // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)

    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 1);
        return;
    }

    if (u_settings[0] == 1.0){
        float depthNeighbor = texture2D(u_depth, v_uv + 1.0/u_camera_width).x;
        float depthNeighbor2 = texture2D(u_depth, v_uv + 1.0/u_camera_height).x;

        if (abs(depth - depthNeighbor) > 0.005 || abs(depth - depthNeighbor2) > 0.005){
            gl_FragColor = vec4(1.0);
            return;
        }
    }

    float dist = length(u_lightPos - pos);

    // Diffuse
    vec3 lightDir = normalize(u_lightPos - pos);
    float diffuse = dot(nor, lightDir);

    // Specular
    vec3 cameraDir = normalize(u_cameraPos - pos);
    vec3 halfVector = normalize(lightDir + cameraDir);
    float specular = dot(nor, halfVector);

    vec3 fragColor = color.rgb;

    // Normal shading
    if (u_settings[0] == 1.0){
        if (diffuse > 0.6){
            fragColor *= 0.6;
        } else if (diffuse > 0.3) {
            fragColor *= 0.3;
        } else {
            fragColor *= max(0.0, 0.4 - diffuse);
        }
        fragColor *= max(0.0,(u_lightRad - 0.1 - dist));

    // Toon shading
    } else {
        fragColor *= diffuse * max(0.0,(u_lightRad - dist)) * 0.5;
        fragColor += color.rgb * specular * max(0.0,(u_lightRad - dist)) * 0.5;
    }

    gl_FragColor = vec4(fragColor, 1.0);
}
