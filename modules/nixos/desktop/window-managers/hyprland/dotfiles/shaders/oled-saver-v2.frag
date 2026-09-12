/*
 * OLED power-saving screen shader.
 *
 * A one-frame checkerboard passes one half of the framebuffer pixels and
 * makes the other half black. Every minute the two halves exchange roles.
 * The exchange is cross-faded: paired pixels always have a combined gain of
 * 1.0, keeping the average emitted light close to 50% during the transition.
 *
 * This operates on framebuffer pixels, not the panel's individual RGB
 * subpixels. The fine pattern is least noticeable on a high-density display.
 * Using Hyprland's `time` uniform requires damage tracking to be disabled, so
 * measure total system power: continuous compositing may offset panel savings.
 */

#version 300 es

#ifndef OLED_SWAP_INTERVAL
#define OLED_SWAP_INTERVAL 60.0
#endif

#ifndef OLED_FADE_DURATION
#define OLED_FADE_DURATION 8.0
#endif

precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D tex;
uniform float time;

void main() {
    vec4 source = texture(tex, v_texcoord);

    // Alternate physical framebuffer pixels in both axes. Adding 0.5 avoids
    // edge ambiguity if a driver exposes pixel centres with minor imprecision.
    vec2 pixel = floor(gl_FragCoord.xy + vec2(0.5));
    float checker = mod(pixel.x + pixel.y, 2.0);

    float interval = max(OLED_SWAP_INTERVAL, 0.001);
    float fadeDuration = clamp(OLED_FADE_DURATION, 0.001, interval);
    float intervalTime = mod(time, interval);
    float intervalIndex = floor(time / interval);

    // Hold the pattern steady, then use a smooth complementary crossfade into
    // the next pattern at the end of each interval.
    float fadeStart = interval - fadeDuration;
    float transition = smoothstep(fadeStart, interval, intervalTime);
    float currentPhase = mod(intervalIndex, 2.0);
    float nextPhase = 1.0 - currentPhase;
    float phase = mix(currentPhase, nextPhase, transition);

    // checker=0 uses 1-phase and checker=1 uses phase. Their gains sum to 1.
    float gain = mix(1.0 - phase, phase, checker);
    fragColor = vec4(source.rgb * gain, source.a);
}
