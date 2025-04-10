
vec4 slerp(vec4 x,	vec4 y, float a)
{
  vec4 z = y;

  float cosTheta = dot(x, y);
  if (cosTheta < 0)
  {
    z        = -y;
    cosTheta = -cosTheta;
  }

  if(cosTheta > 0.9999)
  {
    return vec4(
      mix(x.x, z.x, a),
      mix(x.y, z.y, a),
      mix(x.z, z.z, a),
      mix(x.w, z.w, a));
  }
  else
  {
    float angle = acos(cosTheta);
    return (sin((1.0 - a) * angle) * x + sin(a * angle) * z) / sin(angle);
  }
}

vec3 rotate_vector( vec4 quat, vec3 vec )
{
    return vec + 2.0 * cross( cross( vec, quat.xyz ) + quat.w * vec, quat.xyz );
}