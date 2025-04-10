
#include "lightingCommon.frag"
#include "atmoRenderCommon.frag"

layout(binding = 2) uniform AtmoUniformBufferObject {
    float Rg;
    float Rt;
    float RL;
    float AVERAGE_GROUND_REFLECTANCE;

    vec4 betaRAndHR;
    vec4 betaMScaAndHM;
    vec4 betaMExAndmieG;

    int TRANSMITTANCE_W;
    int TRANSMITTANCE_H;
    int SKY_W;
    int SKY_H;
    int RES_R;
    int RES_MU;
    int RES_MU_S;
    int RES_NU;
} atmoUbo;


layout(binding = 3) uniform UniformBufferObject {
    vec4 sunPos_cloudCover;
    vec4 camPos;
    int outputType;
} skyUbo;

layout(binding = 4) uniform sampler2D transmittanceSampler;
layout(binding = 5) uniform sampler3D inscatterSampler;
layout(binding = 6) uniform sampler2D exposureSampler;

layout(location = 0) in vec3 camDir;

layout(location = 0) out vec4 data;



void main (void)	
{
    vec3 extinction;
    vec3 worldPos = skyUbo.camPos.xyz * 838860.80;
    vec3 inscatter = skyRadiance(atmoUbo.betaMExAndmieG, transmittanceSampler, inscatterSampler, worldPos, normalize(camDir), skyUbo.sunPos_cloudCover, extinction);
    
    float sunDot = max(dot(normalize(camDir), skyUbo.sunPos_cloudCover.xyz), 0.0);
    float sunDisk = smoothstep(0.99995, 0.999995, sunDot);
    float sunGlow = min(sunDot + 0.00005, 1.0);
    float glowAddition = pow(sunDot, 128.0) * 0.05 + pow(sunDot, 8.0) * 0.01;//vec3(pow(sunDot, 8.0));//pow(sunGlow, 16.0) * (0.005 + pow(sunGlow, 256.0) * 0.02 + smoothstep(0.6,1.0,pow(sunGlow, 8192.0))) * vec3(0.18, 0.15, 0.1);
    
    //vec3 sunColor = (vec3(sunBase) * vec3(1.0, 0.5, 0.1) + glowAddition) * extinction * (1.0 - skyUbo.sunPos_cloudCover.w);// * sunRadiance(transmittanceSampler, length(worldPos), dot(normalize(worldPos), skyUbo.sunPos.xyz));

    float camLength = length(worldPos);
    vec3 sunRadianceValue = sunRadiance(transmittanceSampler, camLength, dot(normalize(worldPos), skyUbo.sunPos_cloudCover.xyz));
    sunRadianceValue = mix(sunRadianceValue, vec3(0.01,0.01,0.01), clamp((length(skyUbo.camPos.xyz) - 1.1) * 10.0, 0.0, 1.0));
    
    vec3 sunColor = (sunDisk + sunRadianceValue * glowAddition * 2.0) * (1.0 - skyUbo.sunPos_cloudCover.w);
    
    vec3 outColor =  inscatter;
    
    if(skyUbo.outputType == 1) //env map
    {
        data.rgb = outColor;
    }
    else if(skyUbo.outputType != 0) // water
    {
        data.rgb = sunColor * 8.0 + outColor;
    }
    else
    {
        data.rgb = hdrFinal(exposureSampler, sunColor * 4.0 + outColor);
    }
    data.a = 1.0;
}	
