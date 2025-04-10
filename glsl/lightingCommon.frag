
#define MAX_LIGHTS 64

#define LIGHT_DISTANCE_MULTIPLIER 200.0
#define MAX_LIGHT_DISTANCE2 3600.0
#define FADE_OUT_START_LIGHT_DISTANCE2 2000.0
#define FADE_OUT_DIVIDER_LIGHT_DISTANCE2 1600.0 //must be MAX_LIGHT_DISTANCE2 - FADE_OUT_START_LIGHT_DISTANCE2
#define reflectanceMultiplier 1.0

#define BUMP_MAPPING_STRENGTH 0.3

#define SPOTLIGHT_BRIGHTNESS  0.00002
vec3 getSpotlight(vec3 V, vec3 outView, vec3 normal, vec3 camDirection)
{
    float spotMultiplier = smoothstep(0.4, 1.0, dot(-V, camDirection));
    float lightDistance2 = pow(max(dot(outView,outView), 0.0001), 0.6);
    float att = SPOTLIGHT_BRIGHTNESS / lightDistance2;
    float NdotLP        = clamp(dot( normal, V ), 0.0, 1.0);

    return vec3(NdotLP) * att * spotMultiplier;
}

float lightSpecular(vec3 N, vec3 V, vec3 L, float roughness)
{
    vec3 H = normalize(V + L);

    float dotNH = max(dot(N, H), 0.0);

    float alpha = roughness * roughness + 0.0001;

    float alphaSqr = alpha * alpha;
    float denom = dotNH * dotNH * (alphaSqr - 1.0) + 1.0;
    float D = (alphaSqr / (denom * denom)) / 16.0;

    return D;
}



#define  Pr  .299
#define  Pg  .587
#define  Pb  .114
#define saturationIncreaseL 1.1

vec3 changeSaturationL(vec3 inColor)
{
  float  P=sqrt(
  (inColor.r)*(inColor.r)*Pr+
  (inColor.g)*(inColor.g)*Pg+
  (inColor.b)*(inColor.b)*Pb ) ;

  return vec3(P+((inColor.r)-P)*saturationIncreaseL,
  P+((inColor.g)-P)*saturationIncreaseL,
  P+((inColor.b)-P)*saturationIncreaseL);
}

const vec3 coeff = vec3(0.299,0.587,0.114);
const float vibranceAmount = 0.1;
vec3 vibrance(vec3 color)
{
    float lum = dot(color, coeff);
    vec3 mask = (color - vec3(lum));
    mask = clamp(mask, 0.0, 1.0);
    float lumMask = dot(coeff, mask);
    lumMask = 1.0 - lumMask;
    return mix(vec3(lum), color, 1.0 + vibranceAmount * lumMask);
}

vec3 hdrFinal(sampler2D exposureSampler, vec3 color) {

	/*float exposure = texture(exposureSampler, vec2(0.5,0.5)).g;
	color = color * exposure * 0.1;
    float gamma = 0.8;
	color = pow(color, vec3(1.0 / gamma));
	return color * 80.0;*/ //for rendering to HDR displays. Looks pretty bad.

	float A = 0.15;// * 2.0;x
	float B = 0.50;// * 0.1;
	float C = 0.10;// * 1.0;
	float D = 0.20;// * 2.0;// * 10.0;
	float E = 0.02 * 0.5;// * 0.1;x
	float F = 0.30;
	float W = 11.2;
	float exposure = texture(exposureSampler, vec2(0.5,0.5)).g;
	color = color * exposure * exposure * exposure * 0.05;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
    //float gamma = 1.13 + exposure * 0.015;
    float gamma = 1.6;// + exposure * 0.005;
	color = pow(color, vec3(1.0 / gamma));
	//color = changeSaturationL(color);
	return vibrance(color);
}



vec3 hdrConst(vec3 color) {

	/*float exposure = texture(exposureSampler, vec2(0.5,0.5)).g;
	color = color * exposure * 0.1;
    float gamma = 0.8;
	color = pow(color, vec3(1.0 / gamma));
	return color * 80.0;*/ //for rendering to HDR displays. Looks pretty bad.

	float A = 0.15;// * 2.0;x
	float B = 0.50;// * 0.1;
	float C = 0.10;// * 1.0;
	float D = 0.20;// * 2.0;// * 10.0;
	float E = 0.02 * 0.5;// * 0.1;x
	float F = 0.30;
	float W = 11.2;
	float exposure = 14.0;
	color = color * exposure * exposure * exposure * 0.05;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
    float gamma = 1.3;//13 + exposure * 0.015;
	color = pow(color, vec3(1.0 / gamma));
	//color = changeSaturationL(color);
	return vibrance(color);
}