import raylib as r
import math

#flag -I/opt/homebrew/include
#flag -L/opt/homebrew/lib
#flag -lraylib

fn is_prime(n i64) bool {
	if n < 2 { return false }
	if n == 2 { return true }
	if n % 2 == 0 { return false }
	mut i := i64(3)
	for i * i <= n {
		if n % i == 0 { return false }
		i += 2
	}
	return true
}

fn main() {
	mut limit := 50000 // Przy liniach mniejszy limit daje lepszą czytelność
	mut mod_val := 8
	mut zoom := 1.0
	mut show_lines := true

	r.init_window(1000, 1000, 'Prime Transition Web - CGR')
	r.set_target_fps(60)

	mut camera := r.Camera2D{
		target: r.Vector2{0, 0}
		offset: r.Vector2{500, 500}
		zoom: 1.0
	}

	for !r.window_should_close() {
		// --- STEROWANIE ---
		if r.is_key_pressed(int(r.KeyboardKey.key_up)) { mod_val++ }
		if r.is_key_pressed(int(r.KeyboardKey.key_down)) && mod_val > 2 { mod_val-- }
		if r.is_key_down(int(r.KeyboardKey.key_right)) { limit += 500 }
		if r.is_key_down(int(r.KeyboardKey.key_left)) && limit > 500 { limit -= 500 }
		if r.is_key_pressed(int(r.KeyboardKey.key_space)) { show_lines = !show_lines }

		camera.zoom += r.get_mouse_wheel_move() * 0.1
		if r.is_mouse_button_down(int(r.MouseButton.mouse_button_left)) {
			delta := r.get_mouse_delta()
			camera.target.x -= delta.x / camera.zoom
			camera.target.y -= delta.y / camera.zoom
		}

		r.begin_drawing()
		r.clear_background(r.Color{5, 5, 10, 255})
		r.begin_mode_2d(camera)

		radius := 400.0
		mut anchors := []r.Vector2{}
		for i in 0 .. mod_val {
			angle := (f64(i) * 2.0 * math.pi / f64(mod_val)) - (math.pi / 2.0)
			anchors << r.Vector2{
				x: f32(math.cos(angle) * radius)
				y: f32(math.sin(angle) * radius)
			}
			r.draw_circle_v(anchors[i], 3, r.gray)
		}

		mut current_pos := r.Vector2{0, 0}
		mut prev_pos := r.Vector2{0, 0}

		for n in 1 .. limit {
			if is_prime(n) {
				m := int(n % mod_val)
				target := anchors[m]

				prev_pos = current_pos
				current_pos.x = (current_pos.x + target.x) / 2.0
				current_pos.y = (current_pos.y + target.y) / 2.0

				if n > 2 { // Zaczynamy rysować od drugiego punktu
					if show_lines {
						// Rysujemy linię z bardzo niską przezroczystością (Alpha: 15)
						// Kolor zależy od reszty docelowej
						color := r.color_from_hsv(f32(m) * (360.0 / f32(mod_val)), 0.5, 1.0)
						r.draw_line_v(prev_pos, current_pos, r.Color{color.r, color.g, color.b, 15})
					} else {
						r.draw_pixel_v(current_pos, r.raywhite)
					}
				}
			}
		}

		r.end_mode_2d()

		// Interfejs
		r.draw_rectangle(10, 10, 480, 160, r.Color{0, 0, 0, 200})
		r.draw_text('PRIME TRANSITION WEB', 20, 20, 22, r.gold)
		r.draw_text('MODULO: ${mod_val} | N: ${limit}', 20, 55, 18, r.raywhite)
		r.draw_text('SPACJA: Przełącz Linie / Punkty', 20, 85, 16, r.green)
		r.draw_text('Strzałki: Modulo i Limit | Mysz: Zoom/Pan', 20, 115, 14, r.lightgray)

		r.end_drawing()
	}
	r.close_window()
}
