module radiance::integer;
import radiance::type;

alias is_int        @private = type::is_int;
alias is_signed     @private = type::is_signed;
alias is_unsigned   @private = type::is_unsigned;
alias @is_int       @private = type::@is_int;
alias @is_signed    @private = type::@is_signed;
alias @is_unsigned  @private = type::@is_unsigned;

alias is_int_vector       @private = type::is_int_vector;
alias is_signed_vector    @private = type::is_signed_vector;
alias is_unsigned_vector  @private = type::is_unsigned_vector;

alias @type_match @private = type::@same_type;

<*
 @require is_int(Integer)
*>
module radiance::integer <Integer>;

const SIGNED = is_signed(Integer);
const UNSIGNED = is_unsigned(Integer);

const int _K   @private = bitsize(Integer); 
const int _KM1 @private = _K - 1;



