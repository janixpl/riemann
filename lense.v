import gg
import math
import math.complex as cmplx
import time

const width = 600
const height = 600
const scale = 5.0

fn pow_f64_complex(n f64, s cmplx.Complex) cmplx.Complex {
	if n <= 0 { return cmplx.complex(0, 0) }
	ln_n := math.log(n)
	arg_re := s.re * ln_n
	arg_im := s.im * ln_n
	exp_re := math.exp(arg_re)
	return cmplx.complex(exp_re * math.cos(arg_im), exp_re * math.sin(arg_im))
}

fn zeta(s cmplx.Complex) cmplx.Complex {
	mut res_re := 0.0
	mut res_im := 0.0
	s_neg := cmplx.complex(-s.re, -s.im)

	for n in 1 .. 60 {
		term := pow_f64_complex(f64(n), s_neg)
		if n % 2 == 0 {
			res_re -= term.re
			res_im -= term.im
		} else {
			res_re += term.re
			res_im += term.im
		}
	}

	one_minus_s := cmplx.complex(1.0 - s.re, -s.im)
	pow_part := pow_f64_complex(2.0, one_minus_s)
	denom_re := 1.0 - pow_part.re
	denom_im := -pow_part.im

	d := denom_re * denom_re + denom_im * denom_im
	if d == 0 { return cmplx.complex(0, 0) }

	return cmplx.complex(
		(res_re * denom_re + res_im * denom_im) / d,
		(res_im * denom_re - res_re * denom_im) / d
	)
}

fn frame(mut ctx gg.Context) {
	ctx.begin()
	ctx.draw_rect_filled(0, 0, width, height, gg.white)

	// time.ticks() zwraca i64, konwertujemy na f64 dla obliczeń
	t := f64(time.ticks()) / 1000.0 * 0.2

	for y := 0; y < height; y += 4 { // Zwiększyłem skok do 4 dla lepszej płynności
		for x := 0; x < width; x += 4 {
			re := 0.5 + (f64(x) - width / 2.0) / (width / scale)
			im := t + (f64(y) - height / 2.0) / (height / scale)

			s := cmplx.complex(re, im)
			w := zeta(s)

			grid_size := 0.5
			line_width := 0.04

			if math.abs(math.mod(w.re, grid_size)) < line_width ||
			   math.abs(math.mod(w.im, grid_size)) < line_width {
				ctx.draw_rect_filled(x, y, 4, 4, gg.black)
			}
		}
	}
	ctx.end()
}

fn main() {
	mut ctx := gg.new_context(
		width: width
		height: height
		window_title: 'Riemann Zeta Lens - Vlang'
		frame_fn: frame
	)
	ctx.run()
}
