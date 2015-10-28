#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 2

uniform vec3 u_camPos; // in world space
uniform vec3 u_lightCol;
uniform vec3 u_lightPos;
uniform float u_lightRad;
uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;
uniform mat4 u_invCameraMat;

const float shininess = 16.0;

varying vec2 v_uv;

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv); // texture mapped color
    vec4 gb1 = texture2D(u_gbufs[1], v_uv); // compressed "final" normal
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables
    // These definitions are suggested for starting out, but you will probably want to change them.
    vec4 screenPos = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 pos = vec3(0.0, 0.0, 0.0);

    if (depth < 1.0) {
        // reconstruct screen space position
        // https://mynameismjp.wordpress.com/2009/03/10/reconstructing-position-from-depth/
        // http://stackoverflow.com/questions/22360810/reconstructing-world-coordinates-from-depth-buffer-and-arbitrary-view-projection
        screenPos.x = v_uv.x * 2.0 - 1.0;
        screenPos.y = v_uv.y * 2.0 - 1.0;
        screenPos.z = depth * 2.0 - 1.0;
        vec4 worldPos = u_invCameraMat * screenPos;
        worldPos /= worldPos.w;
        pos = worldPos.xyz;
    }

    // reconstruct normal
    vec3 norm = vec3(gb1.xy, 1.0);
    if (abs(norm.x) > 0.0 && abs(norm.y) > 0.0 && abs(norm.y) < 1.0) {
        if (abs(norm.x) >= 1.0) {
            norm.z = -1.0;
            norm.x -= norm.x / abs(norm.x);
        }
        norm.z *= sqrt(1.0 - norm.x * norm.x - norm.y * norm.y);
    } else {
        norm = vec3(0.0, 0.0, 0.0);
    }

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

    vec3 color = lambert * gb0.rgb * u_lightCol + specular * u_lightCol;
    color *= attenuation;

    gl_FragColor = vec4(color, 1);
}
