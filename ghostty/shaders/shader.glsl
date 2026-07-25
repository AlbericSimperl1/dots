// // ============================================================================
// // GHOSTTY SHADER: PARALLELOGRAM CURSOR + STABLE OKLAB PROFILE + SUBTLE BLOOM
// // ============================================================================
//
// // --- HELPER FUNCTIONS & COLOR SPACES ---
//
// // sRGB linear -> nonlinear transform
// float f(float x) {
//     if (x >= 0.0031308) {
//         return 1.055 * pow(x, 1.0 / 2.4) - 0.055;
//     } else {
//         return 12.92 * x;
//     }
// }
//
// float f_inv(float x) {
//     if (x >= 0.04045) {
//         return pow((x + 0.055) / 1.055, 2.4);
//     } else {
//         return x / 12.92;
//     }
// }
//
// // sRGB -> Linear conversion for Cursor
// vec3 sRGBToLinear(vec3 c) {
//     return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
// }
//
// // Oklab <-> linear sRGB conversions
// vec4 toOklab(vec4 rgb) {
//     vec3 c = vec3(f_inv(rgb.r), f_inv(rgb.g), f_inv(rgb.b));
//     float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
//     float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
//     float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
//     float l_ = pow(l, 1.0 / 3.0);
//     float m_ = pow(m, 1.0 / 3.0);
//     float s_ = pow(s, 1.0 / 3.0);
//     return vec4(
//         0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
//         1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
//         0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
//         rgb.a
//     );
// }
//
// vec4 toRgb(vec4 oklab) {
//     vec3 c = oklab.rgb;
//     float l_ = c.r + 0.3963377774 * c.g + 0.2158037573 * c.b;
//     float m_ = c.r - 0.1055613458 * c.g - 0.0638541728 * c.b;
//     float s_ = c.r - 0.0894841775 * c.g - 1.2914855480 * c.b;
//     float l = l_ * l_ * l_;
//     float m = m_ * m_ * m_;
//     float s = s_ * s_ * s_;
//     vec3 linear_srgb = vec3(
//          4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
//         -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
//         -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
//     );
//     return vec4(
//         clamp(f(linear_srgb.r), 0.0, 1.0),
//         clamp(f(linear_srgb.g), 0.0, 1.0),
//         clamp(f(linear_srgb.b), 0.0, 1.0),
//         oklab.a
//     );
// }
//
// // --- CONFIGURATION (YOUR CURSOR CONFIG) ---
// const float DURATION = 0.09; 
// const float MAX_TRAIL_LENGTH = 0.2;
// const float THRESHOLD_MIN_DISTANCE = 1.5; 
// const float BLUR = 2.0; 
// const float PI = 3.14159265359;
//
// // --- CONFIGURATION (STABLE GLOW / BLOOM SAMPLES) ---
// const vec3[24] samples = {
//   vec3(0.1693761725038636, 0.9855514761735895, 1),
//   vec3(-1.333070830962943, 0.4721463328627773, 0.7071067811865475),
//   vec3(-0.8464394909806497, -1.51113870578065, 0.5773502691896258),
//   vec3(1.554155680728463, -1.2588090085709776, 0.5),
//   vec3(1.681364377589461, 1.4741145918052656, 0.4472135954999579),
//   vec3(-1.2795157692199817, 2.088741103228784, 0.4082482904638631),
//   vec3(-2.4575847530631187, -0.9799373355024756, 0.3779644730092272),
//   vec3(0.5874641440200847, -2.7667464429345077, 0.35355339059327373),
//   vec3(2.997715703369726, 0.11704939884745152, 0.3333333333333333),
//   vec3(0.41360842451688395, 3.1351121305574803, 0.31622776601683794),
//   vec3(-3.167149933769243, 0.9844599011770256, 0.30151134457776363),
//   vec3(-1.5736713846521535, -3.0860263079123245, 0.2886751345948129),
//   vec3(2.888202648340422, -2.1583061557896213, 0.2773500981126146),
//   vec3(2.7150778983300325, 2.5745586041105715, 0.2672612419124244),
//   vec3(-2.1504069972377464, 3.2211410627650165, 0.2581988897471611),
//   vec3(-3.6548858794907493, -1.6253643308191343, 0.25),
//   vec3(1.0130775986052671, -3.9967078676335834, 0.24253562503633297),
//   vec3(4.229723673607257, 0.33081361055181563, 0.23570226039551587),
//   vec3(0.40107790291173834, 4.340407413572593, 0.22941573387056174),
//   vec3(-4.319124570236028, 1.159811599693438, 0.22360679774997896),
//   vec3(-1.9209044802827355, -4.160543952132907, 0.2182178902359924),
//   vec3(3.8639122286635708, -2.6589814382925123, 0.21320071635561041),
//   vec3(3.3486228404946234, 3.4331800232609, 0.20851441405707477),
//   vec3(-2.8769733643574344, 3.9652268864187157, 0.20412414523193154)
// };
//
// const float DIM_CUTOFF = 0.35;
// const float BRIGHT_CUTOFF = 0.65;
//
// // --- SHADER FUNCTIONS ---
// float ease(float x) {
//     return sqrt(1.0 - pow(x - 1.0, 2.0));
// }
//
// float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b) {
//     vec2 d = abs(p - xy) - b;
//     return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
// }
//
// float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
//     vec2 e = b - a;
//     vec2 w = p - a;
//     vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
//     float segd = dot(p - proj, p - proj);
//     d = min(d, segd);
//
//     float c0 = step(0.0, p.y - a.y);
//     float c1 = 1.0 - step(0.0, p.y - b.y);
//     float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
//     float allCond = c0 * c1 * c2;
//     float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
//     float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
//     s *= flip;
//     return d;
// }
//
// float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
//     float s = 1.0;
//     float d = dot(p - v0, p - v0);
//     d = seg(p, v0, v3, s, d);
//     d = seg(p, v1, v0, s, d);
//     d = seg(p, v2, v1, s, d);
//     d = seg(p, v3, v2, s, d);
//     return s * sqrt(d);
// }
//
// vec2 normalizeCoords(vec2 value, float isPosition) {
//     return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
// }
//
// float antialising(float distance) {
//     return 1. - smoothstep(0., normalizeCoords(vec2(BLUR, BLUR), 0.).x, distance);
// }
//
// float determineIfTopRightIsLeading(vec2 a, vec2 b) {
//     float condition1 = step(b.x, a.x) * step(a.y, b.y);
//     float condition2 = step(a.x, b.x) * step(b.y, a.y);
//     return 1.0 - max(condition1, condition2);
// }
//
// // --- MAIN EXECUTION ---
// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     vec2 uv = fragCoord.xy / iResolution.xy;
//
//     // 1. STABLE BASE COLOR (Geen Chromatic Aberration / Shaking)
//     vec4 baseColor = texture(iChannel0, uv);
//     vec4 source = toOklab(baseColor);
//     vec4 dest = source;
//
//     // 2. SUBTLE GLOW / BLOOM IN OKLAB SPACE
//     if (source.x > DIM_CUTOFF) {
//         dest.x *= 1.25; // Schone helderheidsboost
//     } else {
//         vec2 stepSize = vec2(1.414) / iResolution.xy;
//         vec3 glow = vec3(0.0);
//         for (int i = 0; i < 24; i++) {
//             vec3 s = samples[i];
//             float weight = s.z;
//             vec4 c = toOklab(texture(iChannel0, uv + s.xy * stepSize));
//             if (c.x > DIM_CUTOFF) {
//                 glow.yz += c.yz * weight * 0.20; // Subtiele kleurgloed
//                 if (c.x <= BRIGHT_CUTOFF) {
//                     glow.x += c.x * weight * 0.04;
//                 } else {
//                     glow.x += c.x * weight * 0.08;
//                 }
//             }
//         }
//         dest.xyz += glow.xyz;
//     }
//
//     vec4 baseScreenColor = toRgb(dest);
//     vec4 newColor = baseScreenColor;
//
//     // 3. YOUR SMEAR CURSOR LOGIC (Drawn stably over the text)
//     vec2 vu = normalizeCoords(fragCoord, 1.);
//     vec2 offsetFactor = vec2(-.5, 0.5);
//
//     vec4 currentCursor = vec4(normalizeCoords(iCurrentCursor.xy, 1.), normalizeCoords(iCurrentCursor.zw, 0.));
//     vec4 previousCursor = vec4(normalizeCoords(iPreviousCursor.xy, 1.), normalizeCoords(iPreviousCursor.zw, 0.));
//
//     vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
//     vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);
//
//     vec2 delta = centerCP - centerCC;
//     float lineLength = length(delta);
//
//     float sdfCurrentCursor = getSdfRectangle(vu, centerCC, currentCursor.zw * 0.5);
//     float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE;
//     float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
//
//     if (lineLength > minDist) {
//         float head_eased = 0.0;
//         float tail_eased = 0.0;
//
//         float tail_delay_factor = MAX_TRAIL_LENGTH / lineLength;
//         float isLongMove = step(MAX_TRAIL_LENGTH, lineLength);
//
//         float head_eased_short = ease(progress);
//         float tail_eased_short = ease(smoothstep(tail_delay_factor, 1.0, progress));
//         float head_eased_long = 1.0;
//         float tail_eased_long = ease(progress);
//
//         head_eased = mix(head_eased_long, head_eased_short, isLongMove);
//         tail_eased = mix(tail_eased_long, tail_eased_short, isLongMove);
//
//         vec2 delta_abs = abs(centerCC - centerCP); 
//         float threshold = 0.001;
//         float isHorizontal = step(delta_abs.y, threshold);
//         float isVertical = step(delta_abs.x, threshold);
//         float isStraightMove = max(isHorizontal, isVertical);
//
//         // Parallelogram (Diagonal)
//         vec2 head_pos_tl = mix(previousCursor.xy, currentCursor.xy, head_eased);
//         vec2 tail_pos_tl = mix(previousCursor.xy, currentCursor.xy, tail_eased);
//
//         float isTopRightLeading = determineIfTopRightIsLeading(currentCursor.xy, previousCursor.xy);
//         float isBottomLeftLeading = 1.0 - isTopRightLeading;
//
//         vec2 v0 = vec2(head_pos_tl.x + currentCursor.z * isTopRightLeading, head_pos_tl.y - currentCursor.w);
//         vec2 v1 = vec2(head_pos_tl.x + currentCursor.z * isBottomLeftLeading, head_pos_tl.y);
//         vec2 v2 = vec2(tail_pos_tl.x + currentCursor.z * isBottomLeftLeading, tail_pos_tl.y);
//         vec2 v3 = vec2(tail_pos_tl.x + currentCursor.z * isTopRightLeading, tail_pos_tl.y - previousCursor.w);
//
//         float sdfTrail_diag = getSdfParallelogram(vu, v0, v1, v2, v3);
//
//         // Rectangle (Straight)
//         vec2 head_center = mix(centerCP, centerCC, head_eased);
//         vec2 tail_center = mix(centerCP, centerCC, tail_eased);
//
//         vec2 min_center = min(head_center, tail_center);
//         vec2 max_center = max(head_center, tail_center);
//
//         vec2 box_size = (max_center - min_center) + currentCursor.zw;
//         vec2 box_center = (min_center + max_center) * 0.5;
//
//         float sdfTrail_rect = getSdfRectangle(vu, box_center, box_size * 0.5);
//
//         // Combine shapes
//         float sdfTrail = mix(sdfTrail_diag, sdfTrail_rect, isStraightMove);
//
//         vec4 TRAIL_COLOR = vec4(sRGBToLinear(iCurrentCursorColor.rgb), iCurrentCursorColor.a);
//         float trailAlpha = antialising(sdfTrail);
//         newColor = mix(newColor, TRAIL_COLOR, trailAlpha);
//
//         // Punch hole for crisp look
//         newColor = mix(newColor, baseScreenColor, step(sdfCurrentCursor, 0.));
//     }
//
//     fragColor = newColor;
// }

// // ============================================================================
// // COMBINED GHOSTTY SHADER: YOUR PARALLELOGRAM CURSOR + GOLDEN SPIRAL BLOOM
// // ============================================================================
//
// // --- HELPER FUNCTIONS & COLOR SPACES ---
//
// // sRGB -> Linear conversion (needed for correct cursor brightness)
// vec3 sRGBToLinear(vec3 c) {
//     return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
// }
//
// // Luminance function from your bloom code
// float lum(vec4 c) {
//     return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
// }
//
// // --- CONFIGURATION (YOUR CURSOR CONFIG) ---
// const float DURATION = 0.09; 
// const float MAX_TRAIL_LENGTH = 0.2;
// const float THRESHOLD_MIN_DISTANCE = 1.5; 
// const float BLUR = 2.0; 
// const float PI = 3.14159265359;
//
// // --- GOLDEN SPIRAL SAMPLES FOR BLOOM ---
// const vec3[24] samples = {
//   vec3(0.1693761725038636, 0.9855514761735895, 1),
//   vec3(-1.333070830962943, 0.4721463328627773, 0.7071067811865475),
//   vec3(-0.8464394909806497, -1.51113870578065, 0.5773502691896258),
//   vec3(1.554155680728463, -1.2588090085709776, 0.5),
//   vec3(1.681364377589461, 1.4741145918052656, 0.4472135954999579),
//   vec3(-1.2795157692199817, 2.088741103228784, 0.4082482904638631),
//   vec3(-2.4575847530631187, -0.9799373355024756, 0.3779644730092272),
//   vec3(0.5874641440200847, -2.7667464429345077, 0.35355339059327373),
//   vec3(2.997715703369726, 0.11704939884745152, 0.3333333333333333),
//   vec3(0.41360842451688395, 3.1351121305574803, 0.31622776601683794),
//   vec3(-3.167149933769243, 0.9844599011770256, 0.30151134457776363),
//   vec3(-1.5736713846521535, -3.0860263079123245, 0.2886751345948129),
//   vec3(2.888202648340422, -2.1583061557896213, 0.2773500981126146),
//   vec3(2.7150778983300325, 2.5745586041105715, 0.2672612419124244),
//   vec3(-2.1504069972377464, 3.2211410627650165, 0.2581988897471611),
//   vec3(-3.6548858794907493, -1.6253643308191343, 0.25),
//   vec3(1.0130775986052671, -3.9967078676335834, 0.24253562503633297),
//   vec3(4.229723673607257, 0.33081361055181563, 0.23570226039551587),
//   vec3(0.40107790291173834, 4.340407413572593, 0.22941573387056174),
//   vec3(-4.319124570236028, 1.159811599693438, 0.22360679774997896),
//   vec3(-1.9209044802827355, -4.160543952132907, 0.2182178902359924),
//   vec3(3.8639122286635708, -2.6589814382925123, 0.21320071635561041),
//   vec3(3.3486228404946234, 3.4331800232609, 0.20851441405707477),
//   vec3(-2.8769733643574344, 3.9652268864187157, 0.20412414523193154)
// };
//
// // --- CURSOR SDF FUNCTIONS ---
// float ease(float x) {
//     return sqrt(1.0 - pow(x - 1.0, 2.0));
// }
//
// float getSdfRectangle(vec2 p, vec2 xy, vec2 b) {
//     vec2 d = abs(p - xy) - b;
//     return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
// }
//
// float seg(vec2 p, vec2 a, vec2 b, inout float s, float d) {
//     vec2 e = b - a;
//     vec2 w = p - a;
//     vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
//     float segd = dot(p - proj, p - proj);
//     d = min(d, segd);
//
//     float c0 = step(0.0, p.y - a.y);
//     float c1 = 1.0 - step(0.0, p.y - b.y);
//     float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
//     float allCond = c0 * c1 * c2;
//     float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
//     float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
//     s *= flip;
//     return d;
// }
//
// float getSdfParallelogram(vec2 p, vec2 v0, vec2 v1, vec2 v2, vec2 v3) {
//     float s = 1.0;
//     float d = dot(p - v0, p - v0);
//     d = seg(p, v0, v3, s, d);
//     d = seg(p, v1, v0, s, d);
//     d = seg(p, v2, v1, s, d);
//     d = seg(p, v3, v2, s, d);
//     return s * sqrt(d);
// }
//
// vec2 normalizeCoords(vec2 value, float isPosition) {
//     return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
// }
//
// float antialising(float distance) {
//     return 1. - smoothstep(0., normalizeCoords(vec2(BLUR, BLUR), 0.).x, distance);
// }
//
// float determineIfTopRightIsLeading(vec2 a, vec2 b) {
//     float condition1 = step(b.x, a.x) * step(a.y, b.y);
//     float condition2 = step(a.x, b.x) * step(b.y, a.y);
//     return 1.0 - max(condition1, condition2);
// }
//
// // --- MAIN EXECUTION ---
// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     vec2 uv = fragCoord.xy / iResolution.xy;
//
//     // 1. ORIGINAL SPIRAL BLOOM LOGIC (Applied to terminal background)
//     vec4 baseColor = texture(iChannel0, uv);
//     vec2 stepSize = vec2(1.414) / iResolution.xy;
//
//     for (int i = 0; i < 24; i++) {
//         vec3 s = samples[i];
//         vec4 c = texture(iChannel0, uv + s.xy * stepSize);
//         float l = lum(c);
//         if (l > 0.2) {
//             baseColor += l * s.z * c * 0.2;
//         }
//     }
//
//     vec4 newColor = baseColor;
//
//     // 2. YOUR SMEAR CURSOR LOGIC (Drawn on top)
//     vec2 vu = normalizeCoords(fragCoord, 1.);
//     vec2 offsetFactor = vec2(-.5, 0.5);
//
//     vec4 currentCursor = vec4(normalizeCoords(iCurrentCursor.xy, 1.), normalizeCoords(iCurrentCursor.zw, 0.));
//     vec4 previousCursor = vec4(normalizeCoords(iPreviousCursor.xy, 1.), normalizeCoords(iPreviousCursor.zw, 0.));
//
//     vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
//     vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);
//
//     vec2 delta = centerCP - centerCC;
//     float lineLength = length(delta);
//
//     float sdfCurrentCursor = getSdfRectangle(vu, centerCC, currentCursor.zw * 0.5);
//     float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE;
//     float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
//
//     if (lineLength > minDist) {
//         float head_eased = 0.0;
//         float tail_eased = 0.0;
//
//         float tail_delay_factor = MAX_TRAIL_LENGTH / lineLength;
//         float isLongMove = step(MAX_TRAIL_LENGTH, lineLength);
//
//         float head_eased_short = ease(progress);
//         float tail_eased_short = ease(smoothstep(tail_delay_factor, 1.0, progress));
//         float head_eased_long = 1.0;
//         float tail_eased_long = ease(progress);
//
//         head_eased = mix(head_eased_long, head_eased_short, isLongMove);
//         tail_eased = mix(tail_eased_long, tail_eased_short, isLongMove);
//
//         vec2 delta_abs = abs(centerCC - centerCP); 
//         float threshold = 0.001;
//         float isHorizontal = step(delta_abs.y, threshold);
//         float isVertical = step(delta_abs.x, threshold);
//         float isStraightMove = max(isHorizontal, isVertical);
//
//         // Parallelogram Shape (Diagonal Move)
//         vec2 head_pos_tl = mix(previousCursor.xy, currentCursor.xy, head_eased);
//         vec2 tail_pos_tl = mix(previousCursor.xy, currentCursor.xy, tail_eased);
//
//         float isTopRightLeading = determineIfTopRightIsLeading(currentCursor.xy, previousCursor.xy);
//         float isBottomLeftLeading = 1.0 - isTopRightLeading;
//
//         vec2 v0 = vec2(head_pos_tl.x + currentCursor.z * isTopRightLeading, head_pos_tl.y - currentCursor.w);
//         vec2 v1 = vec2(head_pos_tl.x + currentCursor.z * isBottomLeftLeading, head_pos_tl.y);
//         vec2 v2 = vec2(tail_pos_tl.x + currentCursor.z * isBottomLeftLeading, tail_pos_tl.y);
//         vec2 v3 = vec2(tail_pos_tl.x + currentCursor.z * isTopRightLeading, tail_pos_tl.y - previousCursor.w);
//
//         float sdfTrail_diag = getSdfParallelogram(vu, v0, v1, v2, v3);
//
//         // Rectangle Shape (Straight Move)
//         vec2 head_center = mix(centerCP, centerCC, head_eased);
//         vec2 tail_center = mix(centerCP, centerCC, tail_eased);
//
//         vec2 min_center = min(head_center, tail_center);
//         vec2 max_center = max(head_center, tail_center);
//
//         vec2 box_size = (max_center - min_center) + currentCursor.zw;
//         vec2 box_center = (min_center + max_center) * 0.5;
//
//         float sdfTrail_rect = getSdfRectangle(vu, box_center, box_size * 0.5);
//
//         // Interpolate between the two trail types
//         float sdfTrail = mix(sdfTrail_diag, sdfTrail_rect, isStraightMove);
//
//         vec4 TRAIL_COLOR = vec4(sRGBToLinear(iCurrentCursorColor.rgb), iCurrentCursorColor.a);
//         float trailAlpha = antialising(sdfTrail);
//         newColor = mix(newColor, TRAIL_COLOR, trailAlpha);
//
//         // Punch hole so current cursor is cleanly drawn
//         newColor = mix(newColor, baseColor, step(sdfCurrentCursor, 0.));
//     }
//
//     fragColor = newColor;
// }



// ============================================================================
// GHOSTTY SHADER: SMEAR CURSOR WITH STABLE OKLAB COLORS & BLOOM
// ============================================================================

// --- HELPER FUNCTIONS & COLOR SPACES ---

// sRGB linear -> nonlinear transform
float f(float x) {
    if (x >= 0.0031308) {
        return 1.055 * pow(x, 1.0 / 2.4) - 0.055;
    } else {
        return 12.92 * x;
    }
}

float f_inv(float x) {
    if (x >= 0.04045) {
        return pow((x + 0.055) / 1.055, 2.4);
    } else {
        return x / 12.92;
    }
}

// Oklab <-> linear sRGB conversions
vec4 toOklab(vec4 rgb) {
    vec3 c = vec3(f_inv(rgb.r), f_inv(rgb.g), f_inv(rgb.b));
    float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
    float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
    float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
    float l_ = pow(l, 1.0 / 3.0);
    float m_ = pow(m, 1.0 / 3.0);
    float s_ = pow(s, 1.0 / 3.0);
    return vec4(
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
        rgb.a
    );
}

vec4 toRgb(vec4 oklab) {
    vec3 c = oklab.rgb;
    float l_ = c.r + 0.3963377774 * c.g + 0.2158037573 * c.b;
    float m_ = c.r - 0.1055613458 * c.g - 0.0638541728 * c.b;
    float s_ = c.r - 0.0894841775 * c.g - 1.2914855480 * c.b;
    float l = l_ * l_ * l_;
    float m = m_ * m_ * m_;
    float s = s_ * s_ * s_;
    vec3 linear_srgb = vec3(
         4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    );
    return vec4(
        clamp(f(linear_srgb.r), 0.0, 1.0),
        clamp(f(linear_srgb.g), 0.0, 1.0),
        clamp(f(linear_srgb.b), 0.0, 1.0),
        oklab.a
    );
}

// --- CONFIGURATION (STABLE GLOW / BLOOM SAMPLES) ---
const vec3[24] samples = {
  vec3(0.1693761725038636, 0.9855514761735895, 1),
  vec3(-1.333070830962943, 0.4721463328627773, 0.7071067811865475),
  vec3(-0.8464394909806497, -1.51113870578065, 0.5773502691896258),
  vec3(1.554155680728463, -1.2588090085709776, 0.5),
  vec3(1.681364377589461, 1.4741145918052656, 0.4472135954999579),
  vec3(-1.2795157692199817, 2.088741103228784, 0.4082482904638631),
  vec3(-2.4575847530631187, -0.9799373355024756, 0.3779644730092272),
  vec3(0.5874641440200847, -2.7667464429345077, 0.35355339059327373),
  vec3(2.997715703369726, 0.11704939884745152, 0.3333333333333333),
  vec3(0.41360842451688395, 3.1351121305574803, 0.31622776601683794),
  vec3(-3.167149933769243, 0.9844599011770256, 0.30151134457776363),
  vec3(-1.5736713846521535, -3.0860263079123245, 0.2886751345948129),
  vec3(2.888202648340422, -2.1583061557896213, 0.2773500981126146),
  vec3(2.7150778983300325, 2.5745586041105715, 0.2672612419124244),
  vec3(-2.1504069972377464, 3.2211410627650165, 0.2581988897471611),
  vec3(-3.6548858794907493, -1.6253643308191343, 0.25),
  vec3(1.0130775986052671, -3.9967078676335834, 0.24253562503633297),
  vec3(4.229723673607257, 0.33081361055181563, 0.23570226039551587),
  vec3(0.40107790291173834, 4.340407413572593, 0.22941573387056174),
  vec3(-4.319124570236028, 1.159811599693438, 0.22360679774997896),
  vec3(-1.9209044802827355, -4.160543952132907, 0.2182178902359924),
  vec3(3.8639122286635708, -2.6589814382925123, 0.21320071635561041),
  vec3(3.3486228404946234, 3.4331800232609, 0.20851441405707477),
  vec3(-2.8769733643574344, 3.9652268864187157, 0.20412414523193154)
};

const float DIM_CUTOFF = 0.35;
const float BRIGHT_CUTOFF = 0.65;

// --- SHADER FUNCTIONS ---
float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b) {
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);
    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);
    return s * sqrt(d);
}

vec2 norm(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance) {
    return 1. - smoothstep(0., norm(vec2(2., 2.), 0.).x, distance);
}

float determineStartVertexFactor(vec2 c, vec2 p) {
    float condition1 = step(p.x, c.x) * step(c.y, p.y);
    float condition2 = step(c.x, p.x) * step(p.y, c.y);
    return 1.0 - max(condition1, condition2);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}

float ease(float x) {
    return pow(1.0 - x, 3.0);
}

vec4 saturate(vec4 color, float factor) {
    float gray = dot(color, vec4(0.299, 0.587, 0.114, 0.));
    return mix(vec4(gray), color, factor);
}

const vec4 TRAIL_COLOR = vec4(1.0, 0.725, 0.161, 1.0);
const vec4 TRAIL_COLOR_ACCENT = vec4(1.0, 0., 0., 1.0);
const float DURATION = 0.3;

// --- MAIN EXECUTION ---
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 baseColor = texture(iChannel0, uv);
    
    // 1. CURSOR LOGIC & TRAIL CALCULATIONS
    vec2 vu = norm(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    vec4 currentCursor = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));

    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);
    
    float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor = 1.0 - vertexFactor;

    vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
    vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

    float sdfCurrentCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
    float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

    float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    float easedProgress = ease(progress);
    float lineLength = distance(centerCC, centerCP);

    float mod = .007;
    
    // Render de initiële trail / cursor-blaze
    vec4 trail = mix(saturate(TRAIL_COLOR_ACCENT, 1.5), baseColor, 1. - smoothstep(0., sdfTrail + mod, 0.007));
    trail = mix(saturate(TRAIL_COLOR, 1.5), trail, 1. - smoothstep(0., sdfTrail + mod, 0.006));
    trail = mix(trail, saturate(TRAIL_COLOR, 1.5), step(sdfTrail + mod, 0.));
    
    trail = mix(saturate(TRAIL_COLOR_ACCENT, 1.5), trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
    trail = mix(saturate(TRAIL_COLOR, 1.5), trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
    
    vec4 sceneColor = mix(trail, baseColor, 1. - smoothstep(0., sdfCurrentCursor, easedProgress * lineLength));

    // 2. CONVERT WHOLE SCENE TO OKLAB & APPLY STABLE BLOOM
    vec4 source = toOklab(sceneColor);
    vec4 dest = source;

    if (source.x > DIM_CUTOFF) {
        dest.x *= 1.15; // Schone helderheidsboost voor oplichtende elementen
    } else {
        vec2 stepSize = vec2(1.414) / iResolution.xy;
        vec3 glow = vec3(0.0);
        
        for (int i = 0; i < 24; i++) {
            vec3 s = samples[i];
            float weight = s.z;
            
            // Sample de omliggende scene-pixels in Oklab space
            // Hierdoor krijgt ook jouw vuurspoor een zachte, warme gloed over de letters heen
            vec4 c = toOklab(texture(iChannel0, uv + s.xy * stepSize));
            
            if (c.x > DIM_CUTOFF) {
                glow.yz += c.yz * weight * 0.20; // Prachtige kleurgloed
                if (c.x <= BRIGHT_CUTOFF) {
                    glow.x += c.x * weight * 0.04;
                } else {
                    glow.x += c.x * weight * 0.08;
                }
            }
        }
        dest.xyz += glow.xyz;
    }

    // 3. FINAL OUTPUT
    fragColor = toRgb(dest);
}



//
// float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
// {
//     vec2 d = abs(p - xy) - b;
//     return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
// }
//
// // Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// // Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching
//
// float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
//     vec2 e = b - a;
//     vec2 w = p - a;
//     vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
//     float segd = dot(p - proj, p - proj);
//     d = min(d, segd);
//
//     float c0 = step(0.0, p.y - a.y);
//     float c1 = 1.0 - step(0.0, p.y - b.y);
//     float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
//     float allCond = c0 * c1 * c2;
//     float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
//     float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
//     s *= flip;
//     return d;
// }
//
// float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
//     float s = 1.0;
//     float d = dot(p - v0, p - v0);
//
//     d = seg(p, v0, v3, s, d);
//     d = seg(p, v1, v0, s, d);
//     d = seg(p, v2, v1, s, d);
//     d = seg(p, v3, v2, s, d);
//
//     return s * sqrt(d);
// }
//
// vec2 norm(vec2 value, float isPosition) {
//     return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
// }
//
// float antialising(float distance) {
//     return 1. - smoothstep(0., norm(vec2(2., 2.), 0.).x, distance);
// }
//
// float determineStartVertexFactor(vec2 c, vec2 p) {
//     // Conditions using step
//     float condition1 = step(p.x, c.x) * step(c.y, p.y); // c.x < p.x && c.y > p.y
//     float condition2 = step(c.x, p.x) * step(p.y, c.y); // c.x > p.x && c.y < p.y
//
//     // If neither condition is met, return 1 (else case)
//     return 1.0 - max(condition1, condition2);
// }
//
// vec2 getRectangleCenter(vec4 rectangle) {
//     return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
// }
// float ease(float x) {
//     return pow(1.0 - x, 3.0);
// }
//
// vec4 saturate(vec4 color, float factor) {
//     float gray = dot(color, vec4(0.299, 0.587, 0.114, 0.)); // luminance
//     return mix(vec4(gray), color, factor);
// }
// const vec4 TRAIL_COLOR = vec4(1.0, 0.725, 0.161, 1.0);
// const vec4 TRAIL_COLOR_ACCENT = vec4(1.0, 0., 0., 1.0);
// const float DURATION = 0.3; //IN SECONDS
//
// void mainImage(out vec4 fragColor, in vec2 fragCoord)
// {
//     fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
//     // Normalization for fragCoord to a space of -1 to 1;
//     vec2 vu = norm(fragCoord, 1.);
//     vec2 offsetFactor = vec2(-.5, 0.5);
//
//     // Normalization for cursor position and size;
//     // cursor xy has the postion in a space of -1 to 1;
//     // zw has the width and height
//     vec4 currentCursor = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
//     vec4 previousCursor = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));
//
//     vec2 centerCC = getRectangleCenter(currentCursor);
//     vec2 centerCP = getRectangleCenter(previousCursor);
//     // When drawing a parellelogram between cursors for the trail i need to determine where to start at the top-left or top-right vertex of the cursor
//     float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
//     float invertedVertexFactor = 1.0 - vertexFactor;
//
//     // Set every vertex of my parellogram
//     vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
//     vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
//     vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
//     vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);
//
//     float sdfCurrentCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
//     float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);
//
//     float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
//     float easedProgress = ease(progress);
//     // Distance between cursors determine the total length of the parallelogram;
//     float lineLength = distance(centerCC, centerCP);
//
//     float mod = .007;
//     //trailblaze
//     // HACK: Using the saturate function because I currently don't know how to blend colors without losing saturation.
//     vec4 trail = mix(saturate(TRAIL_COLOR_ACCENT, 1.5), fragColor, 1. - smoothstep(0., sdfTrail + mod, 0.007));
//     trail = mix(saturate(TRAIL_COLOR, 1.5), trail, 1. - smoothstep(0., sdfTrail + mod, 0.006));
//     trail = mix(trail, saturate(TRAIL_COLOR, 1.5), step(sdfTrail + mod, 0.));
//     //cursorblaze
//     trail = mix(saturate(TRAIL_COLOR_ACCENT, 1.5), trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
//     trail = mix(saturate(TRAIL_COLOR, 1.5), trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
//     fragColor = mix(trail, fragColor, 1. - smoothstep(0., sdfCurrentCursor, easedProgress * lineLength));
// }
