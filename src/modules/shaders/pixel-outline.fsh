uniform vec2 sprite_size;
uniform float outline_width;
vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
  float pixelSizeX = 1.0 / sprite_size.x;
  float pixelSizeY = 1.0 / sprite_size.y;
  float offsetX = pixelSizeX * outline_width;
  float offsetY = pixelSizeY * outline_width;
  vec4 col = texture2D(texture, texture_coords);
  float originalAlpha = col.a;
  float a = texture2D(texture, vec2(texture_coords.x + offsetX, texture_coords.y)).a +
  texture2D(texture, vec2(texture_coords.x, texture_coords.y - offsetY)).a +
  texture2D(texture, vec2(texture_coords.x - offsetX, texture_coords.y)).a +
  texture2D(texture, vec2(texture_coords.x, texture_coords.y + offsetY)).a;

  bool isEdgePixel = a > 0.0;
  bool isCurrentPixelTransparent = originalAlpha == 0.0;
  bool isTransparentEdge = isCurrentPixelTransparent && isEdgePixel;
  if (isTransparentEdge) {
      return vec4(1,1,1,1);
  }
  else {
      return col;
  }
}