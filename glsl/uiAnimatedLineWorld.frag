
#include "uiRenderCommon.frag"

layout(binding = 2) uniform samplerCube cubeMapTex;
layout(binding = 3) uniform sampler2D brdfTex;
layout(binding = 4) uniform sampler2D texA;
layout(binding = 5) uniform sampler2D texB;

#define PBR_MIP_LEVELS 7
#define saturate(x) clamp(x, 0.0, 1.0)

layout(location = 0) in vec4 outColor;
layout(location = 1) in vec2 outMaterial;
layout(location = 2) in vec3 outView;
layout(location = 3) in vec3 outNormal;
layout(location = 4) in vec2 outTex;
layout(location = 5) in mat4 outNormalMatrix;
layout(location = 9) in vec4 outTimer;
layout(location = 10) in vec4 outShaderUniformA;
layout(location = 11) in vec4 outShaderUniformB;
//in vec3 outPos;

layout(location = 0) out vec4 data;

const vec3 HIGHLIGHT_COLOR = vec3(0.3, 0.7, 1.0);


void main(void)
{

    vec3 litColor = mix(vec3(0.01,0.01,0.01), HIGHLIGHT_COLOR * 0.5, outShaderUniformA.y);

    //float animation = min(smoothstep(0.65, 0.69, sin(outTimer.y * 5.0 - outTex.x * outShaderUniformA.x * 2.0 - abs(outTex.y - 0.5) * 4.0) ), 1.0);
    vec4 texValue = texture(texA, vec2(outTimer.y * -0.5 + outTex.x * outShaderUniformA.x * 0.1, outTex.y));

    vec4 result = vec4(uiHDR(litColor * texValue.r), 1.0);

    data = result * outColor.a * vec4(texValue.a,texValue.a,texValue.a,texValue.a);
    
}
