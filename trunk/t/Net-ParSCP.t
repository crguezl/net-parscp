# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-ParSCP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Net::ParSCP') };

#########################

SKIP: {
  skip("Developer test", 4) unless ($ENV{DEVELOPER} && -x "script/parpush" && ($^O =~ /nux$/));

     my $output = `script/parpush MANIFEST  beo-chum:/tmp 2>&1`;
     like($output, qr/Error. Identifier \(chum\) does not correspond/, 'Illegal machine name');

     $output = `script/parpush MANIFEST  trutu-orion:/tmp 2>&1`;
     like($output, qr/Error. Identifier \(trutu\) does not correspond/, 'Illegal cluster name');

     $output = `script/parpush -v MANIFEST  beo-europa/tmp 2>&1`;
     like($output, qr{Destination beo-europa/tmp must have a colon \(:\)}, 'colon missed');

     $output = `script/parpush -v MANIFEST  beo-europa:/tmp 2>&1`;
     like($output, qr{beowulf output:\s+orion output:\s*}, 'Successful connection');

}



