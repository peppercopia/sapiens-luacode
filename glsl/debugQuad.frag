
layout(binding = 1) uniform sampler2D texMap;

layout(location = 0) in vec4 fragColor;
layout(location = 1) in vec2 fragTexCoord;

layout(location = 0) out vec4 outColor;

const float exposure = 16.0;



vec3 hdrFinal(vec3 color) {

	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
	color = color * exposure * exposure * exposure * 0.05;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
    float gamma = 1.2 + exposure * 0.01;
	color = pow(color, vec3(1.0 / gamma));
	
	return color;
}


void main() {
    vec4 tex = texture(texMap, fragTexCoord);
    outColor = vec4(hdrFinal(tex.rgb * fragColor.rgb), tex.a);
}