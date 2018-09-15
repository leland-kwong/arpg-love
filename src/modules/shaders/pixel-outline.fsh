uniform vec2 sprite_size;
uniform float outline_width = 0.0;
uniform vec4 outline_color;
// includes the intercardinal pixels for outline generation
uniform bool include_corners;
uniform bool use_drawing_color;
uniform float alpha = 1.0;
uniform vec4 fill_color = vec4(1,1,1,1);
vec4 empty_color = vec4(0,0,0,0);

float pixelSizeX = 1.0 / sprite_size.x;
float pixelSizeY = 1.0 / sprite_size.y;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
	// texture color
	vec4 col = texture2D(texture, texture_coords);

	bool hasOutline = outline_width > 0.0;
	if (!hasOutline) {
    col.a *= alpha;
		return col;
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
  if (isTransparentEdge) {
    vec4 result = vec4(outline_color);
    result.a *= alpha;
    return result;
  }
  else {
    vec4 result = use_drawing_color
      ? (isCurrentPixelTransparent ? col : color) * fill_color
      : col * fill_color;
    result.a *= alpha;
		return result;
  }
}