
#include "uiRenderCommon.frag"

layout(location = 0) in vec4 outColor;
layout(location = 1) in vec2 outMaterial;
layout(location = 2) in vec3 outNormal;
layout(location = 3) in vec3 rawPosAndDepth;

layout(location = 0) out vec4 data;

const vec3 sunDirection = normalize(vec3(0.0,0.0,1.0));
const vec3 sunColor = vec3(1.0,1.0,1.0) * 0.8;

void main() {
    
    if(length(rawPosAndDepth.xy) > 1.02)
    {
        discard;
    }
    vec3 normalizedNormal = normalize(outNormal);

    float NdotLToUse = clamp(dot( normalizedNormal, sunDirection ), 0.0, 1.0);

    vec3 outColorToUse = outColor.xyz * outColor.xyz;

    vec3 diffuseLit = outColorToUse.xyz * sunColor * vec3(NdotLToUse * NdotLToUse * NdotLToUse);


    diffuseLit = diffuseLit * (1.0 - outMaterial.y * 0.5);
    vec3 litColor = diffuseLit;

    litColor = mix(litColor, vec3(0.005, 0.045, 0.06) * 2.0, clamp(rawPosAndDepth.z * 10.0, 0.0,0.6));
    

    data.rgb = uiHDR(litColor);
    
    data.a = outColor.a * 0.5;
}