use strict;
use warnings;

use Test::More;
use DBI;
use DBI::Const::GetInfoType;

use vars qw($test_dsn $test_user $test_password);
use lib 't', '.';
require 'lib.pl';

my $dbh;
eval {$dbh= DBI->connect($test_dsn, $test_user, $test_password,
                      { RaiseError => 1, PrintError => 0, AutoCommit => 0 });};

if (!$dbh) {
    plan skip_all => "no database connection";
}
unless($dbh->get_info($GetInfoType{'SQL_ASYNC_MODE'})) {
    plan skip_all => "Async support wasn't built into this version of DBD::mysql";
}

is $dbh->get_info($GetInfoType{'SQL_ASYNC_MODE'}), 2; # statement-level async
is $dbh->get_info($GetInfoType{'SQL_MAX_ASYNC_CONCURRENT_STATEMENTS'}), 1;

$dbh->do(<<SQL);
CREATE TEMPORARY TABLE async_test (
    value0 INTEGER,
    value1 INTEGER,
    value2 INTEGER
);
SQL

ok my $rows = $dbh->do('INSERT INTO async_test VALUES (1,2,3),(4,5,6),(7,8,9)');
is $rows, 3;

ok my $sth = $dbh->prepare('SELECT * FROM async_test where value0 = 7', { async => 1});
my $expected = { 7 => {value0 => 7, value1 => 8, value2 => 9}};

ok $sth->execute();
while (!$sth->mysql_async_ready) {
}
ok $sth->mysql_async_result;

# after this point $sth is no longer in async mode
# and call to mysql_async_ready will trigger 2000 'Handle is not in asynchronous mode'

my $result = $sth->fetchall_hashref('value0');
is_deeply( $result, $expected);

ok $dbh->disconnect;
done_testing;
