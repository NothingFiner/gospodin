// /Users/eliotasenothgaspar-finer/Projects/Gospodin/assets/shaders/spooky_lighting.fs

// 'love_time' is a uniform float automatically provided by LÖVE.
extern number love_time;

// This function generates a pseudo-random value between 0.0 and 1.0
number random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Sample the original color from the light map texture
    vec4 original_color = Texel(texture, texture_coords);

    // Calculate a flicker intensity based on time and position
    number flicker = (random(texture_coords + love_time * 0.5) * 0.2) + 0.9; // Flicker between 90% and 110%

    // Apply the flicker and a spooky color tint (e.g., a dim orange)
    // We also add a base ambient light level so unlit areas aren't pure black.
    vec3 ambient_light = vec3(0.25, 0.25, 0.3);
    vec3 spooky_color_tint = vec3(1.0, 0.8, 0.6);
    
    return vec4(ambient_light + original_color.rgb * flicker * spooky_color_tint, 1.0);
}
