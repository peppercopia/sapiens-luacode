
#define STRENGTH_MULTIPLIER 0.5

vec3 rotate_vector( vec4 quat, vec3 vec )
{
    return vec + 2.0 * cross( cross( vec, quat.xyz ) + quat.w * vec, quat.xyz );
}

vec4 quatAngleAxis(float angle, vec3 axis)
{
    float s = sin(angle * 0.5);
    vec4 result = vec4(axis * s, cos(angle * 0.5));
    return result;
}


float getStrengthWave(vec2 waveOriginOffset, vec2 wavePosition2D, vec3 waveSpaceLocalPosition, float waveLengthScale, float animationTimerToUse)
{
    vec2 directionA = waveOriginOffset - wavePosition2D;
    float lengthA = length(directionA);
    float waveAngleA = sin(lengthA * waveLengthScale + animationTimerToUse);

    return (waveAngleA + 1.5) * 0.5;
}

vec3 getIndividualWave(vec2 waveOriginOffset, vec2 wavePosition2D, vec3 waveSpaceLocalPosition, float waveLengthScale, float localStrength, float constantBendStrength, float animationTimerToUse, inout vec3 waveSpaceNormal)
{
    vec2 directionA = waveOriginOffset - wavePosition2D;
    float lengthA = length(directionA);
    //float waveAngleA = ((sin(lengthA * waveLengthScale + animationTimerToUse)) * localStrength + (1.5 * unmodifiedStrength)) * STRENGTH_MULTIPLIER;//clamp(windStrength, 0.0, 2.5);
    float waveAngleA = ((sin(lengthA * waveLengthScale + animationTimerToUse)) * localStrength + (-3.5 * constantBendStrength)) * STRENGTH_MULTIPLIER;//clamp(windStrength, 0.0, 2.5);
    vec2 directionNormal = directionA / lengthA;

    vec3 waveSpaceAxis = cross(vec3(directionNormal.x, 0.0, directionNormal.y), vec3(0.0, 1.0, 0.0));
    vec4 waveQuat = quatAngleAxis(-waveAngleA, waveSpaceAxis);

    vec3 waveSpacePos = rotate_vector(waveQuat, waveSpaceLocalPosition);
    waveSpaceNormal = rotate_vector(vec4(waveQuat.xyz, -waveQuat.w), waveSpaceNormal); // reverse rotation because decal normals point out along the face.

    return waveSpacePos;
}


vec3 getWindPos(mat4 waveMatrix, vec2 windDir, vec3 pos, vec3 originLocalPos, float heightInfluence, float animationTimer, inout vec3 normal, float strength, float globalStrength)
{
    vec3 originalNormal = normal;
    vec2 wavePosition2D = (waveMatrix * vec4(originLocalPos, 1.0)).xz;
    vec3 waveSpaceLocalPosition = (waveMatrix * vec4(pos, 1.0)).xyz;
    vec3 waveSpaceNormal = (waveMatrix * vec4(normal, 1.0)).xyz;
    mat4 inverseWaveMatrix = inverse(waveMatrix);

    float strengthWave = getStrengthWave(windDir * -40.0 + vec2(-5.6, 4.0), wavePosition2D, waveSpaceLocalPosition, 200.0, animationTimer);

    vec3 waveSpacePos = getIndividualWave((windDir + vec2(0.11,0.3)) * -100.0, wavePosition2D, waveSpaceLocalPosition, 52.0 * 0.5, strength * strengthWave * heightInfluence, strength * heightInfluence, animationTimer * 3.5, waveSpaceNormal);
    waveSpacePos = getIndividualWave((windDir + vec2(-0.07,0.02)) * -109.0, wavePosition2D, waveSpacePos, 50.0 * 0.5, strength * strengthWave * heightInfluence, strength * heightInfluence, animationTimer * 2.8, waveSpaceNormal);
    
    vec3 windPos = (inverseWaveMatrix * vec4(waveSpacePos, 1.0)).xyz;

    float newPosLength = length(windPos);
    float newPosDistance = length(windPos - pos);
    windPos = windPos * (1.0 - newPosDistance / newPosLength * 0.3); //hack to try to reduce the lengthening that occurs due to rotating the extremities more

    normal = normalize(mix(originalNormal, (inverseWaveMatrix * vec4(waveSpaceNormal, 1.0)).xyz, 0.8));

    return windPos;
}

vec3 getDecalWindPos(mat4 waveMatrix, vec2 windDir, vec3 pos, vec3 originLocalPos, float heightInfluence, float animationTimer, inout vec3 normal, float localStrength, float globalStrength)
{
    vec2 wavePosition2D = (waveMatrix * vec4(originLocalPos, 1.0)).xz;
    vec3 waveSpaceLocalPosition = (waveMatrix * vec4(pos, 1.0)).xyz;
    vec3 waveSpaceNormal = (waveMatrix * vec4(normal, 1.0)).xyz;
    mat4 inverseWaveMatrix = inverse(waveMatrix);

    float strengthWave = getStrengthWave(windDir * -90.0 + vec2(-5.6, 4.0), wavePosition2D, waveSpaceLocalPosition, 70.0, animationTimer * 2.5);
    float strength = localStrength * (0.1 + globalStrength * 0.25);
    float constantBend = strength * -0.2;

    vec3 waveSpacePos = getIndividualWave((windDir + vec2(0.11,0.3)) * -100.0, wavePosition2D, waveSpaceLocalPosition, 118.0, strength * strengthWave, constantBend, animationTimer * 2.5 * 1.5, waveSpaceNormal);
    waveSpacePos = getIndividualWave((windDir + vec2(-0.07,0.02)) * -109.0, wavePosition2D, waveSpacePos,120.0, strength * strengthWave, constantBend, animationTimer * 2.8 * 1.5, waveSpaceNormal);
    waveSpacePos = getIndividualWave((windDir + vec2(0.045,-0.17)) * -127.0, wavePosition2D, waveSpacePos,90.0, strength * strengthWave, constantBend, animationTimer * 3.8 * 1.5, waveSpaceNormal);
    
    vec3 windPos = (inverseWaveMatrix * vec4(waveSpacePos, 1.0)).xyz;

    normal = (inverseWaveMatrix * vec4(waveSpaceNormal, 1.0)).xyz;

    return windPos;
}

vec3 getTerrainDecalWindPos(mat4 waveMatrix, vec2 windDir, vec3 pos, vec3 originLocalPos, float heightInfluence, float animationTimer, inout vec3 normal, float globalStrength)
{
    vec2 wavePosition2D = (waveMatrix * vec4(originLocalPos, 1.0)).xz;
    vec3 waveSpaceLocalPosition = (waveMatrix * vec4(pos, 1.0)).xyz;
    vec3 waveSpaceNormal = (waveMatrix * vec4(normal, 1.0)).xyz;
    mat4 inverseWaveMatrix = inverse(waveMatrix);

    float strengthWave = getStrengthWave(windDir * -90.0 + vec2(-5.6, 4.0), wavePosition2D, waveSpaceLocalPosition, 70.0, animationTimer * 2.5) * (4.0 + 0.3 * globalStrength) + 0.8 * globalStrength;
    float strength = 0.01 * (0.2 + globalStrength * 0.05);
    float constantBend = strength * 4.0;

    vec3 waveSpacePos = getIndividualWave((windDir + vec2(0.11,0.3)) * -10.0, wavePosition2D, waveSpaceLocalPosition, 118.0 * 0.5, strength * strengthWave * 2.0, constantBend, animationTimer * 2.5 * 1.5 * (1.0 + globalStrength / 32.0), waveSpaceNormal);
    waveSpacePos = getIndividualWave((windDir + vec2(-0.07,0.02)) * -19.0, wavePosition2D, waveSpacePos,120.0 * 4.3, strength * strengthWave * 0.7, constantBend, animationTimer * 2.8 * 1.5 * 1.5 * (1.0 + globalStrength / 32.0), waveSpaceNormal);
    waveSpacePos = getIndividualWave((windDir + vec2(0.045,-0.17)) * -17.0, wavePosition2D, waveSpacePos,90.0 * 7.3, strength * strengthWave * 0.9, constantBend, animationTimer * 3.8 * 1.5 * (1.0 + globalStrength / 32.0), waveSpaceNormal);
    
    vec3 windPos = (inverseWaveMatrix * vec4(waveSpacePos, 1.0)).xyz;

    normal = (inverseWaveMatrix * vec4(waveSpaceNormal, 1.0)).xyz;

    return windPos;
}


vec3 getFloatingObjectIndividualWave(vec2 waveOriginOffset, vec2 wavePosition2D, vec3 waveSpaceLocalPosition, float waveLengthScale, float localStrength, float animationTimerToUse)
{
    vec2 directionA = waveOriginOffset - wavePosition2D;
    float lengthA = length(directionA);
    //float waveAngleA = ((sin(lengthA * waveLengthScale + animationTimerToUse)) * localStrength + (1.5 * unmodifiedStrength)) * STRENGTH_MULTIPLIER;
    float sinBase = lengthA * waveLengthScale + animationTimerToUse;
    float waveAngleA = (sin(sinBase)) * localStrength * STRENGTH_MULTIPLIER;
    float zOffset = cos(sinBase) * localStrength * STRENGTH_MULTIPLIER * 0.002;
    vec2 directionNormal = directionA / lengthA;

    vec3 waveSpaceAxis = cross(vec3(directionNormal.x, 0.0, directionNormal.y), vec3(0.0, 1.0, 0.0));
    vec4 waveQuat = quatAngleAxis(-waveAngleA, waveSpaceAxis);

    vec3 waveSpacePos = rotate_vector(waveQuat, waveSpaceLocalPosition);
    waveSpacePos.y += zOffset;

    return waveSpacePos;
}

vec3 getFloatingObjectWavePos(mat4 waveMatrix, vec2 windDir, vec3 pos, vec3 originLocalPos, float animationTimer)
{
    vec2 wavePosition2D = (waveMatrix * vec4(originLocalPos, 1.0)).xz;
    vec3 waveSpaceLocalPosition = (waveMatrix * vec4(pos, 1.0)).xyz;
    mat4 inverseWaveMatrix = inverse(waveMatrix);

    float strengthWave = getStrengthWave(windDir * -40.0 + vec2(-5.6, 4.0), wavePosition2D, waveSpaceLocalPosition, 200.0, animationTimer);

    vec3 waveSpacePos = getFloatingObjectIndividualWave((windDir + vec2(0.11,0.3)) * -100.0, wavePosition2D, waveSpaceLocalPosition, 52.0 * 0.5, strengthWave * 0.2, animationTimer * 3.5);
    waveSpacePos = getFloatingObjectIndividualWave((windDir + vec2(-0.07,0.02)) * -109.0, wavePosition2D, waveSpacePos, 50.0 * 0.5, strengthWave * 0.2, animationTimer * 2.8);
    
    vec3 windPos = (inverseWaveMatrix * vec4(waveSpacePos, 1.0)).xyz;

    return windPos;
}