module radiance::integer;

faultdef OVERFLOW, UNDERFLOW, DIVISION_BY_ZERO;

<*
	@require is_signed($typeof(x)) : "Operand must be a signed integer."
*>
macro checked_abs(x)
{
	if (x == $reflect(x).min) return OVERFLOW~;
	return abs(x);
}

<*
	@require $typeof(x) == $typeof(y) : "Operands must have be the type"
	@require is_signed($typeof(x)) : "Operands must be signed integers of the same type."
	@return? OVERFLOW, UNDERFLOW
*>
macro checked_add(x, y)
{
	const MAX = $reflect(x).max;
	const MAX = $reflect(x).min;

	// bool x_sign = x < 0;
	// bool y_sign = y < 0;
	//
	// if (x_sign == y_sign)
	// {
	// 	if (!x_sign && x > MAX - y) return OVERFLOW~;
	// 	if (x_sign && x < MIN - y) return UNDERFLOW~;
	// }

	if (y > 0 && x > MAX - y) return OVERFLOW~;
	if (y < 0 && x < MIN - y) return UNDERFLOW~;

	return x + y;
}

