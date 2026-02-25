import gg
import math

const width = 1000
const height = 800
const cell_size = 2
const max_n = 300000

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	limit     int = 250000
	mouse_x   f32
	mouse_y   f32
	pos_cache []Pos = []Pos{len: max_n}
}

struct Pos {
mut:
	x i16
	y i16
}

// Test pierwszości
fn is_prime(n int) bool {
	if n <= 1 { return false }
	if n <= 3 { return true }
	if n % 2 == 0 || n % 3 == 0 { return false }
	mut i := 5
	for i * i <= n {
		if n % i == 0 || n % (i + 2) == 0 { return false }
		i += 6
	}
	return true
}

// Funkcja sprawdzająca, czy liczba n należy do ciągu Eulera: x^2 + x + 41
fn is_euler(n int) bool {
	if n < 41 { return false }
	// Rozwiązujemy równanie kwadratowe x^2 + x + (41 - n) = 0
	// Delta = 1 - 4 * 1 * (41 - n) = 1 - 164 + 4n = 4n - 163
	delta := 4.0 * f64(n) - 163.0
	if delta < 0 { return false }
	sqrt_delta := math.sqrt(delta)
	// Sprawdzamy czy pierwiastek z delty jest liczbą całkowitą
	if math.abs(sqrt_delta - math.round(sqrt_delta)) < 0.0001 {
		x := (-1.0 + sqrt_delta) / 2.0
		if x >= 0 && math.abs(x - math.round(x)) < 0.0001 {
			return true
		}
	}
	return false
}

fn frame(mut app App) {
	app.ctx.begin()
	app.ctx.draw_rect_filled(0, 0, width, height, gg.black)

	mut cur_x := 0
	mut cur_y := 0
	mut step_limit := 1
	mut step_count := 0
	mut dir := 0
	mut turn_count := 0

	for n in 1 .. app.limit {
		if n >= max_n { break }

		app.pos_cache[n] = Pos{i16(cur_x), i16(cur_y)}

		dx := f32(500 + cur_x * cell_size)
		dy := f32(400 + cur_y * cell_size)

		if dx > 0 && dx < width && dy > 0 && dy < height {
			if is_prime(n) {
				// Sprawdzamy czy to wielomian Eulera
				euler := is_euler(n)

				is_hover := math.abs(app.mouse_x - dx) < 2 &&
				            math.abs(app.mouse_y - dy) < 2

				mut color := gg.Color{60, 100, 200, 150} // Standardowy błękit

				if euler {
					color = gg.Color{255, 215, 0, 255} // ZŁOTO dla Eulera
				}

				if is_hover {
					color = gg.white
					print('\rLICZBA: ${n:-8} | WIELOMIAN EULERA: ${euler}      ')
				}

				size := if euler { f32(3) } else { f32(2) }
				app.ctx.draw_rect_filled(dx, dy, size, size, color)
			}
		}

		match dir {
			0 { cur_x++ }
			1 { cur_y-- }
			2 { cur_x-- }
			3 { cur_y++ }
			else {}
		}
		step_count++
		if step_count == step_limit {
			step_count = 0
			dir = (dir + 1) % 4
			turn_count++
			if turn_count == 2 {
				turn_count = 0
				step_limit++
			}
		}
	}
	app.ctx.end()
}

fn event(e &gg.Event, mut app App) {
	match e.typ {
		.mouse_move {
			app.mouse_x = e.mouse_x
			app.mouse_y = e.mouse_y
		}
		.key_down {
			if e.key_code == .up { app.limit += 20000 }
			if e.key_code == .down { app.limit -= 20000 }
		}
		else {}
	}
}

fn main() {
	mut app := &App{}
	app.ctx = gg.new_context(
		width: width, height: height, window_title: 'Deep Ulam: Euler Polynomial Highlight',
		frame_fn: frame, event_fn: event, user_data: app
	)
	app.ctx.run()
}
