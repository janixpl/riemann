import gg
import math
import math.complex as cmplx

const width = 1000
const height = 800
const grid_res = 80

struct App {
mut:
	ctx      &gg.Context = unsafe { nil }
	// Kamera
	rot_x    f64 = 0.5
	rot_y    f64 = 0.8
	zoom     f64 = 1.0
	offset_y f64 = 15.0 // Nasza pozycja na osi Im(s)
	// Sterowanie
	last_m_x int
	last_m_y int
	is_down  bool
}

fn to_u8(val f64) u8 {
	if val > 255.0 { return 255 }
	if val < 0.0 { return 0 }
	return u8(val)
}

fn zeta_mod(re f64, im f64) f64 {
	s := cmplx.complex(re, im)
	mut res_re := 0.0
	mut res_im := 0.0
	s_neg := cmplx.complex(-s.re, -s.im)
	for n in 1 .. 40 {
		ln_n := math.log(f64(n))
		exp_re := math.exp(s_neg.re * ln_n)
		tr := exp_re * math.cos(s_neg.im * ln_n)
		ti := exp_re * math.sin(s_neg.im * ln_n)
		if n % 2 == 0 { res_re -= tr res_im -= ti } else { res_re += tr res_im += ti }
	}
	one_minus_s := cmplx.complex(1.0 - s.re, -s.im)
	p_re := math.exp(one_minus_s.re * 0.6931) * math.cos(one_minus_s.im * 0.6931)
	p_im := math.exp(one_minus_s.re * 0.6931) * math.sin(one_minus_s.im * 0.6931)
	dr, di := 1.0 - p_re, -p_im
	d := dr * dr + di * di
	v1, v2 := (res_re * dr + res_im * di) / d, (res_im * dr - res_re * di) / d
	m := math.sqrt(v1 * v1 + v2 * v2)
	return if m > 4.0 { 4.0 } else { m }
}

fn frame(mut app App) {
	app.ctx.begin()
	app.ctx.draw_rect_filled(0, 0, width, height, gg.black)

	for i := 0; i < grid_res; i++ {
		for j := 0; j < grid_res; j++ {
			re := 0.0 + f64(i) * 0.015
			im := app.offset_y + f64(j) * 0.25
			z := zeta_mod(re, im)

			// Model 3D
			x := (re - 0.5) * 200.0
			y := (im - app.offset_y - 10.0) * 20.0
			z_v := z * 45.0

			// Rotacja
			x1 := x * math.cos(app.rot_x) - y * math.sin(app.rot_x)
			y1 := x * math.sin(app.rot_x) + y * math.cos(app.rot_x)
			y2 := y1 * math.cos(app.rot_y) - z_v * math.sin(app.rot_y)
			z2 := y1 * math.sin(app.rot_y) + z_v * math.cos(app.rot_y)

			// Zoom i Projekcja
			z_dist := (300.0 / app.zoom) + z2
			if z_dist < 10.0 { continue }
			fov := 1200.0
			px := f32(500.0 + (x1 * fov) / z_dist)
			py := f32(400.0 - (y2 * fov) / z_dist)

			if px < 0 || px > width || py < 0 || py > height { continue }

			mut r, mut g, mut b := to_u8(z * 40), to_u8(80 + z * 30), to_u8(200 - z * 20)
			if math.abs(re - 0.5) < 0.008 { r, g, b = 255, 215, 0 }

			app.ctx.draw_rect_filled(px, py, 2, 2, gg.Color{r, g, b, 255})
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
				app.rot_x += (f64(e.mouse_x) - app.last_m_x) * 0.01
				app.rot_y += (f64(e.mouse_y) - app.last_m_y) * 0.01
			}
			app.last_m_x = int(e.mouse_x)
			app.last_m_y = int(e.mouse_y)
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
		window_title: 'Zeta Explorer: Mouse Rotate, Scroll Zoom, WS Move'
		frame_fn: frame
		event_fn: event
		user_data: app
	)
	app.ctx.run()
}
