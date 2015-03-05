BEGIN { # limited to release test
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}
use Test::More;
eval { require Test::Kwalitee::Extra; Test::Kwalitee::Extra->import(qw(!:optional :experimental)); };
plan( skip_all => "Test::Kwalitee::Extra not installed: $@; skipping") if $@;
 
