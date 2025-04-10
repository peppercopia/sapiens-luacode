
#include "shadowCommon.frag"
#include "lightingCommon.frag"
#include "atmoRenderCommon.frag"

layout(binding = 2) uniform sampler2D decalTexMap;

layout(location = 0) in vec3 outView;
layout(location = 1) in vec4 outTex;
layout(location = 2) in float alpha;
layout(location = 3) in vec3 outForwardNormal;

layout(location = 0) out vec4 data;

void main()
{
    vec4 tex = texture(decalTexMap, outTex.xy);
    vec3 V = normalize(outView);
    float alphaToUse = tex.r * alpha * min(((abs(dot(V,outForwardNormal))) - 0.5) * 8.0, 1.0) * smoothstep(0.01,0.11,outTex.w);
    if(alphaToUse < 0.1)
    {
        discard;
    }
	data.a = alphaToUse;
}
