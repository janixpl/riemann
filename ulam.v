import gg
import math

const width = 1000
const height = 800
const cell_size = 2 // Bardzo małe punkty dla ogromnej rozdzielczości
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
	x i16 // Używamy i16 by oszczędzić pamięć przy 300k
	y i16
}

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

		// Rysujemy tylko to, co widać na ekranie (Clipping)
		if dx > 0 && dx < width && dy > 0 && dy < height {
			if is_prime(n) {
				// Sprawdzamy hover tylko dla punktów blisko myszy
				is_hover := math.abs(app.mouse_x - dx) < cell_size &&
				            math.abs(app.mouse_y - dy) < cell_size

				mut color := gg.Color{60, 100, 200, 180}
				if is_hover {
					color = gg.white
					print('\rLICZBA: ${n:-8} | POS: ${cur_x},${-cur_y}       ')
				}
				app.ctx.draw_rect_filled(dx, dy, 2, 2, color)
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
			if e.key_code == .up { app.limit += 10000 }
			if e.key_code == .down { app.limit -= 10000 }
		}
		else {}
	}
}

fn main() {
	mut app := &App{}
	app.ctx = gg.new_context(
		width: width, height: height, window_title: 'Deep Ulam Spiral (250k)',
		frame_fn: frame, event_fn: event, user_data: app
	)
	app.ctx.run()
}
