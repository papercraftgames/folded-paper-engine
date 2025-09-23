shader_type spatial;
render_mode cull_back, depth_draw_opaque;

/* Adopted look (only used when source HAS a texture) */
uniform sampler2D base_albedo_tex : source_color;
uniform vec4  base_color : source_color = vec4(1.0);
uniform vec2  uv1_scale  = vec2(1.0);
uniform vec2  uv1_offset = vec2(0.0);

/* Geometry waves (world-ish via model->world transform) */
uniform float amp   = 0.35;   // visible
uniform float freq  = 1.8;
uniform float speed = 1.0;
uniform vec2  dir   = vec2(1.0, 0.4);

/* Texture shimmer */
uniform float wobble_strength = 0.03;
uniform float wobble_freq     = 6.0;
uniform float wobble_speed    = 1.2;

varying vec2 v_uv_src;

void vertex() {
    v_uv_src = UV * uv1_scale + uv1_offset;

    // Godot 4: use MODEL_MATRIX, not WORLD_MATRIX
    vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    vec2 w = normalize(dir);
    float t = TIME * speed;

    float h = sin(dot(wp.xz, w) * freq + t) * 0.5
            + cos(dot(wp.xz, vec2(-w.y, w.x)) * (freq * 0.85) + t * 1.27) * 0.5;

    VERTEX += NORMAL * (h * amp);
}

void fragment() {
    vec2 uv = v_uv_src;

    // Texture warble
    float t = TIME * wobble_speed;
    vec2 wobble = vec2(
        sin(uv.y * wobble_freq + t),
        cos(uv.x * (wobble_freq * 0.9) - t * 1.13)
    ) * wobble_strength;
    uv += wobble;

    vec4 base = texture(base_albedo_tex, uv) * base_color;
    ALBEDO = base.rgb;
    ALPHA  = base.a;
}
