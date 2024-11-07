shader_type spatial;
render_mode unshaded;

uniform sampler2D noise;
uniform vec3 baseCol = vec3(1, 0, 0);
uniform vec3 highlightCol = vec3(1, 1, 0);
uniform float twirlStrength = 1.0;
uniform float twirlSpeed = 0.01;

vec2 twirl(in vec2 UVin, float strength, vec2 offset, vec2 centre){
	vec2 delta = UVin - centre;
	float angle = strength * length(delta); // distort angle more based on distance
	float x = cos(angle) * delta.x - sin(angle) * delta.y; // rotate coords
	float y = sin(angle) * delta.x + cos(angle) * delta.y;
	return vec2(x,y)+offset+centre;
}

void vertex(){
	
}

void fragment() {
	// smoother UV
	vec2 smoothUV = UV;//vec2(abs(UV.x-0.5), UV.y);
	// twirl UV
	vec2 twirledUV = twirl(smoothUV, twirlStrength, vec2(TIME * twirlSpeed, TIME * twirlSpeed), vec2(0, 0.5));
	// deal with noise
	float noiseVal = texture(noise, twirledUV).x;
	float power = pow(noiseVal, 4.0);
	vec3 colour = mix(baseCol, highlightCol, power);
	
	ALBEDO = colour;
	//ALPHA = fresnelAmount;
}