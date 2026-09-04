module radiance::flt::binary <WIDTH, PRECISION>;
import radiance::integer @public;

fn FInt mul2(FInt x, FInt y)
{
	FInt  abs_x, abs_y, max_abs, min_abs;
	FInt  sr;

	abs_x = _abs(x);
	abs_y = _abs(y);

	sr = (x ^ y) & SIGN_MASK;

	if (_special_operands(abs_x, abs_y))
	{
		max_abs = integer::max(abs_x, abs_y);
		min_abs = integer::min(abs_x, abs_y);

		switch
		{
			// Either at least one operand is NaN, or one operand is zero and the other is inf
			case max_abs > INF || (min_abs == 0 && max_abs == INF):
				return QNAN | max_abs;

			// both operands are zero
			case max_abs != INF:
				return sr;

			// both operands are inf
			default:
				return sr | INF;
		}
	}
	return _mul2(abs_x, abs_y, sr);
}

fn FInt _mul2(FInt abs_x, FInt abs_y, FInt sr)
{
	FInt  mx, my;
	FInt  bx, by;
	bool  nx, ny;
	FInt  high_r, low_r, abs_r, u, d;
	FInt  rounding, round, sticky;
	int   mlz_x, mlz_y, em, c, lz_r;

	bx = _biased_exponent(abs_x);
	by = _biased_exponent(abs_y);

	nx = _normal_bit(abs_x);
	ny = _normal_bit(abs_y);

	mx = _normalize(&mlz_x, abs_x);
	my = _normalize(&mlz_y, abs_y);

	high_r = _sig_mul2(&low_r, mx, my);

	c = (int)bit::msb(high_r);

	// Exponent Computation
	//   em = e - EXP_MIN,     e = ex - lz_x + ey - lz_y + c
	//   
	//   ex + ey = (bx - nx) + (by - ny) + 2*EXP_MIN
	//   lz_x + lx_y  = mlz_x + mlz_y - 2*EXP_BITS 
	em = ((int)bx - (int)nx) + ((int)by - (int)ny) - (mlz_x + mlz_y) + (2*EXP_BITS + EXP_MIN) + c;

	d = _split_exponent(&lz_r, em);

	if (_exponent_overflow(d))
	{
		return sr | INF;
	}

	// Normalize
	high_r <<= (int)!c;

	// Subnormalize, lz_r can be very large
	high_r >>= integer::min(lz_r, KM1);

	// Rounding
	sticky = _reduce_or(high_r, K - P - 1) | _reduce_or(low_r);
	round = bit::test(high_r, K - P - 1);

	u = high_r >> (K - P);

	rounding = _round_nearest_even(round, sticky, u);

	abs_r = _round_pack(u, d, rounding);
	return sr | abs_r;
}

<*
 Multiplies 2 normalized significands and returns the full product.

 @param[&out] low_r : "Low half of product."
 @return              "High half of product."
*>
fn FInt _sig_mul2(FInt* low_r, FInt mx, FInt my)
{
	// Computes (1,FRAC_BITS) fixed point product, which results in a (2, 2*FRAC_BITS) fixed point
	// number. Therefore the low word contains (k - 2*p) trailing zeros 
	//
	//    c mr[0] . mr[1] ··· mr[p-1] ··· mr[k-2] : mr[k-1] ··· mr[2p-1] 0 ··· 0
	//
	return integer::_umul{FInt}(low_r, mx, my);
}










