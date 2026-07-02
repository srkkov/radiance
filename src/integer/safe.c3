module radiance::integer;
import std::math;
//  overflow_add
//  overflow_sub
//  overflow_mul

faultdef OUT_OF_RANGE, DIVISION_BY_ZERO;

<*
 @require @is_int(x) : "Operand must be an integer."
 @return? OUT_OF_RANGE
*>
macro checked_abs(x)
{
	$if @is_signed(x):
		if (x == $Typeof(x)::min) return OUT_OF_RANGE~;
		return abs(x);
	$else
		return x;
	$endif
}

<*
 @require @is_signed(x) : "Operand must be a signed integer."
 @return? OUT_OF_RANGE
*>
macro checked_neg(x)
{
	if (x == $Typeof(x)::min) return OUT_OF_RANGE~;
	return -x;
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the type."
 @require @is_signed(x) : "Operands must be signed integers of the same type."
 @return? OUT_OF_RANGE
*>
macro checked_add(x, y)
{
	$Typeof(x) r;
	if (std::math::overflow_add(x, y, &r)) return OUT_OF_RANGE~;
	return r;
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the type."
 @require @is_signed(x) : "Operands must be signed integers of the same type."
 @return? OUT_OF_RANGE
*>
macro checked_sub(x, y)
{
	$Typeof(x) r;
	if (std::math::overflow_sub(x, y, &r)) return OUT_OF_RANGE~;
	return r;
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the type."
*>
macro checked_mul(x, y)
{
	$Typeof(x) r;
	if (std::math::overflow_mul(x, y, &r)) return OUT_OF_RANGE~;
	return r;
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the type."
 @return? DIVISION_BY_ZERO, OUT_OF_RANGE
*>
macro checked_div(x, y)
{
	if (!y) return DIVISION_BY_ZERO~;
	$if @is_signed(x):
		if (x == $Typeof(x)::min && y == -1) return OUT_OF_RANGE~;
	$endif
	return x / y;
}

// TODO: remainder









