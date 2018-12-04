uniform vec2 sprite_size;
uniform float outline_width = 0.0;
uniform vec4 outline_color;

uniform sampler2D texture_image;
uniform vec2 texture_scale = vec2(1, 1);

// includes the intercardinal pixels for outline generation
uniform bool include_corners;

float pixelSizeX = 1.0 / sprite_size.x;
float pixelSizeY = 1.0 / sprite_size.y;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
	// texture color
	vec4 col = texture2D(texture, texture_coords);

	bool hasOutline = outline_width > 0.0;
	if (!hasOutline) {
		return col * color;
	}

  float offsetX = pixelSizeX * outline_width;
  float offsetY = pixelSizeY * outline_width;
  float originalAlpha = col.a;
  float a = texture2D(texture, vec2(texture_coords.x + offsetX  , texture_coords.y)).a +
            texture2D(texture, vec2(texture_coords.x            , texture_coords.y - offsetY)).a +
            texture2D(texture, vec2(texture_coords.x - offsetX  , texture_coords.y)).a +
            texture2D(texture, vec2(texture_coords.x            , texture_coords.y + offsetY)).a;

  if (include_corners) {
      a = a +
        texture2D(texture, vec2(texture_coords.x + offsetX  , texture_coords.y - offsetY)).a +
        texture2D(texture, vec2(texture_coords.x + offsetX  , texture_coords.y + offsetY)).a +
        texture2D(texture, vec2(texture_coords.x - offsetX  , texture_coords.y - offsetY)).a +
        texture2D(texture, vec2(texture_coords.x - offsetX  , texture_coords.y + offsetY)).a;
  }

  bool isEdgePixel = a > 0.0;
  bool isCurrentPixelTransparent = originalAlpha == 0.0;
  bool isTransparentEdge = isCurrentPixelTransparent && isEdgePixel;
  vec4 texColor = texture2D(texture_image, texture_coords * texture_scale);
  if (isTransparentEdge) {
    vec4 result = vec4(outline_color);
    result.a *= color.a;
    return result * texColor;
  }
  else {
		return col * color * texColor;
  }
}