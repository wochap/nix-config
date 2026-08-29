/*
 * Moderate paper-like reader profile.
 *
 * These constants are deliberately easy to tune for a specific panel. The
 * shader only transforms color; it does not sample neighbouring pixels, so
 * text and other spatial detail remain unchanged.
 */

#version 300 es

#ifndef READER_SATURATION
#define READER_SATURATION 0.55
#endif
#ifndef READER_BLACK_LEVEL
#define READER_BLACK_LEVEL 0.015
#endif
#ifndef READER_WHITE_LEVEL
#define READER_WHITE_LEVEL 0.82
#endif
#ifndef READER_HIGHLIGHT_TINT
#define READER_HIGHLIGHT_TINT vec3(1.0, 0.995, 0.98)
#endif

precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 source = texture(tex, v_texcoord);
    float luma = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 softened = mix(vec3(luma), source.rgb, READER_SATURATION);

    softened = mix(vec3(READER_BLACK_LEVEL), vec3(READER_WHITE_LEVEL), softened);

    // Concentrate the already-mild warmth in highlights. Hyprsunset remains
    // responsible for the overall color temperature.
    float highlight = smoothstep(0.35, 1.0, luma);
    softened *= mix(vec3(1.0), READER_HIGHLIGHT_TINT, highlight);

    fragColor = vec4(clamp(softened, 0.0, 1.0), source.a);
}
