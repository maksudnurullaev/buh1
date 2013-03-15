use Test::More;
use Test::Mojo;
use ML;
use Data::Dumper;
use utf8;

use_ok('ML');
require_ok('ML');
$ML::FILE_NAME = 'MLTest.INI';
if( -e ML::get_file_path() ){
    unlink(ML::get_file_path());
}
ok(ML::get_file_path() =~ $ML::FILE_NAME, "Test for file name.");
ok($ML::DIR =~ /ML$/, "Root catalog for ML's files.");
ok($ML::DEFAULT_LANG ~~ @ML::DEFAULT_LANGS, "Existance of default languge in languages array.");
ML::save_to_file(); # make empty file 

### -= VALUES as single string =-
ok(ML::get_value() =~ /^ERROR/, "Get invalid result 1");
ok(ML::get_value('key1') =~ /^ERROR/, "Get invalid result 2");
ok(ML::get_value('key1', 'key2') =~ /^\[-/, "Get not filled value");
ok(ML::set_value('key1', 'key2', 'салом') eq 'салом', "Save value");
ok(ML::get_value('key1', 'key2') eq 'салом', "Get for exist value");
my $test_records_count = 10;
for(1 .. $test_records_count){
     ML::set_value("key1.$_", "key2.$_", "салом.$_"); 
}
ML::save_to_file();
$length = scalar(keys(%{ML::load_from_file()}));
ok($length == ($test_records_count + 1), "Check for values count: $length");
$ML::VALUES = {};
$length = scalar(keys(%{$ML::VALUES}));
ok($length == 0 , "Check for values count: $length");

ML::load_from_file();
ok(ML::get_value('key1.9', 'key2.9') eq 'салом.9', "Get for exist value");
### -= VALUES with multiline string =-
my $big_string = "Some \n multiline \n string \n here";
ML::set_value('key1_ml', 'key2_ml', $big_string);
ML::save_to_file();

$ML::VALUES = {};
ML::load_from_file();
    ok($big_string eq ML::get_value('key1_ml', 'key2_ml'), "Test for big multi-line string");

### -=FINISH=-
done_testing();
