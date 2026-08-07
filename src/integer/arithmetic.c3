module radiance::integer <Unsigned>;
import radiance::integer::bit @public;
import std::math;

const K = bitsize(Unsigned);

<*
 Performs full width addition `return, *carry_out = x + y`.

 @param x : "K-bit unsigned integer."
 @param y : "K-bit unsigned integer."
 @param[&out] carry_out : "1-bit unsigned integer."

 @ensure *carry_out <= 1
*>
fn Unsigned _uadd(Unsigned* carry_out, Unsigned x, Unsigned y) @inline
{
	Unsigned r;
	*carry_out = (Unsigned)std::math::overflow_add(x, y, &r);
	return r;
}

<*
 Performs full width addition with carry, `return, *carry_out = x + y + carry_in`.

 @param x : "K-bit unsigned integer."
 @param y : "K-bit unsigned integer."
 @param carry_in : "1-bit unsigned integer."
 @param[&out] carry_out : "1-bit unsigned integer."

 @require carry_in <= 1
 @ensure *carry_out <= 1
*>
fn Unsigned _uadc(Unsigned* carry_out, Unsigned x, Unsigned y, Unsigned carry_in) @inline
{
	Unsigned r, c0, c1;
	c0 = (Unsigned)std::math::overflow_add(x, y, &r);
	c1 = (Unsigned)std::math::overflow_add(r, carry_in, &r);
	*carry_out = c0 | c1;
	return r;
}

<*
 Performs full width subtraction `return, *barrow_out = x - y`.

 @param x : "K-bit unsigned integer."
 @param y : "K-bit unsigned integer."
 @param[&out] barrow_out : "1-bit unsigned integer."

 @ensure *barrow_out <= 1
*>
fn Unsigned _usub(Unsigned* barrow_out, Unsigned x, Unsigned y) @inline
{
	Unsigned r;
	*barrow_out = (Unsigned)std::math::overflow_sub(x, y, &r);
	return r;
}

<*
 Performs full width subtraction with barrow, `return, *barrow_out = x - (y + barrow_in)`.

 @param x : "K-bit unsigned integer."
 @param y : "K-bit unsigned integer."
 @param barrow_in : "1-bit unsigned integer."
 @param[&out] barrow_out : "1-bit unsigned integer."

 @require barrow_in <= 1
 @ensure *barrow_out <= 1
*>
fn Unsigned _usbb(Unsigned* barrow_out, Unsigned x, Unsigned y, Unsigned barrow_in) @inline
{
	Unsigned r, c0, c1;
	c0 = (Unsigned)std::math::overflow_sub(x, y, &r);
	c1 = (Unsigned)std::math::overflow_sub(r, barrow_in, &r);
	*barrow_out = c0 | c1;
	return r;
}

const HAS_DOUBLE = has_doublewidth_type(Unsigned);
alias UnsignedDouble @if (HAS_DOUBLE) = doublewidth_type(Unsigned);

<*
 Performs full width unsigned multiplication.

 @param x : "K-bit unsigned integer."
 @param y : "K-bit unsigned integer."
 @return "2K-bit unsigned integer."

 @ensure return <= ((UnsignedDouble)1 << K) * ((UnsignedDouble)1 << K - 2) + (UnsignedDouble)1
*>
fn UnsignedDouble _umul_wide(Unsigned x, Unsigned y) @inline @if (HAS_DOUBLE)
{
	return (UnsignedDouble)x * (UnsignedDouble)y;
}

<*
 Performs unsigned multiplication and returns the highest K bits of the result.

 @param x : "K-bit unsigned integer."
 @param y : "K-bit unsigned integer."
 @return "K-bit unsigned integer."

 @ensure return < Unsigned::max
*>
fn Unsigned _umulhi(Unsigned x, Unsigned y) @inline @if(HAS_DOUBLE)
{
	return (Unsigned)bit::_extract_high{UnsignedDouble}(_umul_wide(x, y), K);
}

<*

 @param x : "K-bit unsigned integer."
 @param y : "K-bit unsigned integer."
 @param hi : "K-bit unsigned integer."
*>
fn Unsigned _umul(Unsigned* hi, Unsigned x, Unsigned y) @inline @if(HAS_DOUBLE)
{
	UnsignedDouble prod = _umul_wide(x, y);
	*hi = (Unsigned)bit::_extract_high{UnsignedDouble}(prod, K);
	return (Unsigned)bit::_truncate{UnsignedDouble}(prod, K);
}









module radiance::integer;
import std::math;

<*
 @require @is_int(x)
 @require x != $Typeof(x)::max
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
 @require @is_int(x, min, max) : "Operands must be integers."
 @require @type_match(x, min, max) : "Operands must be the same type."
*>
macro clamp(x, min, max)
{
	return min2(max2(x, min), max);
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













// ---Saturating Arithmetic---

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the same type."
*>
macro saturating_add(x, y)
{
	return x.sat_add(y);
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the same type."
*>
macro saturating_sub(x, y)
{
	return x.sat_sub(y);
}

<*
 @require @is_int(x, y) : "Operands must be integers."
 @require @type_match(x, y) : "Operands must be the same type."
*>
macro saturating_mul(x, y)
{
	return x.sat_mul(y);
}













