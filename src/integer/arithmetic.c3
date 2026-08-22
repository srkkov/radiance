// =========================
// --- Unsigned Addition ---
// =========================
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

 @require[carry_in] carry_in <= 1
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

 @param x                 : "K-bit unsigned integer"
 @param y                 : "K-bit unsigned integer"
 @param barrow_in         : "1-bit unsigned integer"
 @param[&out] barrow_out  : "1-bit unsigned integer"

 @require[barrow_in] barrow_in <= 1
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

// ===============================
// --- Unsigned Multiplication ---
// ===============================

const HAS_DOUBLE = has_doublewidth_type(Unsigned);
alias UnsignedDouble @if (HAS_DOUBLE) = doublewidth_type(Unsigned);

<*
 Performs full-width unsigned multiplication.

 @param x : "K-bit unsigned integer"
 @param y : "K-bit unsigned integer"
 @return    "2K-bit unsigned integer"

 @ensure return <= ((UnsignedDouble)1 << K) * ((UnsignedDouble)1 << K - 2) + (UnsignedDouble)1
*>
fn UnsignedDouble _umul_wide(Unsigned x, Unsigned y) @inline @if (HAS_DOUBLE)
{
	return (UnsignedDouble)x * (UnsignedDouble)y;
}

<*
 Performs unsigned multiplication and returns the high K bits of the result.

 @param x : "K-bit unsigned integer"
 @param y : "K-bit unsigned integer"
 @return "K-bit unsigned integer"

 @ensure return < Unsigned::max
*>
fn Unsigned _umulhi(Unsigned x, Unsigned y) @inline @if(HAS_DOUBLE)
{
	return (Unsigned)bit::_extract_high{UnsignedDouble}(_umul_wide(x, y), K);
}

<*
 Performs full width unsigned multiplication and returns the the product in 2 words.

 @param x       : "K-bit unsigned integer"
 @param y       : "K-bit unsigned integer"
 @param[out] hi : "K-bit unsigned integer"
*>
fn Unsigned _umul(Unsigned* hi, Unsigned x, Unsigned y) @inline @if(HAS_DOUBLE)
{
	UnsignedDouble prod = _umul_wide(x, y);
	*hi = (Unsigned)bit::_extract_high{UnsignedDouble}(prod, K);
	return (Unsigned)bit::_isolate_low{UnsignedDouble}(prod, K);
}

// fn Unsigned _umul_lo_hi(Unsigned* lo, Unsigned* hi, Unsigned x, Unsigned y)

// ==================
// --- Arithmetic ---
// ==================
module radiance::integer <Integer>;
import std::math;

<*
 @require x != Integer::min
*>
fn Integer _abs(Integer x) @inline
{
	$if SIGNED:
		return x < 0 ? -x : x;
	$else
		return x;
	$endif
}

fn Integer _max0(Integer x) @inline
{
	$if SIGNED:
		return x > 0 ? x : 0;
	$else
		return x;
	$endif
}

fn Integer _min0(Integer x) @inline
{
	$if SIGNED:
		return x < 0 ? x : 0;
	$else
		return x;
	$endif
}

fn Integer _max(Integer x, Integer y) @inline
{
	return x > y ? x : y;
}

fn Integer _min(Integer x, Integer y) @inline
{
	return x < y ? x : y;
}

fn Integer _clamp(Integer x, Integer min, Integer max) @inline
{
	return _min(_max(x, min), max);
}

fn Integer _diff(Integer x, Integer y) @inline
{
	return _max(x, y) - _min(x, y);
}

<*
 Swaps variables #x1 and #x2 such that #x1 >= #x2.
*>
macro void @_maxmin(Integer #x1, Integer #x2)
{
	Integer max = _max(#x1, #x2);
	Integer min = _min(#x1, #x2);
	#x1 = max;
	#x2 = min;
}

<*
 Swaps variables #x1 and #x2 such that #x1 <= #x2.
*>
macro void @_minmax(Integer #x1, Integer #x2)
{
	Integer max = _max(#x1, #x2);
	Integer min = _min(#x1, #x2);
	#x1 = min;
	#x2 = max;
}

module radiance::integer;

macro max0(x) => _max0{$Typeof(x)}(x);
macro min0(x) => _min0{$Typeof(x)}(x);
macro @maxmin(#x, #y) => @_maxmin{$Typeof(#x)}(#x, #y);
macro @minmax(#x, #y) => @_minmax{$Typeof(#x)}(#x, #y);

<*
 @require $vaarg.len > 0 : "There must be at least 1 operand."
 @require @is_int(...$vaarg) : "Operands must be integers."
 @require @type_match(...$vaarg) : "Operands must be the same type."
*>
macro max(...)
{
	var $Type = $Typeof($vaarg[0]);
	$switch $vaarg.len:
		$case 1:
			return $vaarg[0];
		$case 2:
			return _max{$Type}($vaarg[0], $vaarg[1]);
		$default:
			return _max{$Type}($vaarg[0], max(...$vaarg[1..]));
	$endswitch
}

<*
 @require $vaarg.len > 0 : "There must be at least 1 operand."
 @require @is_int(...$vaarg) : "Operands must be integers."
 @require @type_match(...$vaarg) : "Operands must be the same type."
*>
macro min(...)
{
	var $Type = $Typeof($vaarg[0]);
	$switch $vaarg.len:
		$case 1:
			return $vaarg[0];
		$case 2:
			return _min{$Type}($vaarg[0], $vaarg[1]);
		$default:
			return _min{$Type}($vaarg[0], min(...$vaarg[1..]));
	$endswitch
}





// =============================
// --- Saturating Arithmetic ---
// =============================
module radiance::integer <Integer>;

fn Integer _saturating_add(Integer x, Integer y)
{
	return Integer.sat_add(x, y);
}

fn Integer _saturating_sub(Integer x, Integer y)
{
	return Integer.sat_sub(x, y);
}

fn Integer _saturating_mul(Integer x, Integer y)
{
	return Integer.sat_mul(x, y);
}

module radiance::integer;

macro saturating_add(x, y) => _saturating_add{$Typeof(x)}(x, y);
macro saturating_sub(x, y) => _saturating_sub{$Typeof(x)}(x, y);
macro saturating_mul(x, y) => _saturating_mul{$Typeof(x)}(x, y);



