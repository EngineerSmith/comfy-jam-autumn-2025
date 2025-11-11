// written by groverbuger for g3d
// september 2021
// MIT license

// this vertex shader is what projects 3d vertices in models onto your 2d screen

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn

uniform vec3 lightDirection;
uniform bool disableLight;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;

varying float vertexLight;

#ifdef VERTEX
// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute layout(location = 3) vec3 VertexNormal;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // calculate the positions of the transformed coordinates on the screen
    // save each step of the process, as these are often useful when writing custom fragment shaders
    worldPosition = modelMatrix * vertexPosition;
    viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;

    // save some data from this vertex for use in fragment shaders
    mat3 normalMatrix = transpose(inverse(mat3(modelMatrix)));
    vertexNormal = normalize(normalMatrix * VertexNormal);

    vertexColor = VertexColor;

    float light = max(0.0, dot(vertexNormal, lightDirection));
    if (disableLight)
        light = 0.5;
    vertexLight = clamp(0.3 + 0.7 * light, 0.0, 1.0);

    return screenPosition;
}
#endif

#ifdef PIXEL
#define COLLECTABLE_SHADOW_MAX 32
uniform vec3 collectablePositions[COLLECTABLE_SHADOW_MAX];
uniform int numCollectable;
uniform float shadowRadiusX;
uniform float shadowRadiusY;
uniform float shadowSoftness;
uniform float shadowStrength;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 textureColor = Texel(tex, texture_coords);
    if (textureColor.a <= 0.005)
        discard;
    vec4 baseColor = textureColor * color;
    vec4 finalColor = vec4(baseColor.rgb * vertexLight, baseColor.a);

    float overallShadowIntensity = 0.0;
    for (int i = 0; i < min(numCollectable, COLLECTABLE_SHADOW_MAX); i++) {
        if (worldPosition.z >= collectablePositions[i].z)
            continue;

        float dx = worldPosition.x - collectablePositions[i].x;
        float dy = worldPosition.y - collectablePositions[i].y;

        float invRadiusX = (shadowRadiusX > 0.0) ? (1.0 / shadowRadiusX) : 0.0;
        float invRadiusY = (shadowRadiusY > 0.0) ? (1.0 / shadowRadiusY) : 0.0;
        float effectiveDistSq = (dx * invRadiusX) * (dx * invRadiusX) + (dy * invRadiusY) * (dy * invRadiusY);

        if (effectiveDistSq < 1.0) {
            float effectiveDist = sqrt(effectiveDistSq);
            float intensity = 1.0 - effectiveDist;
            intensity = pow(intensity, shadowSoftness);

            overallShadowIntensity = max(overallShadowIntensity, intensity);
        }
    }
    float darkingFactor = max(1.0 - overallShadowIntensity * shadowStrength, 0.1);
    finalColor.rgb *= darkingFactor;

    return finalColor;
}
#endif