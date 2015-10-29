#version 100
precision highp float;
precision highp int;

uniform sampler2D u_color;
uniform float u_bloom;
varying vec2 v_uv;

uniform vec2 u_resolution;
uniform vec2 u_dir;

const vec4 SKY_COLOR = vec4(0.01, 0.14, 0.42, 1.0);

void main() {
	vec4 color = texture2D(u_color, v_uv);

    if (color.a == 0.0) {
        gl_FragColor = SKY_COLOR;
        return;
    }


	vec4 sum = vec4(0.0);
	
    //the amount to blur, i.e. how far off center to sample from 
    //1.0 -> blur by one pixel
    //2.0 -> blur by two pixels, etc.
    float blur = 4.0/u_resolution.x; 

    //the direction of our blur
    //(1.0, 0.0) -> x-axis blur
    //(0.0, 1.0) -> y-axis blur
    float hstep = u_dir.x;
    float vstep = u_dir.y;

    //apply blurring, using a 9-tap filter with predefined gaussian weights

    sum += texture2D(u_color, vec2(v_uv.x - 4.0*blur*hstep, v_uv.y - 4.0*blur*vstep)) * 0.0162162162;
    sum += texture2D(u_color, vec2(v_uv.x - 3.0*blur*hstep, v_uv.y - 3.0*blur*vstep)) * 0.0540540541;
    sum += texture2D(u_color, vec2(v_uv.x - 2.0*blur*hstep, v_uv.y - 2.0*blur*vstep)) * 0.1216216216;
    sum += texture2D(u_color, vec2(v_uv.x - 1.0*blur*hstep, v_uv.y - 1.0*blur*vstep)) * 0.1945945946;

    sum += texture2D(u_color, vec2(v_uv.x, v_uv.y)) * 0.2270270270;

    sum += texture2D(u_color, vec2(v_uv.x + 1.0*blur*hstep, v_uv.y + 1.0*blur*vstep)) * 0.1945945946;
    sum += texture2D(u_color, vec2(v_uv.x + 2.0*blur*hstep, v_uv.y + 2.0*blur*vstep)) * 0.1216216216;
    sum += texture2D(u_color, vec2(v_uv.x + 3.0*blur*hstep, v_uv.y + 3.0*blur*vstep)) * 0.0540540541;
    sum += texture2D(u_color, vec2(v_uv.x + 4.0*blur*hstep, v_uv.y + 4.0*blur*vstep)) * 0.0162162162;

    //discard alpha for our simple demo, multiply by vertex color and return
    gl_FragColor = color * vec4(sum.rgb, 1.0);




}







