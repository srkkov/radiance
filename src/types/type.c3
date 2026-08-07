module radiance::type;

<*
 @require $vaarg.len > 0
*>
macro bool @same_type(...)
{
	$if $vaarg.len == 1: return true; $endif

	var $Type = $Typeof($vaarg[0]);
	$for sz $i = 1; $i < $vaarg.len; $i++:
		$if $Type != $Typeof($vaarg[$i]):
			return false;
		$endif
	$endfor
	return true;
}












macro bool @all(#check, ...) @private
{
	$for sz $i; $i < $vaarg.len; $i++:
		$if !#check($Typeof($vaarg[$i])):
			return false;
		$endif
	$endfor
	return true;
}

