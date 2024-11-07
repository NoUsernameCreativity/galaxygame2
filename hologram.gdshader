shader_type spatial;
render_mode cull_disabled;

uniform vec3 baseColour = vec3(.1, .2, .45);
uniform float lineDensity = 2;
uniform float lineSpacing = 0.2;
uniform float scrollSpeed = 4.0;
uniform float fresnelFactor = 1.0;
uniform float stripesInfluence = 0.3;

float fresnel(float amount, vec3 normal, vec3 view){
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex(){
	vec4 vert = vec4(VERTEX, 1.0);
	vert = MODELVIEW_MATRIX * (vert);
	vert = PROJECTION_MATRIX * (vert+vec4(1,0,0,0)*sin(vert.y*10.0+TIME)/100.0);
	POSITION = vert + vec4(0,0,0,0);
}

void fragment() {
	// obtain bands of values from 0->1 every 0 -> lineDensity
	float stripes = mod((SCREEN_UV.y*100.0+TIME*scrollSpeed), lineDensity) / lineDensity;
	// flip second half (above 1) to have nice falloff
	if(abs(stripes-0.5) <= lineSpacing){stripes = 1.0;}
	else{stripes = 0.0;}
	
	// calc fresnel alpha and glow
	float fresnelAmount = fresnel(fresnelFactor, NORMAL, VIEW);
	float strength = clamp(fresnelAmount*0.5 + stripes*stripesInfluence, 0.0, 1.0) + 0.2;
	
	// add hologram colour
	EMISSION = baseColour * strength;
	ALPHA = strength;
}
