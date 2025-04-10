
layout(location = 0) out vec4 data;

/** Defines **/
#define M_PI 3.1415926535897932384626433832795
#define M_PI2 M_PI * 2
#define PI    3.14159265359
#define INVPI 0.31830988618
#define EPS   1e-5

float saturate (float x) {
    return clamp(x, 0.0, 1.0);
}

vec3 saturate (vec3 v) {
    return clamp(v, 0.0, 1.0);
}

float radicalInverse_VdC(uint bits) {
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}

// http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
vec2 Hammersley(uint i, uint N) {
    return vec2(float(i)/float(N), radicalInverse_VdC(i));
}

vec3 ImportanceSampleGGX( vec2 E, float Roughness4, vec3 N ) {
    
    float Phi = 2.0 * PI * E.x;
    float CosTheta = sqrt( (1.0 - E.y) / ( 1.0 + (Roughness4 - 1.0) * E.y ) );
    float SinTheta = sqrt( 1.0 - CosTheta * CosTheta );
    
    vec3 H;
    H.x = SinTheta * cos( Phi );
    H.y = SinTheta * sin( Phi );
    H.z = CosTheta;
    
    vec3 UpVector = abs(N.z) < 0.999 ? vec3(0,0,1) : vec3(1,0,0);
    vec3 TangentX = normalize( cross( UpVector, N ) );
    vec3 TangentY = cross( N, TangentX );
    // tangent to world space
    return TangentX * H.x + TangentY * H.y + N * H.z;
}

// http://graphicrants.blogspot.com.au/2013/08/specular-brdf-reference.html
float GGX(float NdotV, float a){
    float k = a / 2.0;
    return NdotV / (NdotV * (1.0f - k) + k);
}

// http://graphicrants.blogspot.com.au/2013/08/specular-brdf-reference.html
float G_Smith(float a, float nDotV, float nDotL){
    return GGX(nDotL, a * a) * GGX(nDotV, a * a);
}

vec2 IntegrateBRDF(float Roughness, float NoV ){
    vec3 V;
    V.x = sqrt( 1.0f - NoV * NoV ); // sin
    V.y = 0.0;
    V.z = NoV;
    // cos
    float A = 0.0;
    float B = 0.0;
    
    float Roughness4 = pow(Roughness, 4.0);
    
    uint NumSamples = 1024u;
    for( uint i = 0u; i < NumSamples; i++){
        vec2 Xi = Hammersley(i, NumSamples);
        vec3 H = ImportanceSampleGGX(Xi, Roughness4, vec3(0.0, 0.0, 1.0));
        vec3 L = 2.0 * dot( V, H ) * H - V;
        float NoL = saturate(L.z);
        float NoH = saturate(H.z);
        float VoH = saturate(dot(V, H));
        if( NoL > 0.0 ){
            float G = G_Smith( Roughness, NoV, NoL );
            float G_Vis = G * VoH / (NoH * NoV);
            float Fc = pow( 1.0 - VoH, 5.0 );
            A += (1.0 - Fc) * G_Vis;
            B += Fc * G_Vis;
        }
    }
    return vec2( A, B ) / NumSamples;
}

void main( void )
{
	//vec3 color = textureCube( cubeTexture, outNormal ).rgb;
	//float roughness = lod / maxLod;
	//vec3 color = PrefilterEnvMap( pow( roughness, 6.0 ), normal );

    vec2 brdf = IntegrateBRDF(gl_FragCoord.x / 64.0, gl_FragCoord.y / 64.0);
    data = vec4(brdf.x, brdf.y,0.0, 1.0);
}