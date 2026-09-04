module radiance::flt::binary <WIDTH, PRECISION>;
import radiance::integer;

<*
 Computes ∘(x ± y), addition or subtraction if sign is false or true.
*>
fn FInt add2(FInt x, FInt y, bool sign)
{
	FInt  sr, sx, sy;
	FInt  abs_x, abs_y;
	FInt  max_abs, min_abs;
	bool  s;

	abs_x = _abs(x);
	abs_y = _abs(y);

	sx = x & SIGN_MASK;
	sy = y & SIGN_MASK;

	// effective operation, 0 = addition, 1 = subtraction
	s = (sx != sy) != sign;


	if (abs_x == abs_y)
	{
		sr = s ? 0 : sx;
	}
	else
	{
		sr = ((FInt)(s && abs_x < abs_y) << KM1) ^ sx;
	}

	if (_special_operands(abs_x, abs_y))
	{
		max_abs = integer::max(abs_x, abs_y);
			
		// Either at least one operand is NaN or |x| and |y| are infinities with opposite signs.
		if (max_abs > INF || (s && abs_x == INF && abs_y == INF))
		{
			// we propogate the NaN with the larger payload
			// TODO: Customizable NaN progapation rule
			return QNAN | max_abs;
		}

		// |x| and |y| are infinities with the same sign, or they are zeros
		// zero or infinity with respective sign.
		return sr | max_abs;
	}

	// x = -y not covered by general case
	// only for RN
	if (abs_x == abs_y && s) return 0; // +0

	integer::@maxmin(abs_x, abs_y);

	return _add2(abs_x, abs_y, s, sr);
}

<*
 Computes ∘(|x| ± |y|), depending on the value of s.

 @require abs_x > abs_y || (!s && abs_x == abs_y)
 @require sr & SIGN_MASK == sr
*>
fn FInt _add2(FInt abs_x, FInt abs_y, bool s, FInt sr)
{
	FInt  mx, my;
	FInt  bx, by;
	bool  nx, ny;
	FInt  high_r, abs_r, u, d;
	FInt  rounding, round, sticky;
	int   e_diff, t, n, c, lz_r;

	bx = _biased_exponent(abs_x);
	by = _biased_exponent(abs_y);

	nx = _normal_bit(abs_x);
	ny = _normal_bit(abs_y);

	// save for later
	t = (int)bx - (int)nx;

	// e_diff = ex - ey
	e_diff = t - ((int)by - (int)ny);

	// We do not normalize subnormal inputs, since the possibility of cancellation
	// means we have to normalize the result anyway.

	// m =  0 ··· m[0] . m[1] m[2] ··· m[p-1] 0 0 0

	mx = (((FInt)nx << FRAC_BITS) | bit::isolate_low(abs_x, FRAC_BITS)) << 3;
	my = (((FInt)ny << FRAC_BITS) | bit::isolate_low(abs_y, FRAC_BITS)) << 3;

	high_r = _sig_add2(mx, my, e_diff, s);

	n = bit::lzcnt(high_r);

	// Normalize
	high_r <<= n;
	n -= K - P - 3;

	// At this point, er = ex - n

	// lz_r = max(EXP_MIN - er, 0) = max((nx - bx) + n, 0)
	lz_r = integer::max0(n - t);

	// d = max(er, EXP_MIN) - EXP_MIN = max(er - EXP_MIN, 0)
	d = (FInt)integer::max0(t - n);

	// overflow if er > EXP_MAX
	if (d >= 2 * EXP_MAX)
	{
		return sr | INF;
	}

	// Subnormalize
	high_r >>= lz_r;

	sticky = _reduce_or(high_r, K - P - 1);
	round = bit::test(high_r, K - P - 1);

	u = high_r >> (K - P);

	rounding = _round_nearest_even(round, sticky, u);

	abs_r = _round_pack(u, d, rounding);
	return sr | abs_r;
}

<*
 Aligns and computes the addition or subtraction of significands (with space for GRS bits).
*>
fn FInt _sig_add2(FInt mx, FInt my, int e_diff, bool s) @inline
{
	// Besides alignment, we are doing 2 things here.
	//  1. Doing only a (p+3)-bit addition/subtraction.
	//  2. Precomputing the sticky bit before the addition/subtraction is done.
	//
	// This is accomplished by computing the sticky of the low bits of my, and *merging it* with
	// the addition/subtraction. That is, this sticky bit is attached to the significand.
	//
	//   high_y = 0 ··· 0 my[0] my[1] ··· my[p+1-δ] OR( my[p+2-δ .. p+2] )
	// 
	// First note that if the sticky is zero, then we just truncate my to p+3 bits.
	//
	// Addition:
	//  All low bits would be added to zeros, thus they have no impact on the high part of the sum.
	//  This also means we can directly compute the sticky bit before the addition, merging it has 
	//  no effect.
	//
	// Subtraction:
	//  All discarded bits would be subtracted from zeros, thus if any of the discarded bits are 1, 
	//  a barrow will propagate as just the same as an effective subtraction by 1. 
	//  And then thats the actual sticky because IDK.

	FInt high_y, sticky;

	// align
	high_y = my >> integer::min(KM1, e_diff); 

	// compute sticky
	switch 
	{
		// no bits discarded
		case e_diff <= 3:
			sticky = 0;

		// all bits discarded, but since my is nonzero, sticky is 1
		case e_diff >= PRECISION + 3:
			sticky = 1;

		// some bits discarded, we directly compute the sticky of these discarded bits
		default:
			sticky = _reduce_or(my, e_diff);
	}

	// merge
	high_y |= sticky;

	return mx + (s ? -high_y : high_y);
}











	//  s | |x| ? |y| || sr
	// --------------------
	//  0 |     >     || sx
	//  0 |     <     || sx
	//  1 |     >     || sx
	//  1 |     <     || !sx
