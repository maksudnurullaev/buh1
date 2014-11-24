use Test::More;
use t::Base;
use ML;
use Data::Dumper;
use Utils;
use utf8;

use_ok('ML');
require_ok('ML');

my $ml_file_path;
my $test_mojo;

BEGIN { 
    $test_mojo     = t::Base::get_test_mojo_session();
    $ML::FILE_NAME = 'MLTest.INI';
    $ml_file_path  = $test_mojo->app->home->rel_file("$ML::DIR_NAME/$ML::FILE_NAME");
    die "Tests going to work with actual(production) ML.INI file" if $ml_file_path =~ /ML\.INI$/ ;
    if( -e $ml_file_path ){
        unlink( $ml_file_path );
    }
}    
END { unlink( $ml_file_path ); }

ok($ml_file_path =~ $ML::FILE_NAME, "Test for file name.");
ok($ML::DIR_NAME =~ /ML$/, "Root catalog for ML's files.");
my $default_lang = $Utils::Languages::DEFAULT_LANG;
ok( join(',',@{Utils::Languages::get()}) =~ /$default_lang/, "Existance of default language in languages array.");

#-### -= VALUES as single string =-
$test_mojo->get_ok('/')->status_is(200);
my $invalid_key  = 'some_invalid_key';
ok($test_mojo->app->ml() =~ /ERROR/, "Get invalid result 1");
ok($test_mojo->app->ml($invalid_key) =~ /^\[-$default_lang\]$invalid_key$/, "Get invalid result 2");
ok(ML::set_value($test_mojo,'key1', 'key2', 'салом') eq 'салом', "Save value");
ok(ML::get_value($test_mojo,'key1', 'key2') eq 'салом', "Get for exist value");
ok(ML::save_to_file($test_mojo), "File saving test to: " . ML::get_file_path($test_mojo)) ;
ok( -e ML::get_file_path($test_mojo), "Check file existance for:" . ML::get_file_path($test_mojo) );
my $test_records_count = 10;
for(1 .. $test_records_count){
     ML::set_value($test_mojo,"key1.$_", "key2.$_", "салом.$_"); 
}
ok(ML::save_to_file($test_mojo), "File saving test to: " . ML::get_file_path($test_mojo)) ;
for(1 .. $test_records_count){
     ok( ML::get_value($test_mojo,"key1.$_", "key2.$_") eq "салом.$_", "Test for UTF-8 value: $_" ); 
}
ok(ML::get_value($test_mojo,'key1.9', 'key2.9') eq 'салом.9', "Get for exist value");
### -= VALUES with multiline string =-
my $big_string = "Some \n multiline \n string \n here";
ML::set_value($test_mojo,'key1_ml', 'key2_ml', $big_string);
ML::save_to_file($test_mojo);
ML::load_from_file($test_mojo);
ok($big_string eq ML::get_value($test_mojo,'key1_ml', 'key2_ml'), "Test for big multi-line string");

### -=FINISH=-
done_testing();
