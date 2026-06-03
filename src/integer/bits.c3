module radiance::integer;

// --- const macros ---

<*
	@require is_unsigned($IntType)
	@require $width > 0, $begin >= 0
	@require $begin + $width <= bitsize($IntType)
*>
macro const_bitmask($IntType, uint $width, uint $begin = 0) @const
{
	$IntType $mask = ~($IntType)0 >> (bitsize($IntType) - $width);
	return $mask << $begin;
}

// --- implementation template ---

<*
	@require is_unsigned(IntType)
	@require width > 0, begin >= 0
	@require begin + width <= bitsize(IntType)
*>
macro IntType bitmask(int width, int begin = 0) <IntType>
{
	IntType mask = IntType::max >> (bitsize(IntType) - width);
	return mask << begin;
}

<*
	@require is_unsigned(IntType)
	@require width > 0, begin >= 0
	@require begin + width <= bitsize(IntType)
*>
macro IntType bitmask2(int width, int begin = ...) <IntType>
{
	IntType mask = IntType::max >> (bitsize(IntType) - width);

	$if $defined(begin):
		return mask << begin;
	$else
		return mask;
	$endif
}

<*
	@require is_unsigned(IntType)
	@require begin >= 0, begin <= end, end <= bitsize(IntType)
*>
macro IntType bitmask_r(int begin, int end) <IntType>
{
	return bitmask{IntType}(end - begin + 1, begin);
}

<*
	@require is_unsigned($Typeof(x))
	@require begin >= 0, width > 0
	@require begin + width <= bitsize($Typeof(x))
*>
macro bit_extract(x, int begin, int width) 
{
	var $IntType = $Typeof(x);	
	$IntType r = (x >> begin) & bitmask{$IntType}(width);
	return r;
}

<*
	@require is_unsigned($Typeof(x))
	@require $Typeof(x) == $Typeof(value)
	@require begin >= 0, width > 0
	@require begin + width <= bitsize($Typeof(x))
	@require value <= bitmask($Typeof(value), width)
*>
macro bit_deposit(x, value, int begin, int width)
{
	var $IntType = $Typeof(x);	
	$IntType mask = bitmask{$IntType}(width, begin);
	$IntType r = (x & ~mask) | ((value << begin) & mask);
	return r;
}

<*
	@require is_unsigned($Typeof(x))
	@require 0 <= index, index <= bitsize($Typeof(x))
*>
macro bit_get(x, int index)
{
	return ($Typeof(x))((x >> index) & 1u);
}

<*
	@require is_unsigned($Typeof(x))
	@require is_int($Typeof(value))
	@require value == 0 || value == 1
	@require 0 <= index, index <= bitsize($Typeof(x))
*>
macro bit_write(x, value, int index)
{
	return ($Typeof(x))(x | (value << index));
}

<*
	@require is_unsigned($Typeof(x))
	@require 0 <= index, index <= bitsize($Typeof(x))
*>
macro bit_set(x, int index)
{
	return ($Typeof(x))(x | (1 << index));
}

<*
	@require is_unsigned($Typeof(x))
	@require 0 <= index, index <= bitsize($Typeof(x))
*>
macro bit_toggle(x, int index)
{
	return ($Typeof(x))(x ^ (1 << index));
}

<*
	@require is_unsigned($Typeof(x))
	@require 0 <= width, width <= bitsize($Typeof(x))
	@ensure return == 0 || return == 1
*>
macro bit_or(x, int width = ...)
{
	var $IntType = $Typeof(x);	
	$if $defined(width):
		return ($IntType)(x & bitmask{$IntType}(width) != 0);
	$else
		return ($IntType)(x != 0);
	$endif
}

<*
	@require is_unsigned($Typeof(x))
*>
macro int popcnt(x)
{
	return x.popcount();
}

<*
	@require is_unsigned($Typeof(x))
*>
macro int lzcnt(x)
{
	return x.clz();
}

<*
	@require is_unsigned($Typeof(x))
*>
macro int tzcnt(x)
{
	return x.ctz();
}

const String METHODS @local = `
macro %0 %0.deposit(self, %0 value, int begin, int width) => bit_deposit(self, value, begin, width);
macro %0 %0.extract(self, int begin, int width) => bit_extract(self, begin, width);
macro %0 %0.truncate(self, int width) => bit_extract(self, 0, width);
macro %0 %0.lo(self) => bit_extract(self, 0, (bitsize(%0) / 2) - 1);
macro %0 %0.hi(self) => bit_extract(self, bitsize(%0) / 2, bitsize(%0) - 1);
macro %0 %0.bit(self, int index) => bit_get(self, index);
macro %0 %0.lsb(self) => bit_get(self, 0);
macro %0 %0.msb(self) => bit_get(self, bitsize(%0) - 1);
macro %0 %0.bit_or(self, int width = ...) => bit_or(self, width);
macro %0 %0.bit_set(self, int index) => bit_set(self, index);
macro %0 %0.bit_toggle(self, int index) => bit_toggle(self, index);
macro int %0.popcnt(self) => popcnt(self); 
macro int %0.lzcnt(self) => lzcnt(self);
macro int %0.tzcnt(self) => tzcnt(self);
`;

macro define_methods()
{
	var $methods = "";
	$foreach $type : integer::UNSIGNED_TYPES:
		$methods +++= ifmt(METHODS, $type);
	$endforeach
	return $methods;		
}

$expand(define_methods());

// --- pre/post condition macros ---

macro bool is_arithmetic_type($Type) @const
{
	$switch:
		$case $defined(($Type){} + ($Type){}):
		$case $defined(($Type){} - ($Type){}):
		$case $defined(($Type){} * ($Type){}):
		$case $defined(($Type){} / ($Type){}):
			return true;
		$default:
			return false;
	$endswitch
}

macro ifmt(String $format, ...) @local
{
	var $result = "";
	sz $i, $s;
	$for ;$i < $format.len;:
		$if $format[$i] == '%':
			$if $s != $i:
				$result +++= $format[$s..$i-1];
			$endif
			char $c = $format[++$i];
			$if !('0' <= $c && $c <= '9'):
				$error "Expected a decimal integer from 0 to 9.";
			$endif
			int $x = (int)($c - '0');
			$result +++= $vaarg[$x];
			$s = ++$i;
		$else
			$i++;
		$endif
	$endfor
	$if $s != $i:
		$result +++= $format[$s..$i-1];
	$endif
	return $result;	
}

