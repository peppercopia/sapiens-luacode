

#include "lightingCommon.frag"

layout(binding = 2) uniform UniformBufferObject {
    int outputType;
} ubo;

layout(binding = 3) uniform sampler2D starTexture;

layout(location = 0) in float outColor;

layout(location = 0) out vec4 data;


void main()
{
    
    float tex = (texture(starTexture, gl_PointCoord) * outColor).a * 1.0;

    tex = hdrConst(vec3(tex)).r;
    data = vec4(vec3(1.0), tex);
}
