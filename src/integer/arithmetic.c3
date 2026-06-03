module radiance::integer;
import std::math;

<*
	@require is_int($Typeof(value))
	@require is_int($Typeof(lower))
	@require is_int($Typeof(upper))
	@require lower >= 0, upper >= lower
*>
macro bool in_range_abs(value, lower, upper)
{
	if (value == $reflect(value).max) return false;
	return lower <= abs(value) && abs(value) <= upper;
}

<*
	@require x != $reflect(value).max
*>
macro abs(x)
{
	return x < 0 ? -x : x;
}

// macro max(x, y) => std::math::max(x, y);
// macro min(x, y) => std::math::min(x, y);

<*
	@require is_int($Typeof(x))
	@require $Typeof(x) == $Typeof(y) : "Operands must be the same type."
*>
macro max(x, y)
{
	return x > y ? x : y;
}

<*
	@require is_int($Typeof(x)) : "Operands must be integers"
	@require $Typeof(x) == $Typeof(y) : "Operands must be the same type."
*>
macro min(x, y)
{
	return x < y ? x : y;
}

<*
	@require is_int($Typeof(x)) : "Operands must be integers"
	@require $Typeof(x) == $Typeof(y) : "Operands must be the same type."
*>
macro diff(x, y)
{
	return max(x,y) - min(x,y);
}

<*
	@require is_unsigned($Typeof(a)) : "Operands must be unsigned integers."
	@require $Typeof(a) == $Typeof(b) : "Operands must be the same type."
	@require $Typeof(*carry) == $Typeof(a) : "Outputs must be pointers of the operand type."
	@param[&out] carry
	@ensure *carry <= 1
*>
macro uadd(carry, a, b)
{
	var $Int = $Typeof(a); 
	$Int r;
	*carry = ($Int)std::math::overflow_add(a, b, &r);
	return r;
}

<*
	@require is_unsigned($Typeof(a)) : "Operands must be unsigned integers."
	@require $Typeof(b) == $Typeof(a) : "Operands must be the same type."
	@require $Typeof(carry_in) == $Typeof(a) : "Operands must be the same type."
	@require $Typeof(*carry) == $Typeof(a) : "Outputs must be pointers of the operand type."
	@param[&out] carry
	@ensure *carry <= 1
*>
macro uadc(carry, a, b, carry_in)
{
	var $Int = $Typeof(a);
	$Int r, carry0, carry1;
	carry0 = ($Int)std::math::overflow_add(a, b, &r);
	carry1 = ($Int)std::math::overflow_add(r, carry_in, &r);
	*carry = carry0 | carry1;
	return r;
}

<*
	@require is_unsigned($Typeof(a)) : "Operands must be unsigned integers."
	@require $Typeof(a) == $Typeof(b) : "Operands must be the same type."
	@require $Typeof(*barrow) == $Typeof(a) : "Outputs must be pointers of the operand type."
	@param[&out] barrow
	@ensure *barrow <= 1
*>
macro usub(barrow, a, b)
{
	var $Int = $Typeof(a); 
	$Int r;
	*barrow = ($Int)std::math::overflow_sub(a, b, &r);
	return r;
}

<*
	@require is_unsigned($Typeof(a)) : "Operands must be unsigned integers."
	@require $Typeof(b) == $Typeof(a) : "Operands must be the same type."
	@require $Typeof(barrow_in) == $Typeof(a) : "Operands must be the same type."
	@require $Typeof(*barrow) == $Typeof(a) : "Outputs must be pointers of the operand type."
	@param[&out] barrow
	@ensure *barrow <= 1
*>
macro usbb(barrow, a, b, barrow_in)
{
	var $Int = $Typeof(a);
	$Int r, barrow0, barrow1;
	barrow0 = ($Int)std::math::overflow_sub(a, b, &r);
	barrow1 = ($Int)std::math::overflow_sub(r, barrow_in, &r);
	*barrow = barrow0 | barrow1;
	return r;
}

<*
	@require is_unsigned($Typeof(a)) : "Operands must be unsigned integers."
	@require $Typeof(a) == $Typeof(b) : "Operands must be the same type."    
	@ensure return < $Typeof(a).max - 1
*>
macro umulhi(a, b)
{
	var $DInteger = doublewidth_type($Typeof(a));
	$DInteger p = ($DInteger)a * ($DInteger)b;
	return p.hi();
}

<*
	@require $Typeof(b) == $Typeof(b) : "Operands must be the same type."
	@require has_doublewidth_type($Typeof(a)) : "Operand type must have a doublewidth equivalent."
	@require $Typeof(*prod_hi) == $Typeof(a) || $Typeof(*prod_hi) == doublewidth_type($Typeof(a)) : "Output type must fit result."
	@param[out] prod_hi
	@ensure *prod_hi < $reflect(a).max - 1
*>
macro umul(prod_hi, a, b)
{
	var $DInteger = doublewidth_type($Typeof(a));
	$DInteger p = ($DInteger)a * ($DInteger)b;
	*prod_hi = ($Typeof(*prod_hi))(p.hi());
	return p.lo();
}




















