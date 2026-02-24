import gg
import math
import math.complex as cmplx

const width = 1000
const height = 800
const grid_res = 80

struct App {
mut:
	ctx      &gg.Context = unsafe { nil }
	rot_x    f64 = 0.6
	rot_y    f64 = 0.9
	zoom     f64 = 1.0
	offset_y f64 = 14.0
	is_down  bool
	last_x   int
	last_y   int
}

fn to_u8(val f64) u8 {
	if val > 255.0 { return 255 }
	if val < 0.0 { return 0 }
	return u8(val)
}

fn zeta_full(s cmplx.Complex) cmplx.Complex {
	mut res_re := 0.0
	mut res_im := 0.0
	s_neg := cmplx.complex(-s.re, -s.im)
	for n in 1 .. 45 {
		ln_n := math.log(f64(n))
		ex := math.exp(s_neg.re * ln_n)
		tr := ex * math.cos(s_neg.im * ln_n)
		ti := ex * math.sin(s_neg.im * ln_n)
		if n % 2 == 0 { res_re -= tr res_im -= ti } else { res_re += tr res_im += ti }
	}
	one_s := cmplx.complex(1.0 - s.re, -s.im)
	p_re := math.exp(one_s.re * 0.6931) * math.cos(one_s.im * 0.6931)
	p_im := math.exp(one_s.re * 0.6931) * math.sin(one_s.im * 0.6931)
	dr, di := 1.0 - p_re, -p_im
	d := dr * dr + di * di
	return cmplx.complex((res_re * dr + res_im * di) / d, (res_im * dr - res_re * di) / d)
}

fn frame(mut app App) {
	app.ctx.begin()
	app.ctx.draw_rect_filled(0, 0, width, height, gg.black)

	for i := 0; i < grid_res; i++ {
		for j := 0; j < grid_res; j++ {
			re := 0.1 + f64(i) * 0.015
			im := app.offset_y + f64(j) * 0.2

			s := cmplx.complex(re, im)
			w := zeta_full(s)

			mod := math.sqrt(w.re * w.re + w.im * w.im)
			phase := math.atan2(w.im, w.re)

			x := (re - 0.5) * 250.0
			y := (im - app.offset_y - 8.0) * 20.0
			z := if mod > 4.0 { 4.0 } else { mod } * 40.0

			x1 := x * math.cos(app.rot_x) - y * math.sin(app.rot_x)
			y1 := x * math.sin(app.rot_x) + y * math.cos(app.rot_x)
			y2 := y1 * math.cos(app.rot_y) - z * math.sin(app.rot_y)
			z2 := y1 * math.sin(app.rot_y) + z * math.cos(app.rot_y)

			z_d := (400.0 / app.zoom) + z2
			if z_d < 1.0 { continue }
			px := f32(500.0 + (x1 * 1200.0) / z_d)
			py := f32(400.0 - (y2 * 1200.0) / z_d)

			// Mapowanie Fazy (4-ty wymiar) na kolory RGB
			r := to_u8(127.0 + 127.0 * math.cos(phase))
			g := to_u8(127.0 + 127.0 * math.cos(phase + 2.094))
			b := to_u8(127.0 + 127.0 * math.cos(phase + 4.188))

			mut alpha := u8(160)
			if math.abs(re - 0.5) < 0.008 { alpha = 255 }

			app.ctx.draw_rect_filled(px, py, 3, 3, gg.Color{r, g, b, alpha})
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
				app.rot_x += (f64(e.mouse_x) - app.last_x) * 0.01
				app.rot_y += (f64(e.mouse_y) - app.last_y) * 0.01
			}
			app.last_x = int(e.mouse_x)
			app.last_y = int(e.mouse_y)
		}
		.mouse_scroll {
			app.zoom += e.scroll_y * 0.1
			if app.zoom < 0.1 { app.zoom = 0.1 }
		}
		.key_down {
			if e.key_code == .w { app.offset_y += 0.5 }
			if e.key_code == .s { app.offset_y -= 0.5 }
		}
		else {}
	}
}

fn main() {
	mut app := &App{}
	app.ctx = gg.new_context(
		width: width
		height: height
		window_title: 'Riemann Zeta 4D: Color-Phase Topology'
		frame_fn: frame
		event_fn: event
		user_data: app
	)
	app.ctx.run()
}
