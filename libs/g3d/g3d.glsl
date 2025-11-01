// written by groverbuger for g3d
// september 2021
// MIT license

// this vertex shader is what projects 3d vertices in models onto your 2d screen

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn

uniform vec3 lightDirection;

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
    vertexLight = clamp(0.3 + 0.7 * light, 0.0, 1.0);

    return screenPosition;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 textureColor = Texel(tex, texture_coords);
    if (textureColor.a <= 0.005)
        discard;
    vec4 baseColor = textureColor * color;
    return vec4(baseColor.rgb * vertexLight, baseColor.a);
}
#endif