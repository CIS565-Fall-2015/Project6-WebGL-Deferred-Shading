#version 100
precision highp float;
precision highp int;

uniform sampler2D u_lights; // an alpha buffer, so need to mul values by 100 and clamp
uniform sampler2D u_light_lists; // an alpha buffer, so need to mul values by 100 and clamp
uniform sampler2D u_light_list_indices; // an alpha buffer, so need to mul values by 100 and clamp

uniform uInt u_width;
uniform uInt u_height;
uniform uInt u_tileSize;
uniform uInt u_numLightsMax;

varying vec2 v_uv;

void main() {
    // compute the number of tiles
    int num_tiles_wide = (u_width + u_tileSize - 1) / u_tileSize;
    int num_tiles_high = (u_height + u_tileSize - 1) / u_tileSize;
    float num_tiles = num_tiles_wide * num_tiles_high;

    // use the uv to compute this's tile coordinates
    int tile_x = (v_uv.x * u_width) / u_tileSize;
    int tile_y = (v_uv.y * u_height) / u_tileSize;
    float tile_number = tile_y + tile_x * num_tiles_high;

    // compute this tile's start index in u_light_list_indices. get this tile's number of lights
    int startIndex = tile_number * u_numLightsMax;
    vec2 light_list_indices_uv = vec2(0.5, 0.5);
    light_list_indices_uv.x = tile_number / num_tiles;

    // sample this tile's number of lights
    vec4 numLightsAsAlpha = texture2D(u_light_list_indices, light_list_indices_uv);

    vec3 color = vec3(numLightsAsAlpha.a);

    gl_FragColor = vec4(color, 1); 
}
