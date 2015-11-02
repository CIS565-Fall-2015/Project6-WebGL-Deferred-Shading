#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 5

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

uniform vec3 u_camPos; // in world space

uniform int u_width;
uniform int u_height;
uniform int u_tileSize;
uniform int u_numLightsMax;

varying vec2 v_uv;
const float shininess = 16.0;
const int MAX_LIGHTS = 20; // don't forget to change max lights over in deferredRender.js!

vec3 applyNormalMap(vec3 geomnor, vec3 normap) {
    normap = normap * 2.0 - 1.0;
    vec3 up = normalize(vec3(0.001, 1, 0.001));
    vec3 surftan = normalize(cross(geomnor, up));
    vec3 surfbinor = cross(geomnor, surftan);
    return normap.y * surftan + normap.x * surfbinor + normap.z * geomnor;
}

vec3 blynnPhong(vec3 lightPos, float radius, vec3 lightCol, vec3 pos, vec3 norm, vec3 col) {
    vec3 lightDir = normalize(lightPos - pos);
    float lightDistance = length(lightPos - pos);
    float lambert = max(dot(lightDir, norm), 0.0);
    float specular = 0.0;
    if (lambert > 0.0) {
        vec3 viewDir = normalize(pos - u_camPos);

        // "blinn phong"
        vec3 halfDir = normalize(lightDir + viewDir);
        float specAngle = max(dot(halfDir, norm), 0.0);
        specular = pow(specAngle, shininess);
    }

    float attenuation = max(0.0, radius - lightDistance);

    vec3 color = lambert * col * lightCol + specular * lightCol;
    color *= attenuation;
    return color;
}

void main() {
    vec4 gb0 = texture2D(u_gbufs[0], v_uv); // texture mapped color
    vec4 gb1 = texture2D(u_gbufs[1], v_uv); // world space position
    vec4 gb2 = texture2D(u_gbufs[2], v_uv); // geometry normal
    vec4 gb3 = texture2D(u_gbufs[3], v_uv); // mapped normal
    float depth = texture2D(u_depth, v_uv).x;
    // TODO: Extract needed properties from the g-buffers into local variables
    // These definitions are suggested for starting out, but you will probably want to change them.
    vec3 pos = gb1.xyz;     // World-space position
    vec3 geomnor = gb2.xyz;  // Normals of the geometry as defined, without normal mapping
    vec3 colmap = gb0.xyz;  // The color map - unlit "albedo" (surface color)
    vec3 normap = gb3.xyz;  // The raw normal map (normals relative to the surface they're on)
    vec3 nor = normalize(applyNormalMap(geomnor, normap)); // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)

    // If nothing was rendered to this pixel, set alpha to 0 so that the
    // postprocessing step can render the sky color.
    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }

    // start reading dem lights!
    vec4 lightDataStructure = texture2D(u_gbufs[4], v_uv);

    // figure out which tile this is
    // compute the number of tiles
    int num_tiles_wide = (u_width + u_tileSize - 1) / u_tileSize;
    int num_tiles_high = (u_height + u_tileSize - 1) / u_tileSize;
    int num_tiles = num_tiles_wide * num_tiles_high;

    // use the uv to compute this's tile coordinates
    int tile_x = int(v_uv.x * float(u_width)) / u_tileSize;
    int tile_y = int(v_uv.y * float(u_height)) / u_tileSize;
    int tile_number = tile_x + tile_y * num_tiles_wide;

    // use to quickly try out light color sampling. if we can do this, we can sample anything.
    float tile_uv_x = float(tile_x * u_tileSize) / float(u_width); // corner's pixel coordinates / dimensions
    float tile_uv_y = float(tile_y * u_tileSize) / float(u_height);
    vec2 tile_uv = vec2(tile_uv_x, tile_uv_y);

    float uv_xStep = 1.0 / float(u_width);
    float uv_yStep = 1.0 / float(u_height);

    tile_uv.x += uv_xStep * 0.5; // sample from center of pixel
    tile_uv.y += uv_yStep * 0.5; // sample from center of pixel

    vec2 tile_uv_lightCol = vec2(tile_uv);
    tile_uv_lightCol.y += uv_yStep;

    vec3 color = vec3(0.0, 0.0, 0.0);

    // compute blynn-phong for each light
    for (int i = 0; i < MAX_LIGHTS; i++) {
        // sample light data
        vec4 lightCol = texture2D(u_gbufs[4], tile_uv_lightCol);
        vec4 lightPos = texture2D(u_gbufs[4], tile_uv);
        if (lightPos.w < 0.0) {
            break; // end of list
        }
        tile_uv.x += uv_xStep;
        tile_uv_lightCol.x += uv_xStep;
        // compute blynn-phong
        color += blynnPhong(lightPos.xyz, lightPos.w, lightCol.rgb, pos, nor, colmap);
    }
    gl_FragColor = vec4(color, 1.0);
}