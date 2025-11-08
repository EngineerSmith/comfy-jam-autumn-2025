uniform vec3 centerColor;
uniform vec3 edgeColor;

uniform float vignettePower = 0.5;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
  // Calculate distance from centre
  float dist = distance(texture_coords, vec2(0.5, 0.5));
  // Normalise the distance
  float distNorm = dist * sqrt(2.0);
  // Apply falloff using ^3 for quick transition
  float falloff = clamp(pow(distNorm, vignettePower), 0.0, 1.0);
  // Lerp between colours, centre: falloff = 0, edge: falloff = 1
  vec3 vignette = mix(centerColor, edgeColor, falloff);

  return vec4(vignette, 1.0);
}