import gg
import math

const width  = 800
const height = 800
const scale  = 100.0 // Zwiększyłem skalę, by lepiej widzieć "trafienia" w środek

// Własna struktura, żeby uniknąć problemów z gg.Pos
struct Point {
mut:
	x f32
	y f32
}

struct App {
mut:
	gg     &gg.Context = unsafe { nil }
	t      f64
	points []Point
}

// Funkcja Eta Dirichleta
fn eta(re f64, im f64) (f64, f64) {
	mut sum_re := 0.0
	mut sum_im := 0.0
	for n in 1 .. 200 {
		term_re := math.pow(n, -re)
		angle := -im * math.log(n)
		if n % 2 == 0 {
			sum_re -= term_re * math.cos(angle)
			sum_im -= term_re * math.sin(angle)
		} else {
			sum_re += term_re * math.cos(angle)
			sum_im += term_re * math.sin(angle)
		}
	}
	return sum_re, sum_im
}

fn frame(mut app App) {
	app.gg.begin()

	// 1. Rysujemy osie współrzędnych
	app.gg.draw_line(0, height/2, width, height/2, gg.gray)
	app.gg.draw_line(width/2, 0, width/2, height, gg.gray)

	// 2. Rysujemy skalę (podziałkę co 1 jednostkę)
	for i in -10 .. 11 {
		if i == 0 { continue }
		// Pionowe kreski na osi X
		x_tick := f32(width/2 + i * scale)
		app.gg.draw_line(x_tick, height/2 - 5, x_tick, height/2 + 5, gg.gray)

		// Poziome kreski na osi Y
		y_tick := f32(height/2 - i * scale)
		app.gg.draw_line(width/2 - 5, y_tick, width/2 + 5, y_tick, gg.gray)
	}

	// 3. Obliczamy nowy punkt
	z_re, z_im := eta(0.5, app.t)
	new_x := f32(width/2 + z_re * scale)
	new_y := f32(height/2 - z_im * scale)
	app.points << Point{x: new_x, y: new_y}

	// 4. Rysujemy ścieżkę
	for i in 0 .. app.points.len - 1 {
		p1 := app.points[i]
		p2 := app.points[i+1]
		app.gg.draw_line(p1.x, p1.y, p2.x, p2.y, gg.white)
	}

	// 5. Aktualna pozycja i celownik w (0,0)
	app.gg.draw_circle_filled(new_x, new_y, 3, gg.red)
	app.gg.draw_circle_empty(width/2, height/2, 5, gg.green) // Mały celownik w zerze

	// 6. Wyświetlamy aktualne "t" (część urojoną)
	app.gg.draw_text(10, 10, 'Część urojona (t): ${app.t:.2f}',
		size: 20
		color: gg.yellow
	)
	app.gg.draw_text(10, 35, 'Skala: 1 jednostka = ${scale}px',
		size: 16
		color: gg.gray
	)

	// 7. Prędkość animacji
	app.t += 0.02 // Nieco wolniej, żebyś mógł wyłapać zera

	app.gg.end()
}


fn main() {
	mut app := &App{
		t: 0.0
		points: []Point{}
	}
	app.gg = gg.new_context(
		width: width
		height: height
		window_title: 'Riemann Zeta Trace - x = 0.5'
		frame_fn: frame
		user_data: app
		bg_color: gg.black
	)
	app.gg.run()
}
