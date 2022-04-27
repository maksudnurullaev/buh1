use Test::More;
use Tests::Base;
use Utils;
use utf8;

use_ok('Utils');
require_ok('Utils');


ok(!defined(Utils::date4format2format), "Non defined result with no parameters!");
ok(!defined(Utils::date4format2format('01.01.1975')), "Non defined result with not all parameters!");
ok(!defined(Utils::date4format2format('01.01.1975','%d.%m.%Y')), "Non defined result with not all parameters!");
is('1975.01.01', Utils::date4format2format('01.01.1975','%d.%m.%Y', '%Y.%m.%d'), "Test different test format - 1!");
is('1975.01.01', Utils::date4format2format('1.1.1975','%d.%m.%Y', '%Y.%m.%d'), "Test different test format - 2!");
is('1975.01.24', Utils::date4format2format('24.01.1975','%d.%m.%Y', '%Y.%m.%d'), "Test different test format - 3!");
is('2022.04.01', Utils::date4format2format('2022-04-01','%Y-%m-%d', '%Y.%m.%d'), "Test different test format! - 4!");

### -=FINISH=-
done_testing();
