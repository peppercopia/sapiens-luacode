
layout(binding = 1) uniform sampler2D texMap[32];

layout(location = 0) in vec4 fragColor;
layout(location = 1) in vec2 fragTexCoord;
layout(location = 2) in vec4 fragLayer;

layout(location = 0) out vec4 outColor;

void main() {
    int layer = int(fragLayer.x);
    layer = clamp(layer,0,31);
    vec4 tex = texture(texMap[layer], fragTexCoord);
    outColor = vec4(tex.rgb, 1.0) * fragColor;
}