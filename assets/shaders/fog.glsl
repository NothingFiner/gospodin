extern Image visibilityMap;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Get the color from the original texture (the rug)
    vec4 originalColor = Texel(tex, texture_coords);

    // Get the visibility value from our fog canvas.
    // We need to convert screen coordinates to texture coordinates for the visibility map.
    vec2 visibility_coords = screen_coords / vec2(love_ScreenSize.x, love_ScreenSize.y);
    float visibility = Texel(visibilityMap, visibility_coords).r;

    // Multiply the original color by the visibility to apply the fog.
    return originalColor * visibility;
}