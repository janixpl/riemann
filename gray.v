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

// Zamiana liczby binarnej na kod Graya
fn binary_to_gray(n i64) i64 {
	return n ^ (n >> 1)
}

// Rozdzielanie bitów kodu Graya na współrzędne X i Y (Z-order/Morton curve style)
fn decode_gray_to_2d(gray i64) (int, int) {
	mut x := 0
	mut y := 0
	for i in 0 .. 31 {
		bit := (gray >> i) & 1
		if i % 2 == 0 {
			x |= int(bit << (i / 2))
		} else {
			y |= int(bit << (i / 2))
		}
	}
	return x, y
}

fn main() {
	mut limit := 40000 // Ile liczb sprawdzamy
	mut zoom := f32(4.0)

	r.init_window(1000, 1000, 'Ulam Map - Gray Code 2D')
	r.set_target_fps(60)

	mut camera := r.Camera2D{
		target: r.Vector2{500, 500}
		offset: r.Vector2{500, 500}
		rotation: 0
		zoom: 1.0
	}

	for !r.window_should_close() {
		// Sterowanie zoomem i przesuwaniem
		if r.is_key_down(int(r.KeyboardKey.key_equal)) { zoom += 0.1 }
		if r.is_key_down(int(r.KeyboardKey.key_minus)) { zoom -= 0.1 }
		camera.zoom = zoom

		if r.is_mouse_button_down(int(r.MouseButton.mouse_button_left)) {
			delta := r.get_mouse_delta()
			camera.target.x -= delta.x / camera.zoom
			camera.target.y -= delta.y / camera.zoom
		}

		r.begin_drawing()
		r.clear_background(r.Color{10, 10, 15, 255})

		r.begin_mode_2d(camera)

		for n in 1 .. limit {
			if is_prime(n) {
				gray := binary_to_gray(n)
				gx, gy := decode_gray_to_2d(gray)

				// Rysujemy mały punkt dla każdej liczby pierwszej
				pos_x := f32(gx) * 2.0
				pos_y := f32(gy) * 2.0

				// Kolorowanie bitowe - pokazuje "głębokość" liczby
				color := r.color_from_hsv(f32(n % 360), 0.7, 1.0)
				r.draw_pixel_v(r.Vector2{pos_x, pos_y}, color)
			}
		}

		r.end_mode_2d()

		r.draw_rectangle(10, 10, 350, 100, r.Color{0, 0, 0, 200})
		r.draw_text('GRAY CODE PRIME MAP', 20, 20, 20, r.gold)
		r.draw_text('N: ${limit}', 20, 50, 18, r.raywhite)
		r.draw_text('LPM: Przesuń | +/-: Zoom', 20, 75, 14, r.lightgray)

		r.end_drawing()
	}
	r.close_window()
}
