module radiance;



// enum RadianceRoundingMode : char
// {
// 	RNE,
// 	RNO,
//
// 	RU,
// 	RD,
//
// 	RA,
// 	RT,
//
// 	RNA,
// 	RNT,
// }

enum RadianceRoundingMode : char
{
	<*
		round to nearest, ties to even
	*>
	NEAREST_EVEN,

	<*
		round to nearest, ties to odd
	*>
	NEAREST_ODD,
	
	<*
		round upwards (towards positive infinity)
	*>
	UPWARDS,

	<*
		round downwards (towards negative infinity)
	*>
	DOWNWARDS,

	<*
		round away from zero
	*>
	AWAY,

	<*
		round towards zero
	*>
	TOWARDS,

	<*
		round to nearest, ties away from zero
	*>
	NEAREST_AWAY,

	<*
		round to nearest, ties towards zero
	*>
	NEAREST_TOWARDS,
}

