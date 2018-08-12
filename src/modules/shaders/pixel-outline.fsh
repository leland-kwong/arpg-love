uniform vec2 sprite_size;
uniform float outline_width;
uniform vec4 outline_color;
// includes the intercardinal pixels for outline generation
uniform bool include_corners;
uniform bool use_drawing_color;

float pixelSizeX = 1.0 / sprite_size.x;
float pixelSizeY = 1.0 / sprite_size.y;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
  float offsetX = pixelSizeX * outline_width;
  float offsetY = pixelSizeY * outline_width;
  vec4 col = texture2D(texture, texture_coords);
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
      return outline_color;
  }
  else {
      if (use_drawing_color) {
          return isCurrentPixelTransparent ? col : color;
      }
      return col;
  }
}