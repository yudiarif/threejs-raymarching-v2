uniform float uTime;
uniform float progress;
uniform vec2 mouse;
varying vec3 vPosition;
varying vec3 vNormal;
varying vec2 vUv;
uniform vec4 resolution;
float PI = 3.1415926535897932384626433832795;
uniform sampler2D matcap;
uniform sampler2D matcap2;

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}

vec2 getMatcap(vec3 eye, vec3 normal) {
  vec3 reflected = reflect(eye, normal);
  float m = 2.8284271247461903 * sqrt( reflected.z+1.0 );
  return reflected.xy / m + 0.5;
}



float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sdSphere( vec3 p, float r )
{
  return length(p)-r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 sdf(vec3 p){
	float type = 0.0;
	vec3 p1 = rotate(p,vec3(1.0), uTime/5.0);
	float s = 0.3+0.1*sin(uTime/3.0)+0.2*sin(uTime/6.0)+0.05*sin(uTime);
	float box = smin(sdBox(p1,vec3(s)),sdSphere(p,0.2),s);
	float boxsphere = sdSphere(p1,0.3);
	float final = mix(box, boxsphere, 0.5+0.5*sin(uTime/3.0));


	for (float i=0.0;i<10.0; i++){
	float randOffset = rand(vec2(i,0.0));
	float prog = 1.0 -fract(uTime/3.0 + randOffset*3.0);
	vec3 pos = vec3(sin(randOffset*2.0*PI),cos(randOffset*2.0 *PI),0.0);
	float center = sdSphere(p-pos*prog, 0.1*sin(PI*prog));
	final = smin(final,center,0.2);

	}
	float sphere = sdSphere(p - vec3(mouse*resolution.zw*2.0,0.0),0.2+0.1*sin(uTime));

	if(sphere<final) type =1.0;
	return vec2(smin(final,sphere,0.4),type);
}

vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(sdf(p+h.xyy).x - sdf(p-h.xyy).x,
                           sdf(p+h.yxy).x - sdf(p-h.yxy).x,
                           sdf(p+h.yyx).x - sdf(p-h.yyx).x ) );
}




void main() {
	float dist = length(vUv-vec2(0.5));
	vec3 bg = mix(vec3(0.3),vec3(0.0),dist);
	vec2 newUv = (vUv-vec2(0.5)) * resolution.zw + vec2(0.5);
	vec3 camPos = vec3(0.0,0.0,2.0);
	vec3 ray = normalize(vec3( (vUv - vec2(0.5))* resolution.zw ,-1));
	//vec3 ray = normalize(vec3( (vUv - vec2(0.5)),-1));


	vec3 rayPos = camPos;
	float t = 0.0;
	float tMax = 5.0;
	float type = -1.0 ;
	for(int i=0; i<256; ++i){
		vec3 pos = camPos + t*ray;
		float h = sdf(pos).x;
		type = sdf(pos).y;
		if(h<0.0001 || t>tMax) break;
		t+=h;
	} 
	vec3 color = bg;
	if(t<tMax){
		vec3 pos = camPos+t*ray;
		color = vec3(1.0);
		vec3 normal = calcNormal(pos);
		color = normal;
		float diff = dot(vec3(1.0),normal);
		vec2 matcapUv = getMatcap(ray,normal);
		color = vec3(diff);
		if(type<0.5){
		color = texture2D(matcap, matcapUv).rgb;

		}else{
		color = texture2D(matcap2, matcapUv).rgb;

		}

		float fresnel = pow(1.0 +dot(ray,normal),3.0);
		//color = vec3(fresnel);
		color = mix(color,bg,fresnel);
	}
	gl_FragColor = vec4(color, 1.0);
	//gl_FragColor = vec4(bg, 1.0);
}