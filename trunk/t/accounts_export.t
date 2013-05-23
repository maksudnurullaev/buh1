use Test::More;
use Test::Mojo;
use Accounts;

use_ok('Accounts');
require_ok('Accounts');

# Salted password
ok(defined Accounts::export_lex_definitions, "Non defined export_lex_definitions sub!");
#ok(defined Accounts::export_sasol_definitions, "Non defined export_sasol_definitions sub!");

#Accounts::export_lex_definitions();
#Accounts::export_sasol_definitions();

### -=FINISH=-
done_testing();
