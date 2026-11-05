shader_type canvas_item;
// Jednolita sylwetka z kanału alfa tekstury (postać za pniem lub wozem).
uniform vec4 silhouette_color : source_color = vec4(0.85, 0.92, 1.0, 0.65);

void fragment() {
	COLOR = vec4(silhouette_color.rgb, silhouette_color.a * texture(TEXTURE, UV).a);
}
