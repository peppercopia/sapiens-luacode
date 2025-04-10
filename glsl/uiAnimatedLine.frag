
#include "uiRenderCommon.frag"

layout(binding = 2) uniform samplerCube cubeMapTex;
layout(binding = 3) uniform sampler2D brdfTex;
layout(binding = 4) uniform sampler2D fontTex;
layout(binding = 5) uniform sampler2D fontNormalTex;

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


void main(void)
{
    vec3 normalTex = normalize((texture(fontNormalTex, outTex).rgb - vec3(0.5,0.5,0.5)) * vec3(1.0,1.0,0.5));

    vec3 normalToUse = (outNormalMatrix * vec4(normalTex, 1.0)).xyz;

    vec4 tex = texture(fontTex, outTex);

    float baseNDotL = dot( normalToUse, sunPos );

    float NdotL = clamp(baseNDotL, 0.0, 1.0);

    vec3 V = normalize(outView);

    vec3 diffuseColor = textureLod( cubeMapTex, normalToUse * vec3(1,-1,1), PBR_MIP_LEVELS - 1 ).rgb;

    vec3 diffuseLit = outColor.xyz * (vec3(NdotL) + diffuseColor);

    diffuseLit = diffuseLit * (1.0 - outMaterial.y);

    vec3 specularColor		= mix( vec3( 0.04 ), outColor.xyz, outMaterial.y );
    vec3 lookup				= -reflect( V, normalToUse );
    float mip				= PBR_MIP_LEVELS - 1 + log2(outMaterial.x);
    vec3 sampledColor		= textureLod( cubeMapTex, lookup * vec3(1,-1,1), mip ).rgb;

    float NoV				= saturate( dot( normalToUse, V ) );
    vec3 EnvBRDF = texture( brdfTex, vec2(outMaterial.x, NoV)).rgb;
    vec3 reflectance		= (specularColor * EnvBRDF.x + EnvBRDF.y);
    
    vec3 lightReflect = vec3(1.0,1.0,1.0) * uiLightSpecular(normalToUse, V, sunPos, outMaterial.x);
  //  vec3 litColor = diffuseLit + (sampledColor) * reflectance;

    vec3 litColor = diffuseLit + (sampledColor + lightReflect) * reflectance * reflectanceMultiplier;

    float animation = min(smoothstep(0.9 - 1.85 * outShaderUniformA.y,0.95 - 1.85 * outShaderUniformA.y, sin(outTimer.x * 5.0 - outTex.x * outShaderUniformA.x * 0.2)) + 0.5, 1.0);
    

    vec4 result = vec4(uiHDR(litColor), 1.0);

    data = result * tex * vec4(1,1,1,outColor.a) * animation;
    
}
