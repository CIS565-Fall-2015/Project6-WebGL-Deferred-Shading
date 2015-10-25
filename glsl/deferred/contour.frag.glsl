#version 100
precision highp float;
precision highp int;



#define TOON_DEPTH_THRESHOLD 0.003

uniform float u_width;
uniform float u_height;


uniform sampler2D u_depth;

varying vec2 v_uv;


float unpack_depth(const in vec4 rgba_depth){
/*
    const vec4 bit_shift =
        vec4(1.0/(256.0*256.0*256.0)
            , 1.0/(256.0*256.0)
            , 1.0/256.0
            , 1.0);
    float depth = dot(rgba_depth, bit_shift);
    return depth;
    */
    return rgba_depth.x;
}

void main() {
    float depth = texture2D(u_depth, v_uv).x;

    if (depth == 1.0) {
        gl_FragColor = vec4(0, 0, 0, 0); // set alpha to 0
        return;
    }


    
    
    vec2 x_offset = vec2(1.0/u_width, 0.0);
    vec2 y_offset = vec2(0.0, 1.0/u_height);
    
    //float laplacian = depth;
    
    
    float laplacian = abs(texture2D(u_depth, v_uv + x_offset).x
                            + texture2D(u_depth, v_uv - x_offset).x
                            + texture2D(u_depth, v_uv + y_offset).x
                            + texture2D(u_depth, v_uv - y_offset).x
                            - 4.0 * depth);
                              
              
    if(laplacian > TOON_DEPTH_THRESHOLD)
    {
        //contour
        //use black
        gl_FragColor = vec4(0, 0, 0, 1);
        return;
    }
    
    
    gl_FragColor = vec4(0,0,0,0);
   
}
