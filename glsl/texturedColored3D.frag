
layout(binding = 1) uniform sampler3D texMap;

layout(location = 0) in vec4 fragColor;
layout(location = 1) in vec3 fragTexCoord;

layout(location = 0) out vec4 outColor;

void main() {
    vec4 tex = texture(texMap, fragTexCoord);
    outColor = vec4(tex.rgb, 1.0) * fragColor;
}