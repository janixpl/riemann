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
	// --- PARAMETRY TORUSA ---
	mut total_points := 10000 // Ile liczb sprawdzamy
	mut tube_radius := f32(5.0)  // Promień rurki (mały)
	mut main_radius := f32(15.0) // Promień całego pączka (duży)
	mut winding_speed := f32(0.1) // Jak szybko owijamy rurkę (klucz do patternów!)
	voxel_size := f32(0.4)
	// ------------------------

	r.init_window(1024, 768, 'Ulam 3D - Torus Topology')
	r.set_target_fps(60)

	// Kamera manualna
	mut cam_dist := f32(50.0)
	mut angle_h := f32(0.5)
	mut angle_v := f32(0.5)
	sensitivity := f32(0.005)

	mut camera := r.Camera3D{
		up: r.Vector3{0.0, 1.0, 0.0}
		fovy: 45.0
		projection: int(r.CameraProjection.camera_perspective)
	}

	for !r.window_should_close() {
		// --- KONTROLA PARAMETRÓW ---
		if r.is_key_pressed(int(r.KeyboardKey.key_up)) { total_points += 1000 }
		if r.is_key_pressed(int(r.KeyboardKey.key_down)) && total_points > 1000 { total_points -= 1000 }
		if r.is_key_pressed(int(r.KeyboardKey.key_right)) { winding_speed += 0.005 }
		if r.is_key_pressed(int(r.KeyboardKey.key_left)) { winding_speed -= 0.005 }

		// Sterowanie kamerą LPM
		if r.is_mouse_button_down(int(r.MouseButton.mouse_button_left)) {
			delta := r.get_mouse_delta()
			angle_h -= delta.x * sensitivity
			angle_v += delta.y * sensitivity
		}
		cam_dist -= r.get_mouse_wheel_move() * 2.0

		camera.position = r.Vector3{
			x: cam_dist * f32(math.cos(angle_v)) * f32(math.sin(angle_h))
			y: cam_dist * f32(math.sin(angle_v))
			z: cam_dist * f32(math.cos(angle_v)) * f32(math.cos(angle_h))
		}
		camera.target = r.Vector3{0, 0, 0}

		r.begin_drawing()
		r.clear_background(r.Color{10, 10, 20, 255})

		r.begin_mode_3d(camera)

		for i in 0 .. total_points {
			n := i64(i + 1)
			if is_prime(n) {
				// theta: kąt wokół głównego otworu
				// phi: kąt "owijania" rurki
				theta := f64(i) * 0.02
				phi := f64(i) * f64(winding_speed)

				// Równania parametryczne torusa
				x := (f64(main_radius) + f64(tube_radius) * math.cos(phi)) * math.cos(theta)
				y := f64(tube_radius) * math.sin(phi)
				z := (f64(main_radius) + f64(tube_radius) * math.cos(phi)) * math.sin(theta)

				pos := r.Vector3{f32(x), f32(y), f32(z)}

				// Kolor zależny od kąta theta (pozycja na obwodzie)
				color := r.color_from_hsv(f32(theta * 50.0), 0.7, 1.0)
				r.draw_cube(pos, voxel_size, voxel_size, voxel_size, color)
			}
		}

		r.end_mode_3d()

		// Interfejs
		r.draw_rectangle(10, 10, 450, 130, r.Color{0, 0, 0, 200})
		r.draw_text('TORUS PRIME SOLENOID', 20, 20, 20, r.gold)
		r.draw_text('WINDING SPEED: ${winding_speed:.3f}', 20, 50, 18, r.raywhite)
		r.draw_text('PUNKTY: ${total_points}', 20, 75, 18, r.raywhite)
		r.draw_text('STRZAŁKI: Lewo/Prawo (Zmiana skoku spirali)', 20, 105, 14, r.lightgray)

		r.end_drawing()
	}
	r.close_window()
}
