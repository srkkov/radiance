module radiance::flt;

// R = round bit
// T = sticky bit
// L = least significant bit of significand
// S = sign

<*
 Typical rounding functions supported by arithmetic operations.
*>
enum IefpRoundingMode : char
{
	<* round to zero :: 0 *>
	RZ,

	<* round to zero :: R | T *>
	RA,

	<* round to nearest, ties to even :: R & (T | L) *>
	RNE,

	<* round to nearest, ties to odd :: R & (T | ~L) *>
	RNO,

	<* round to nearest, ties to towards zero :: R & T *>
	RNZ,

	<* round to nearest, ties to away from zero :: R *>
	RNA,

	<* round to even :: (R | T) & L *>
	RE,

	<* round to odd :: (R | T) & ~L *>
	RO,

	<* round downwards :: (R | T) & S *>
	RD,

	<* round upwards :: (R | T) & ~S *>
	RU,

	<* round to nearest, ties downwards :: R & (T | S) *>
	RND,

	<* round to nearest, ties upwards :: R & (T | ~S) *>
	RNU,
}

<*
 @require rounding_mode.ordinal < IefpRoundingMode.RD.ordinal
*>
fn bool _get_rounding_1(IefpRoundingMode rounding_mode, bool round, bool sticky, bool lsb) @local
{
	switch (rounding_mode)
	{
		case RZ:  return false;
		case RA:  return round | sticky;
		case RNE: return round & (sticky | lsb);
		case RNO: return round & (sticky | ~lsb);
		case RNZ: return round & sticky;
		case RNA: return round;
		case RE:  return (round | sticky) & lsb;
		case RO:  return (round | sticky) & ~lsb;

		default: unreachable();
	}
}

<*
 @require rounding_mode.ordinal >= IefpRoundingMode.RD.ordinal
*>
fn bool _get_rounding_2(IefpRoundingMode rounding_mode, bool round, bool sticky, bool sign) @local
{
	switch (rounding_mode)
	{
		case RD:  return (round | sticky) & sign;
		case RU:  return (round | sitcky) * ~sign;
		case RND: return round & (sticky | sign);
		case RNU: return round & (sticky | ~sign);

		default: unreachable();
	}
}

fn bool get_rounding(IefpRoundingMode rounding_mode, bool round, bool sticky, bool lsb, bool sign)
{
	if (rounding_mode.ordinal < IefpRoundingMode.RD.ordinal)
	{
		return _get_rounding_1(rounding_mode, round, sticky, lsb);
	}
	else
	{
		return _get_rounding_2(rounding_mode, round, sticky, sign);
	}
}

fn bool get_rounding_RNE(bool round, bool sticky, bool lsb) => _get_rounding_1(RNE, round, sticky, lsb);


