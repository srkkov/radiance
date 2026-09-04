module radiance::flt;

enum FltRoundingMode : char
{
	<* round to nearest, ties to even *>
	NEAREST_EVEN,

	<* round towards zero *>
	ZERO,

	<* round upwards (towards positive infinity) *>
	UP,

	<* round downwards (towards negative infinity) *>
	DOWN,

	<* round to nearest, ties to away from zero *>
	NEAREST_AWAY,

	<* round away from zero *>
	AWAY,

	<* round to nearest, ties to odd *>
	NEAREST_ODD,

	<* round to nearest, ties to towards zero *>
	NEAREST_ZERO,
	
	<* round to nearest, ties to towards positive infinity *>
	NEAREST_UP,

	<* round to nearest, ties to towards negative infinity *>
	NEAREST_DOWN,
}

fn bool is_basic_rounding_mode(FltRoundingMode rnd)
{
	$assert(FltRoundingMode.NEAREST_EVEN.ordinal == 0);
	$assert(FltRoundingMode.ZERO.ordinal == 1);
	$assert(FltRoundingMode.UP.ordinal == 2);
	$assert(FltRoundingMode.DOWN.ordinal == 3);

	return rnd.ordinal < 4;
}
