#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 4

uniform vec3 u_camPos; // in world space
uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;
const float shininess = 16.0;

varying vec2 v_uv;

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv); // texture mapped color
    vec4 gb1 = texture2D(u_gbufs[1], v_uv); // world space position
    vec4 gb2 = texture2D(u_gbufs[2], v_uv); // geometry normal
    vec4 gb3 = texture2D(u_gbufs[3], v_uv); // mapped normal
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables
    vec3 pos = gb1.xyz;     // cam space position
    vec3 colmap = gb0.xyz;  // The color map - unlit "albedo" (surface color)
    vec3 norm = applyNormalMap(gb2.xyz, gb3.xyz);     // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)

    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }

    // https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model
    vec3 lightDir = normalize(u_lightPos - pos);
    float lightDistance = length(u_lightPos - pos);
    float lambert = max(dot(lightDir, norm), 0.0);
    float specular = 0.0;
    if (lambert > 0.0) {
        vec3 viewDir = normalize(pos - u_camPos);

        // "blinn phong"
        vec3 halfDir = normalize(lightDir + viewDir);
        float specAngle = max(dot(halfDir, norm), 0.0);
        specular = pow(specAngle, shininess);
    }

    float attenuation = max(0.0, u_lightRad - lightDistance);

    vec3 color = lambert * colmap * u_lightCol + specular * u_lightCol;
    color *= attenuation;

    gl_FragColor = vec4(color, 1); 
}
