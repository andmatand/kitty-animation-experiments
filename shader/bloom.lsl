number kernel = .005;
number scale = 0.5;
number thresh = 1.0;

vec4 effect(vec4 color, Image tInput, vec2 vUv, vec2 screen_coords) {
    vec4 sum = vec4(0);

    for (int j = -2; j <= 2; j++) {
        for (int i = -2; i <= 2; i++) {
            sum += Texel(tInput, vUv + vec2(i, j) * kernel);
        }
    }

    sum /= 25.0;

    vec4 s = Texel(tInput, vUv);

    // Use the blurred colour if it's bright enough
    if (length(sum) > thresh) {
        s += sum * scale;
    }

    return s;
}
