#version 100
precision highp float;
precision highp int;

#define NUM_GBUFFERS 5

uniform sampler2D u_gbufs[NUM_GBUFFERS];
uniform sampler2D u_depth;

uniform int u_width;
uniform int u_height;
uniform int u_tileSize;
uniform int u_numLightsMax;

uniform sampler2D u_light_list_indices; // an alpha buffer, so need to mul values by 100 and clamp
//uniform sampler2D u_light_lists; // an alpha buffer, so need to mul values by 100 and clamp

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
    // These definitions are suggested for starting out, but you will probably want to change them.
    vec3 pos = gb1.xyz;     // World-space position
    vec3 geomnor = gb2.xyz;  // Normals of the geometry as defined, without normal mapping
    vec3 colmap = gb0.xyz;  // The color map - unlit "albedo" (surface color)
    vec3 normap = gb3.xyz;  // The raw normal map (normals relative to the surface they're on)
    vec3 nor = normalize(applyNormalMap(geomnor, normap)); // The true normals as we want to light them - with the normal map applied to the geometry normals (applyNormalMap above)

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
    tile_uv.x += 0.0005; // jitter
    tile_uv.y += 0.0005; // jitter

    float uv_yStep = 1.0 / float(u_height);
    float uv_xStep = 1.0 / float(u_width);
    tile_uv.y += uv_yStep;
    //tile_uv.x += uv_xStep;

    // for testing sampling
    vec4 firstLightCol = texture2D(u_gbufs[4], tile_uv);
    gl_FragColor = vec4(firstLightCol.rgb * 0.25, 1.0);

    // for debugging the tile_number calculation
    //float gradient = float(tile_number) / float (num_tiles);
    //gl_FragColor = vec4(vec3(gradient * 4.0), 1.0); // need multiplier, or gradient per line is too slight

    // for debugging tile_x and tile_y
    //gl_FragColor = vec4(vec3(tile_uv_x, tile_uv_y, 0.0), 1.0);

    // for looking at the light datastructure directly
    if (lightDataStructure.a > 0.0) {
        gl_FragColor = vec4(lightDataStructure.rgb * 0.5, 1.0);
    }
}