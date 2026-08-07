module radiance::type;

macro bool is_int($Type) @const
{
	$switch $Type::kind:
		$case UNSIGNED_INT:
		$case SIGNED_INT:
			return true;
		$case BITSTRUCT:
		$case TYPEDEF:
			return is_int($Type::inner);
		$default:
			return false;
	$endswitch
}

macro bool is_unsigned($Type) @const
{
	$switch $Type::kind:
		$case UNSIGNED_INT:
			return true;
		$case BITSTRUCT:
		$case TYPEDEF:
			return is_unsigned($Type::inner);
		$default:
			return false;
	$endswitch
}

macro bool is_signed($Type) @const
{
	$switch $Type::kind:
		$case SIGNED_INT:
			return true;
		$case BITSTRUCT:
		$case TYPEDEF:
			return is_signed($Type::inner);
		$default:
			return false;
	$endswitch
}

macro bool is_int_vector($Type) @const
{
	return $Type::kind == VECTOR &&& is_int($Type::inner);
}

macro bool is_signed_vector($Type) @const
{
	return $Type::kind == VECTOR &&& is_signed($Type::inner);
}

macro bool is_unsigned_vector($Type) @const
{
	return $Type::kind == VECTOR &&& is_unsigned($Type::inner);
}

macro @is_int(...)
{
	return @all(is_int, ...$vaarg);
}

macro @is_signed(...)
{
	return @all(is_signed, ...$vaarg);
}

macro @is_unsigned(...)
{
	return @all(is_unsigned, ...$vaarg);
}
