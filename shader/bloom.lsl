number kernel = .005;
number scale = 0.5;
number thresh = 1.0;

vec4 effect(vec4 color, Image image, vec2 textureXy, vec2 screenXy) {
    vec4 sum = vec4(0);

    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            sum += Texel(image, textureXy + vec2(x, y) * kernel);
        }
    }

    sum /= 25.0;

    vec4 s = Texel(image, textureXy);

    // Use the blurred colour if it's bright enough
    if (length(sum) > thresh) {
        s += sum * scale;
    }

    return s;
}
