use Test::More;
use Tests::Base;
use Data::Dumper;
use utf8;

use Mojo::DOM;
use Utils::Imports;

my $test_mojo;

BEGIN { $test_mojo     = Tests::Base::get_test_mojo_session(); }    

use_ok('Mojo::DOM');
require_ok('Mojo::DOM');

my $dom = Mojo::DOM->new('<td style="TEXT-ALIGN: center; VERTICAL-ALIGN: middle" tabindex="1"><font size="2"><br>0710-0720,1010-1090,<br>2910-2990 </font></td>');
my $result = Utils::Imports::get_dom_deep_text($dom);

is($result, '_BR_0710-0720,1010-1090,_BR_2910-2990 ', "Base dom test");

my $dom2 = Mojo::DOM->new('<td style="TEXT-ALIGN: center; VERTICAL-ALIGN: middle" tabindex="1"><font size="2">2010, 2110,<br> 2310 </font></td>');
$result = Utils::Imports::get_dom_deep_text($dom2);
is($result, '2010, 2110,_BR_ 2310 ', "Base dom test #2");

my $dom3 = Mojo::DOM->new('<td style="TEXT-ALIGN: center; VERTICAL-ALIGN: middle" tabindex="1">2010,2110</td>');
$result = Utils::Imports::get_dom_deep_text($dom3);
is($result, '2010,2110', "Base dom test #3");


#<td style="TEXT-ALIGN: center; VERTICAL-ALIGN: middle" tabindex="1"><font size="2"><br>0710-0720,1010-1090,<br>2910-2990 </font></td>
my $dom4 = Mojo::DOM->new('<td style="TEXT-ALIGN: center; VERTICAL-ALIGN: middle" tabindex="1"><font size="2"><br>0710-0720,1010-1090,<br>2910-2990 </font></td>');
$result = Utils::Imports::get_dom_deep_text($dom4);
is($result, '_BR_0710-0720,1010-1090,_BR_2910-2990 ', "Base dom test #4");

### -=FINISH=-
done_testing();
