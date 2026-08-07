module radiance::type;

<*
 Identifies types that are effectively a struct of same-length vectors.
*>
macro bool is_composite_vector($Type) @const
{
	$if !$Type::has_tag(COMPOSITE_VECTOR_TAG):
		return false;
	$endif

	$switch $Type::kind:

		$case STRUCT:

			var $first = $Type::members[0].type;

			$if $first.kind != VECTOR:
				return false;
			$endif

			$if $Type::members.len == 1:
				return true;
			$else
				int $vl = $first.len;

				$foreach $member_ref : $Type::members[1..]:
					var $member = $member_ref.type;

					$if $member.kind != VECTOR ||| $member.len != $vl:
						return false;
					$endif

				$endforeach
				return true;
			$endif

		$case ARRAY:
			return $Type::inner.kind == VECTOR;

		$case TYPEDEF:
		$case CONSTDEF:
			return is_vector_struct($Type::inner);

		$default:
			return false;

	$endswitch
}

const COMPOSITE_VECTOR_TAG = "radiance::composite_vector";

attrdef @VectorComposite = @tag(COMPOSITE_VECTOR_TAG, true);


