use Test::More;
use Test::Mojo;
use Utils::Import::Definitions;

use Utils::Accounts;

use_ok('Utils::Import::Definitions');
require_ok('Utils::Import::Definitions');

#my ( $ACCOUNT_PART ,$ACCOUNT_SECTION ,$ACCOUNT ,$ACCOUNT_SUBCONTO , $TYPES )
diag( $Utils::Accounts::ACCOUNT_PART );

#ok(defined Utils::Import::Definitions::import_sasol_definitions, "Non defined export_lex_definitions sub!");

### -=FINISH=-
done_testing();