
#define POISSON_SCALE 0.00048828125 * 0.75
#define SHADOW_BIAS -0.000001

vec2 poissonDisk[16] = vec2[](
                              vec2( -0.94201624, -0.39906216 ) * POISSON_SCALE,
                              vec2( 0.94558609, -0.76890725 ) * POISSON_SCALE,
                              vec2( -0.094184101, -0.92938870 ) * POISSON_SCALE,
                              vec2( 0.34495938, 0.29387760 ) * POISSON_SCALE,
                              vec2( -0.91588581, 0.45771432 ) * POISSON_SCALE,
                              vec2( -0.81544232, -0.87912464 ) * POISSON_SCALE,
                              vec2( -0.38277543, 0.27676845 ) * POISSON_SCALE,
                              vec2( 0.97484398, 0.75648379 ) * POISSON_SCALE,
                              vec2( 0.44323325, -0.97511554 ) * POISSON_SCALE,
                              vec2( 0.53742981, -0.47373420 ) * POISSON_SCALE,
                              vec2( -0.26496911, -0.41893023 ) * POISSON_SCALE, 
                              vec2( 0.79197514, 0.19090188 ) * POISSON_SCALE, 
                              vec2( -0.24188840, 0.99706507 ) * POISSON_SCALE, 
                              vec2( -0.81409955, 0.91437590 ) * POISSON_SCALE, 
                              vec2( 0.19984126, 0.78641367 ) * POISSON_SCALE, 
                              vec2( 0.14383161, -0.14100790 ) * POISSON_SCALE 
                              );

#define saturate(x) clamp(x, 0.0, 1.0)

#define SHADOW_WEIGHT 0.0625 //1.0/16

float sampleShadowMap(sampler2DShadow shadowTex, vec4 shadowCoord, float bias)
{
    float shadow=16.0;
    float shadowZW = (shadowCoord.z - (SHADOW_BIAS * bias))/shadowCoord.w;

    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[0], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[1], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[2], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[3], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[4], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[5], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[6], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[7], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[8], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[9], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[10], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[11], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[12], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[13], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[14], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[15], shadowZW));
    
    return (shadow * 0.0625);
}


float sampleShadowMapLow(sampler2DShadow shadowTex, vec4 shadowCoord, float bias)
{
    float shadowZW = (shadowCoord.z - (SHADOW_BIAS * bias))/shadowCoord.w;
    //return 1.0 - texture(shadowTex, vec3(shadowCoord.xy, shadowZW));

   
    float shadow=4.0;
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[0], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[1], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[2], shadowZW));
    shadow -= texture(shadowTex, vec3(shadowCoord.xy + poissonDisk[3], shadowZW));
    
    return (shadow * 0.25);
}

float getShadowVisibility(float shadowBaseVisibility, vec4 outShadowCoords[4], sampler2DShadow shadowTexA,sampler2DShadow shadowTexB,sampler2DShadow shadowTexC,sampler2DShadow shadowTexD)
{

    if(shadowBaseVisibility > 0.0)
    {
        float shadowVisibility = shadowBaseVisibility;

        float edgeDistanceX = min(-(outShadowCoords[0].x - 1.0), outShadowCoords[0].x);
        float edgeDistanceY = min(-(outShadowCoords[0].y - 1.0), outShadowCoords[0].y);
        float shadowEdgeDistance = min(edgeDistanceX, edgeDistanceY);
            
        if(shadowEdgeDistance > 0.0)
        {
            float shadowMapValue = sampleShadowMap(shadowTexA, outShadowCoords[0], 4.0);
            shadowVisibility = shadowVisibility * mix(shadowMapValue, 1.0, (1.0 - clamp(shadowEdgeDistance * 10.0, 0.0, 1.0)));
        }
        if(shadowEdgeDistance < 0.2)
        {
            float fadeIn = 1.0 - (max((shadowEdgeDistance - 0.1), 0.0) / 0.1);
            edgeDistanceX = min(-(outShadowCoords[1].x - 1.0), outShadowCoords[1].x);
            edgeDistanceY = min(-(outShadowCoords[1].y - 1.0), outShadowCoords[1].y);
            shadowEdgeDistance = min(edgeDistanceX, edgeDistanceY);
                
            if(shadowEdgeDistance > 0.0)
            {
                float shadowMapValue = sampleShadowMapLow(shadowTexB, outShadowCoords[1], 4.0);
                shadowMapValue = mix(1.0, shadowMapValue, fadeIn);
                shadowVisibility = shadowVisibility * mix(shadowMapValue, 1.0, (1.0 - clamp(shadowEdgeDistance * 10.0, 0.0, 1.0)));
            }

            if(shadowEdgeDistance < 0.2)
            {
                fadeIn = 1.0 - (max((shadowEdgeDistance - 0.1), 0.0) / 0.1);
                edgeDistanceX = min(-(outShadowCoords[2].x - 1.0), outShadowCoords[2].x);
                edgeDistanceY = min(-(outShadowCoords[2].y - 1.0), outShadowCoords[2].y);
                shadowEdgeDistance = min(edgeDistanceX, edgeDistanceY);
                    
                if(shadowEdgeDistance > 0.0)
                {
                    float shadowMapValue = sampleShadowMapLow(shadowTexC, outShadowCoords[2], 4.0);
                    shadowMapValue = mix(1.0, shadowMapValue, fadeIn);
                    shadowVisibility = shadowVisibility * mix(shadowMapValue, 1.0, (1.0 - clamp(shadowEdgeDistance * 10.0, 0.0, 1.0)));
                }
            }
        }

        

        edgeDistanceX = min(-(outShadowCoords[3].x - 1.0), outShadowCoords[3].x);
        edgeDistanceY = min(-(outShadowCoords[3].y - 1.0), outShadowCoords[3].y);
        shadowEdgeDistance = min(edgeDistanceX, edgeDistanceY);
            
        if(shadowEdgeDistance > 0.0)
        {
            float shadowMapValue = sampleShadowMapLow(shadowTexD, outShadowCoords[3], 32.0);
            shadowVisibility = shadowVisibility * mix(shadowMapValue, 1.0, (1.0 - clamp(shadowEdgeDistance * 10.0, 0.0, 1.0)));
        }
        return shadowVisibility;
        
    }
    return 0.0;
}