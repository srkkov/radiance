module radiance::iefp::binary;
import radiance::integer;

const K <FInt> = integer::bitsize(FInt);
const K <FInt, SigInt> = K{FInt};

const L <SigInt> = integer::bitsize(SigInt);
const L <FInt, SigInt> = L{SigInt};

const J <ExpInt> = integer::bitsize(ExpInt);
const J <FInt, ExpInt> = J::{ExpInt};

module radiance::iefp::binary <FInt>;
import radiance::integer;

alias bit @local = bit::_bit{FInt};

macro FInt _sign_mask(int p, int w) => bit(p + w - 1);

macro FInt _frac_mask(int p) = bit::mask(p);

macro FInt _inf(int p, int w) => bit(p + w - 1) - bit(p - 1);
macro FInt _qnan(int p, int w) => bit(p + w - 1) - bit(p - 2);

macro FInt _min_subnormal(int p, int w) => 1;
macro FInt _max_subnormal(int p, int w) => bit(p - 1) - 1;
macro FInt _min_normal(int p, int w) => bit(p - 1);
macro FInt _max_normal(int p, int w) => bit(p + w - 1) - bit(p - 1) - 1;

macro bool _is_valid_format(int p, int w)
{
	return p > 2 && w > 2 && p + w <= K;
}

macro bool _is_valid_float(int p, int w, FInt x)
{
	return _is_valid_format(p, w) && bit::clear_low(x, p + w) == 0;
}

macro bool _abs_is_zero(int p, int w, FInt x) => x == 0;
macro bool _abs_is_subnormal(int p, int w, FInt x) => x > 0 && x < _min_normal(p, w, x);
macro bool _abs_is_normal(int p, int w, FInt x) =>  x >= _min_normal(p, w, x) && x < _inf(p, w, x);
macro bool _abs_is_finite(int p, int w, FInt x) => x < _inf(p, w, x);
macro bool _abs_is_regular(int p, int w, FInt x) => x > 0 && x < _inf(p, w, x);
macro bool _abs_is_inf(int p, int w, FInt x) => x == _inf(p, w, x);
macro bool _abs_is_nan(int p, int w, FInt x) => x > _inf(p, w, x);
macro bool _abs_is_snan(int p, int w, FInt x) => x > _inf(p, w, x) && x < _qnan(p, w, x);
macro bool _abs_is_qnan(int p, int w, FInt x) => x >= _qnan(p, w, x);


module radiance::iefp::binary <ExpInt>;

<*
 @require[w] w >= 1, w <= J - 1
*>
macro ExpInt exp_max(int w) => ((ExpInt)1 << (w - 1)) - 1;

macro ExpInt exp_min(int w) => (ExpInt)1 - exp_max(w);

// bitstruct _BinaryBits : FInt <FInt, PREC, EXP_WIDTH> @overlap
// {
// 	FInt i                : 0 .. WIDTH - 1;
// 	FInt abs              : 0 .. WIDTH - 2;
// 	FInt fraction         : 0 .. FRAC_BITS - 1;
// 	FInt biased_exponent  : FRAC_BITS .. FRAC_BITS + EXP_BITS - 1;
// 	bool sign             : WIDTH - 1 .. WIDTH - 1;
// }
//
// macro bool _Binary.is_nan(self) => is_nan(self.i);
// macro bool _Binary.is_inf(self) => is_inf(self.i);
// macro bool _Binary.is_normal(self) => is_normal(self.i);
// macro bool _Binary.is_subnormal(self) => is_subnormal(self.i);
// macro bool _Binary.is_finite(self) => is_finite(self.i);
//
// macro void _Binary.negate(&self)
// {
// 	self.sign = !self.sign;
// }

// <*
//  @require EXP_MIN <= e, e <= EXP_MAX
// *>
// macro void _Binary.set_exponent(&self, int e)
// {
// 	self.biased_exponent = (FInt)(e + EXP_MAX);
// }
//
// fn sz? _Binary.to_format(&x, Formatter* formatter) @dynamic
// {
// 	FInt abs = x.abs;
// 	char sign = x.sign ? '-' : '+';
// 	String $sig_fmt = @sprintf("%%0%sb", FRAC_BITS);
//
// 	switch
// 	{
// 		case abs == 0:
// 			return formatter.printf("%c0." +++ $sig_fmt +++ "p+0", sign, 0)!;
//
// 		case abs < BIT_PM1:
// 			return formatter.printf("%c0." +++ $sig_fmt +++ "p%+d", sign, x.fraction, EXP_MIN)!;
//
// 		case abs < BIT_KM1 - BIT_PM1:
// 			return formatter.printf("%c1." +++ $sig_fmt +++ "p%+d", sign, x.fraction, (int)x.biased_exponent - EXP_MAX)!;
//
// 		case abs == BIT_KM1 - BIT_PM1:
// 			return formatter.printf("%cINF", sign)!;
//
// 		case abs < BIT_KM1 - BIT_PM2:
// 			return formatter.printf("%csNaN", sign)!;
//
// 		default:
// 			return formatter.printf("%cqNaN", sign)!;
// 	}
// }






