<*
 @require is_int(Integer)
*>
module radiance::integer <Integer>;

<*
 @require @is_int(x)
*>
macro bool will_cast_exactly(x)
{
	return _is_exact_cast{Integer, $Typeof(x)}(x);
}

<*
 @require @is_int(x)
 @return? OUT_OF_RANGE
*>
macro Integer? try_cast(x)
{
	return _try_cast{Integer, $Typeof(x)}(x);
}

<*
 @require @is_int(x)
*>
macro Integer exact_cast(x)
{
	return _try_cast{Integer, $Typeof(x)}(x)!!;
}

<*
 @require @is_int(x)
*>
macro Integer saturating_cast(x)
{
	return _saturating_cast{Integer, $Typeof(x)}(x);
}

<*
 @require is_int(Integer), is_int(FromInteger)
*>
module radiance::integer <Integer, FromInteger> @private;

const bool UNSIGNED_TO_UNSIGNED = !is_signed(FromInteger) && !is_signed(Integer);
const bool UNSIGNED_TO_SIGNED   = !is_signed(FromInteger) &&  is_signed(Integer);
const bool   SIGNED_TO_UNSIGNED =  is_signed(FromInteger) && !is_signed(Integer);
const bool   SIGNED_TO_SIGNED   =  is_signed(FromInteger) &&  is_signed(Integer);

const int TO_SIZE = bitsize(Integer);
const int FROM_SIZE = bitsize(FromInteger);

const Integer MIN = Integer::min;
const Integer MAX = Integer::max;

macro bool _will_cast_inexactly(FromInteger x)
{
	$switch:
		$case UNSIGNED_TO_UNSIGNED:
			return TO_SIZE < FROM_SIZE &&& x > MAX;

		$case UNSIGNED_TO_SIGNED:
			return TO_SIZE <= FROM_SIZE &&& x > MAX;

		$case SIGNED_TO_UNSIGNED:
			return  x < 0 || (TO_SIZE < FROM_SIZE &&& x > MAX);

		$case SIGNED_TO_SIGNED:
			return TO_SIZE < FROM_SIZE &&& (x < MIN || x > MAX);
	$endswitch
}

macro bool _will_cast_exactly(FromInteger x) => !_will_cast_inexactly(x);

<*
 @return? OUT_OF_RANGE
*>
fn Integer? _try_cast(FromInteger x)
{
	if (_will_cast_inexactly(x))
	{
		return OUT_OF_RANGE~;
	}
	return (Integer)x;
}

fn Integer _exact_cast(FromInteger x) => _try_cast(x)!!;

fn Integer _saturating_cast(FromInteger x)
{
	$switch:
		$case UNSIGNED_TO_UNSIGNED:
			x = TO_SIZE < FROM_SIZE ??? min(x, (FromInteger)MAX) : x;

		$case UNSIGNED_TO_SIGNED:
			x = TO_SIZE <= FROM_SIZE ??? min(x, (FromInteger)MAX) : x;

		$case SIGNED_TO_UNSIGNED:
			x = max(x, (FromInteger)MIN);
			x = TO_SIZE <= FROM_SIZE ??? min(x, (FromInteger)MAX) : x;

		$case SIGNED_TO_SIGNED:
			x = TO_SIZE < FROM_SIZE ??? clamp(x, (FromInteger)MIN, (FromInteger)MAX) : x;
	$endswitch
	return (Integer)x;
}

