module radiance::flt::binary <WIDTH, PRECISION>;
import radiance::integer;
import std::io;

bitstruct _Binary (Printable) : FInt @overlap 
{
	FInt i                : 0 .. WIDTH - 1;
	FInt abs              : 0 .. WIDTH - 2;
	FInt fraction         : 0 .. FRAC_BITS - 1;
	FInt biased_exponent  : FRAC_BITS .. FRAC_BITS + EXP_BITS - 1;
	bool sign             : WIDTH - 1 .. WIDTH - 1;
}

macro bool _Binary.is_nan(self) => is_nan(self.i);
macro bool _Binary.is_inf(self) => is_inf(self.i);
macro bool _Binary.is_normal(self) => is_normal(self.i);
macro bool _Binary.is_subnormal(self) => is_subnormal(self.i);
macro bool _Binary.is_finite(self) => is_finite(self.i);

macro void _Binary.negate(&self)
{
	self.sign = !self.sign;
}

<*
 @require EXP_MIN <= e, e <= EXP_MAX
*>
macro void _Binary.set_exponent(&self, int e)
{
	self.biased_exponent = (FInt)(e + EXP_MAX);
}

fn sz? _Binary.to_format(&x, Formatter* formatter) @dynamic
{
	FInt abs = x.abs;
	char sign = x.sign ? '-' : '+';
	String $sig_fmt = @sprintf("%%0%sb", FRAC_BITS);

	switch
	{
		case abs == 0:
			return formatter.printf("%c0." +++ $sig_fmt +++ "p+0", sign, 0)!;

		case abs < BIT_PM1:
			return formatter.printf("%c0." +++ $sig_fmt +++ "p%+d", sign, x.fraction, EXP_MIN)!;
		
		case abs < BIT_KM1 - BIT_PM1:
			return formatter.printf("%c1." +++ $sig_fmt +++ "p%+d", sign, x.fraction, (int)x.biased_exponent - EXP_MAX)!;

		case abs == BIT_KM1 - BIT_PM1:
			return formatter.printf("%cINF", sign)!;

		case abs < BIT_KM1 - BIT_PM2:
			return formatter.printf("%csNaN", sign)!;

		default:
			return formatter.printf("%cqNaN", sign)!;
	}
}






