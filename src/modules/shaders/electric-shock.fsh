uniform float time;
uniform float speed;
uniform vec2 resolution; // the higher the value, the more granular the lighting effect
uniform float brightness;
uniform sampler2D noiseImage;
vec4 transparentColor = vec4(0,0,0,0);

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
  vec4 imageColor = texture2D(texture, texture_coords);
  if (imageColor.a == 0.0) {
    return transparentColor;
  }

  vec2 position = texture_coords * resolution;
	vec3 pos = vec3( position.x, 0.0, position.y );

	float timeScale = time * speed;

	// lights
	float cc  = 0.55*texture2D( noiseImage, 1.8*0.02*pos.xz + 0.007*timeScale*vec2( 1.0, 0.0) ).x;
	cc += 0.25*texture2D( noiseImage, 1.8*0.04*pos.xz + 0.011*timeScale*vec2( 0.0, 1.0) ).x;
	cc += 0.10*texture2D( noiseImage, 1.8*0.08*pos.xz + 0.014*timeScale*vec2(-1.0,-1.0) ).x;
	cc = 0.6*(1.0-smoothstep( 0.0, 0.025, abs(cc-0.4))) +
		0.4*(1.0-smoothstep( 0.0, 0.150, abs(cc-0.4)));

	vec4 col = color * cc;

  return color * cc * brightness;
}
