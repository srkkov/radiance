module radiance::integer;
import std::math;
// From std::math
//  overflow_add
//  overflow_sub
//  overflow_mul

<*
 @require @is_int(value, lower, upper)
 @require lower >= 0, upper >= lower
*>
macro bool in_range_abs(value, lower, upper)
{
	if (value == $reflect(value).max) return false;
	return lower <= abs(value) && abs(value) <= upper;
}

<*
 @require @is_int(x)
 @require x != $reflect(value).max
*>
macro abs(x)
{
	return x < 0 ? -x : x;
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the same type."
*>
macro max2(x, y)
{
	return x > y ? x : y;
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the same type."
*>
macro min2(x, y)
{
	return x < y ? x : y;
}

<*
 @require $vaarg.len > 0 : "There must be at least 1 operand."
 @require @is_int(...$vaarg) : "Operands must be integers."
 @require @type_match(...$vaarg) : "Operands must be the same type."
*>
macro max(...)
{
	$switch $vaarg.len:
		$case 1:
			return $vaarg[0];
		$case 2:
			return max2($vaarg[0], $vaarg[1]);
		$default:
			return max2($vaarg[0], max(...$vaarg[1..]));
	$endswitch
}

<*
 @require $vaarg.len > 0 : "There must be at least 1 operand."
 @require @is_int(...$vaarg) : "Operands must be integers."
 @require @type_match(...$vaarg) : "Operands must be the same type."
*>
macro min(...)
{
	$switch $vaarg.len:
		$case 1:
			return $vaarg[0];
		$case 2:
			return min2($vaarg[0], $vaarg[1]);
		$default:
			return min2($vaarg[0], min(...$vaarg[1..]));
	$endswitch
}

<*
 @require @is_int(x) : "Operands must be integers"
 @require @type_match(x, y) : "Operands must be the same type."
*>
macro diff(x, y)
{
	return max(x, y) - min(x, y);
}

<*
 @require @is_unsigned(y) : "Operands must be unsigned integers."
 @require @type_match(x, y, *carry) : "Operands and output must be the same type."
 @param[&out] carry
 @ensure *carry <= 1
*>
macro uadd(carry, x, y)
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
 @require $Typeof(*prod_hi) == $Typeof(a)  : "Output type must fit result."
 @param[out] prod_hi
 @ensure *prod_hi < $reflect(a).max - 1
*>
macro mul(prod_hi, a, b)
{
	var $Integer = $Typeof(a);
	var $DInteger = doublewidth_type($Typeof(a));
	$DInteger p = ($DInteger)a * ($DInteger)b;
	*prod_hi = ($Integer)p.hi();
	return ($Integer)p.lo();
}










<*
 @require @is_int(x, min, max) : "Operands must be integers."
 @require @type_match(x, min, max) : "Operands must be the same type."
*>
macro clamp(x, min, max)
{
	return min2(max2(x, min), max);
}



// ---Saturating Arithmetic---

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the same type."
*>
macro sat_add(x, y)
{
	return x.sat_add(y);
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the same type."
*>
macro sat_sub(x, y)
{
	return x.sat_sub(y);
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the same type."
*>
macro sat_mul(x, y)
{
	return x.sat_mul(y);
}

<*
 @require is_int($Type) : "The type to be saturated to must be an integer type."
 @require @is_int(x) : "The value to be saturated must be an integer."
*>
macro saturating_cast($Type, x)
{
	return clamp(x, $Type::min, $Type::max);
}












