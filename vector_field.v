import gg
import math
import math.complex as cmplx

const width = 1000
const height = 800
const grid_res = 50

struct App {
mut:
	ctx      &gg.Context = unsafe { nil }
	rot_x    f64 = 0.8
	rot_y    f64 = 0.5
	zoom     f64 = 1.1
	offset_y f64 = 13.0
	is_down  bool
	last_x   int
	last_y   int
	frame_cnt int
}

fn to_u8(val f64) u8 {
	if val > 255.0 { return 255 }
	if val < 0.0 { return 0 }
	return u8(val)
}

fn zeta_full(s cmplx.Complex) cmplx.Complex {
	mut res_re, mut res_im := 0.0, 0.0
	s_neg := cmplx.complex(-s.re, -s.im)
	for n in 1 .. 40 {
		ln_n := math.log(f64(n))
		ex := math.exp(s_neg.re * ln_n)
		tr, ti := ex * math.cos(s_neg.im * ln_n), ex * math.sin(s_neg.im * ln_n)
		if n % 2 == 0 { res_re -= tr res_im -= ti } else { res_re += tr res_im += ti }
	}
	one_s := cmplx.complex(1.0 - s.re, -s.im)
	p_re := math.exp(one_s.re * 0.6931) * math.cos(one_s.im * 0.6931)
	p_im := math.exp(one_s.re * 0.6931) * math.sin(one_s.im * 0.6931)
	dr, di := 1.0 - p_re, -p_im
	d := dr * dr + di * di
	return cmplx.complex((res_re * dr + res_im * di) / d, (res_im * dr - res_re * di) / d)
}

fn project(x f64, y f64, z f64, app &App) (f32, f32) {
	x1 := x * math.cos(app.rot_x) - y * math.sin(app.rot_x)
	y1 := x * math.sin(app.rot_x) + y * math.cos(app.rot_x)
	y2 := y1 * math.cos(app.rot_y) - z * math.sin(app.rot_y)
	z2 := y1 * math.sin(app.rot_y) + z * math.cos(app.rot_y)
	z_d := (400.0 / app.zoom) + z2
	if z_d < 1.0 { return -1000, -1000 }
	return f32(500.0 + (x1 * 1200.0) / z_d), f32(400.0 - (y2 * 1200.0) / z_d)
}

fn frame(mut app App) {
	app.ctx.begin()
	app.ctx.draw_rect_filled(0, 0, width, height, gg.black)

	// --- LICZNIK W KONSOLI ---
	// Wypisuj parametry co 10 klatek, żeby nie spowalniać procesora
	app.frame_cnt++
	if app.frame_cnt % 10 == 0 {
		print('\x1b[H\x1b[2J') // Czyści terminal (ANSI escape code)
		println('--- NAWIGATOR RIEMANNA ---')
		println('Aktualna wysokość t (Im): ${app.offset_y:.4f}')
		println('Zoom: ${app.zoom:.2f}')
		println('Użyj W/S aby płynąć, Mysz aby obracać, Scroll aby przybliżać')
		println('--------------------------')
	}

	// Skala Im
	for t_mark := math.floor(app.offset_y - 5.0); t_mark < app.offset_y + 15.0; t_mark += 1.0 {
		mut mark_color := gg.Color{60, 60, 60, 255}
		if math.mod(math.abs(t_mark), 5.0) < 0.1 { mark_color = gg.Color{180, 180, 180, 255} }

		p1_x, p1_y := project((0.0-0.5)*300.0, (t_mark-app.offset_y)*25.0, 0, app)
		p2_x, p2_y := project((1.0-0.5)*300.0, (t_mark-app.offset_y)*25.0, 0, app)
		if p1_x > -500 { app.ctx.draw_line(p1_x, p1_y, p2_x, p2_y, mark_color) }
	}

	// Pole wektorowe
	for i := 0; i < grid_res; i++ {
		for j := 0; j < grid_res; j++ {
			re := 0.2 + f64(i) * 0.015
			im := app.offset_y + f64(j) * 0.2 - 5.0

			s := cmplx.complex(re, im)
			w := zeta_full(s)
			mod := math.sqrt(w.re * w.re + w.im * w.im)
			z_h := if mod > 3.0 { 3.0 } else { mod } * 50.0

			gx := (re - 0.5) * 300.0
			gy := (im - app.offset_y) * 25.0

			px, py := project(gx, gy, z_h, app)
			if px < 0 || px > width { continue }

			v_scale := 12.0
			px2, py2 := project(gx + w.re * v_scale, gy + w.im * v_scale, z_h, app)

			mut color := gg.Color{80, 150, 255, 140}
			if math.abs(re - 0.5) < 0.008 { color = gg.Color{255, 215, 0, 255} }

			app.ctx.draw_line(px, py, px2, py2, color)
			app.ctx.draw_rect_filled(px - 1, py - 1, 2, 2, color)
		}
	}
	app.ctx.end()
}

fn event(e &gg.Event, mut app App) {
	match e.typ {
		.mouse_down { app.is_down = true }
		.mouse_up   { app.is_down = false }
		.mouse_move {
			if app.is_down {
				app.rot_x += (f64(e.mouse_x) - app.last_x) * 0.005
				app.rot_y += (f64(e.mouse_y) - app.last_y) * 0.005
			}
			app.last_x, app.last_y = int(e.mouse_x), int(e.mouse_y)
		}
		.mouse_scroll { app.zoom += e.scroll_y * 0.05 }
		.key_down {
			if e.key_code == .w { app.offset_y += 0.1 }
			if e.key_code == .s { app.offset_y -= 0.1 }
		}
		else {}
	}
}

fn main() {
	mut app := &App{}
	app.ctx = gg.new_context(
		width: width, height: height, window_title: 'Zeta Navigator',
		frame_fn: frame, event_fn: event, user_data: app
	)
	app.ctx.run()
}
