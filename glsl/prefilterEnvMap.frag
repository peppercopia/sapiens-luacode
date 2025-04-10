
layout(binding = 1) uniform UniformBufferObject {
	float		lod;
	float		maxLod;
} ubo;

layout(binding = 2) uniform samplerCube cubeTexture;


layout(location = 0) in vec3 normal;

layout(location = 0) out vec4 data;

layout( push_constant ) uniform OpacityBlock {
  vec4 worldUpOpacity;
} pc;

#define saturate(_x_) clamp(_x_, 0.0, 1.0)
#define PI 3.1415926535897932384626433832795

/*
// Interesting page on Hammersley Points
// http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html#
vec2 Hammersley(const in int index, const in int numSamples ){
	int reversedIndex = index;
	reversedIndex = (reversedIndex << 16) | (reversedIndex >> 16);
	reversedIndex = ((reversedIndex & 0x00ff00ff) << 8) | ((reversedIndex & 0xff00ff00) >> 8);
	reversedIndex = ((reversedIndex & 0x0f0f0f0f) << 4) | ((reversedIndex & 0xf0f0f0f0) >> 4);
	reversedIndex = ((reversedIndex & 0x33333333) << 2) | ((reversedIndex & 0xcccccccc) >> 2);
	reversedIndex = ((reversedIndex & 0x55555555) << 1) | ((reversedIndex & 0xaaaaaaaa) >> 1);
	
	return vec2(fract(float(index) / numSamples), float(reversedIndex) * 2.3283064365386963e-10);
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
}*/

// straight from Epic paper for Siggraph 2013 Shading course
// http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_slides.pdf

/*vec3 ImportanceSampleGGX( vec2 Xi, float Roughness4, vec3 N ) {
	float Phi = 2.0 * PI * Xi.x;
	float CosTheta = sqrt( (1.0 - Xi.y) / ( 1.0 + (Roughness4 - 1.0) * Xi.y ) );
	float SinTheta = sqrt( 1.0 - CosTheta * CosTheta );
	
	vec3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;
	
	vec3 UpVector = abs( N.z ) < 0.999 ? vec3(0,0,1) : vec3(1,0,0);
	vec3 TangentX = normalize( cross( UpVector, N ) );
	vec3 TangentY = cross( N, TangentX );
	
	// Tangent to world space
	return TangentX * H.x + TangentY * H.y + N * H.z;
}*/

float radicalInverse_VdC(uint bits) {
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 0.3283064365386963e-10; // / 0x100000000
}

// http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
vec2 Hammersley(uint i, uint N) {
    return vec2(float(i)/float(N), radicalInverse_VdC(i));
}

vec3 ImportanceSampleGGX( vec2 E, float Roughness, vec3 N ) {
    //float m = Roughness * Roughness;
    
    float Phi = 2.0 * PI * E.x;
    float CosTheta = sqrt( (1.0 - E.y) / ( 1.0 + (Roughness - 1.0) * E.y ) );
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

#define numSamples 64u

#define WEIGHT_FUNCTION(__i__) result = getWeight(__i__, roughness, R); prefilteredColor += result.xyz; totalWeight += result.w;

vec4 getWeight(uint i, float roughness, vec3 R)
{
	vec4 result = vec4(0.0);
	vec2 xi  = Hammersley(i, numSamples);
	vec3 H   = ImportanceSampleGGX(xi, roughness, R);
	vec3 L   = 2.0 * dot(R, H) * H - R;
	float  NoL = saturate(dot(R, L));
	if(NoL>0)
	{
		vec3 lookup = L;
		result.xyz = texture( cubeTexture, lookup ).xyz * NoL;
		result.w =  NoL;
	}

	return result;
}

vec3 PrefilterEnvMap( float roughness, vec3 R )
{
	vec3 prefilteredColor = vec3(0);
	float  totalWeight      = 0.0;
	
    //uint numSamples = 32u;//256u / uint( maxLod - lod );
	vec4 result;

	WEIGHT_FUNCTION(0u)
	WEIGHT_FUNCTION(1u)
	WEIGHT_FUNCTION(2u)
	WEIGHT_FUNCTION(3u)
	WEIGHT_FUNCTION(4u)
	WEIGHT_FUNCTION(5u)
	WEIGHT_FUNCTION(6u)
	WEIGHT_FUNCTION(7u)

	WEIGHT_FUNCTION(8u)
	WEIGHT_FUNCTION(9u)
	WEIGHT_FUNCTION(10u)
	WEIGHT_FUNCTION(11u)
	WEIGHT_FUNCTION(12u)
	WEIGHT_FUNCTION(13u)
	WEIGHT_FUNCTION(14u)
	WEIGHT_FUNCTION(15u)

	WEIGHT_FUNCTION(16u)
	WEIGHT_FUNCTION(17u)
	WEIGHT_FUNCTION(18u)
	WEIGHT_FUNCTION(19u)
	WEIGHT_FUNCTION(20u)
	WEIGHT_FUNCTION(21u)
	WEIGHT_FUNCTION(22u)
	WEIGHT_FUNCTION(23u)

	WEIGHT_FUNCTION(24u)
	WEIGHT_FUNCTION(25u)
	WEIGHT_FUNCTION(26u)
	WEIGHT_FUNCTION(27u)
	WEIGHT_FUNCTION(28u)
	WEIGHT_FUNCTION(29u)
	WEIGHT_FUNCTION(30u)
	WEIGHT_FUNCTION(31u)

	WEIGHT_FUNCTION(32u)
	WEIGHT_FUNCTION(33u)
	WEIGHT_FUNCTION(34u)
	WEIGHT_FUNCTION(35u)
	WEIGHT_FUNCTION(36u)
	WEIGHT_FUNCTION(37u)
	WEIGHT_FUNCTION(38u)
	WEIGHT_FUNCTION(39u)

	WEIGHT_FUNCTION(40u)
	WEIGHT_FUNCTION(41u)
	WEIGHT_FUNCTION(42u)
	WEIGHT_FUNCTION(43u)
	WEIGHT_FUNCTION(44u)
	WEIGHT_FUNCTION(45u)
	WEIGHT_FUNCTION(46u)
	WEIGHT_FUNCTION(47u)

	WEIGHT_FUNCTION(48u)
	WEIGHT_FUNCTION(49u)
	WEIGHT_FUNCTION(50u)
	WEIGHT_FUNCTION(51u)
	WEIGHT_FUNCTION(52u)
	WEIGHT_FUNCTION(53u)
	WEIGHT_FUNCTION(54u)
	WEIGHT_FUNCTION(55u)

	WEIGHT_FUNCTION(56u)
	WEIGHT_FUNCTION(57u)
	WEIGHT_FUNCTION(58u)
	WEIGHT_FUNCTION(59u)
	WEIGHT_FUNCTION(60u)
	WEIGHT_FUNCTION(61u)
	WEIGHT_FUNCTION(62u)
	WEIGHT_FUNCTION(63u)

	//getWeight(0, roughness, R); prefilteredColor += result.xyz; totalWeight += result.w;
	
	return prefilteredColor / max(totalWeight, 0.001);
}

void main( void )
{
	vec3 normalizedNormal = normalize( normal);
	/*if(ubo.lod < 0.5)
	{
		data = vec4(texture( cubeTexture, normalizedNormal).xyz, 1.0);
	}
	else
	{*/
		float roughness = (ubo.lod / ubo.maxLod) + (1.0 / ubo.maxLod);
		vec3 color = mix(vec3(0.00004,0.00006,0.00008) * 2.0, PrefilterEnvMap( pow( roughness, 4.0 ), normalizedNormal), 0.6);
		//data = vec4(color, pc.worldUpOpacity.a);
		data = vec4(min(color, vec3(1.0,1.0,1.0)), pc.worldUpOpacity.a);
		//data = vec4(max(color, vec3(0.0004,0.0006,0.0008) * (0.5 + dot(normalizedNormal, vec3(pc.worldUpOpacity.x, -pc.worldUpOpacity.y, pc.worldUpOpacity.z)))), pc.worldUpOpacity.a);
	//}
}