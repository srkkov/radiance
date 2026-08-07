module radiance::integer;
import radiance::integer::bit @public;

$expand(define_methods());

const String METHODS @local = `
// macro %0 %0.deposit(self, %0 value, int begin, int width) => bit_deposit{%0}(self, value, begin, width);
// macro %0 %0.extract(self, int begin, int width) => bit_extract{%0}(self, begin, width);
macro %0 %0.truncate(self, int width) => bit::_extract{%0}(self, 0, width);
macro %0 %0.lo(self) => bit::_extract{%0}(self, 0, bitsize(%0) / 2);
macro %0 %0.hi(self) => bit::_extract{%0}(self, bitsize(%0) / 2, bitsize(%0) / 2);
macro %0 %0.bit(self, int index) => bit::_test{%0}(self, index);
macro %0 %0.lsb(self) => bit::_test{%0}(self, 0);
macro %0 %0.msb(self) => self >> (bitsize(%0) - 1);
// macro %0 %0.bit_or(self, int width = ...) => $defined(width) ??? bit_or{%0}(self, width) : bit_or{%0}(self);
// macro %0 %0.bit_set(self, int index) => bit_set{%0}(self, index);
// macro %0 %0.bit_toggle(self, int index) => bit_toggle{%0}(self, index);
// macro int %0.popcnt(self) => popcnt{%0}(self); 
// macro int %0.lzcnt(self) => lzcnt{%0}(self);
// macro int %0.tzcnt(self) => tzcnt{%0}(self);
`;

macro define_methods()
{
	var $methods = "";
	$foreach $type : UNSIGNED_TYPES:
		$methods +++= ifmt(METHODS, $type);
	$endforeach
	return $methods;		
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
				$error "Expected a single decimal digit.";
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
