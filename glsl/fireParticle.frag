
#include "lightingCommon.frag"
#include "atmoRenderCommon.frag"

layout(binding = 3) uniform sampler2D texMap;
layout(binding = 4) uniform sampler2D transmittanceSampler;
layout(binding = 5) uniform samplerCube cubeMapTex;
layout(binding = 6) uniform sampler2D brdfTex;
layout(binding = 7) uniform sampler2DShadow shadowTextureA;
layout(binding = 8) uniform sampler2DShadow shadowTextureB;
layout(binding = 9) uniform sampler2DShadow shadowTextureC;
layout(binding = 10) uniform sampler2DShadow shadowTextureD;
layout(binding = 11) uniform sampler2DShadow rainDepthTexture;
layout(binding = 12) uniform sampler2D exposureSampler;


layout(location = 0) in vec2 texOffset;
layout(location = 1) in vec2 outTexCoord;
layout(location = 2) in vec4 lifeColorOffsetAndLifeLeftAndRandomValue;

layout(location = 0) out vec4 data;

void main()
{
    float texX = texOffset.x + sin((1.0 - lifeColorOffsetAndLifeLeftAndRandomValue.z) * (10.0 + lifeColorOffsetAndLifeLeftAndRandomValue.w * 2.0) + outTexCoord.y * 10.0 + lifeColorOffsetAndLifeLeftAndRandomValue.w * 3.141) * 0.005;
    vec4 tex = texture(texMap, outTexCoord * vec2(0.125, -0.12109375) + vec2(texX, texOffset.y));
    vec4 texLife = texture(texMap, lifeColorOffsetAndLifeLeftAndRandomValue.xy);
    vec4 combined = tex * texLife;
    
    data.a = combined.a;
    data.rgb = hdrFinal(exposureSampler, combined.rgb * combined.rgb * 0.04);
}
