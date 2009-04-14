use warnings;
use strict;
use Test::More tests => 15;
BEGIN { use_ok('Net::ParSCP') };

#########################

SKIP: {
  skip("Developer test", 14) unless ($ENV{DEVELOPER} && -x "script/parpush" && ($^O =~ /nux$/));

     my $output = `script/parpush -v 'orion:.bashrc beowulf:.bashrc' europa:/tmp/bashrc.@# 2>&1`;
     like($output, qr{scp\s+beowulf:.bashrc\s+europa:.tmp.bashrc.beowulf}, 'using macro for source machine: remote target');
     like($output, qr{scp\s+orion:.bashrc europa:/tmp/bashrc.orion}, 'using macro for source machine: remote target');
     ok(!$?, 'macro for source machine: status 0');

     $output = `script/parpush -l europa -v MANIFEST  beo-europa:/tmp/@# 2>&1`;
     ok(!$?, 'macro from local to remote: status 0');
     like($output, qr{scp  MANIFEST beowulf:/tmp/europa}, 'using macro from local machine: remote target');
     like($output, qr{scp  MANIFEST orion:/tmp/europa}, 'using macro from local machine: remote target');

     $output = `script/parpush -v MANIFEST  beo-europa:/tmp/@# 2>&1`;
     ok(!$?, 'macro from local to remote: status 0');
     like($output, qr{scp  MANIFEST beowulf:/tmp/localhost}, 'using macro from local machine: remote target');
     like($output, qr{scp  MANIFEST orion:/tmp/localhost}, 'using macro from local machine: remote target');

     $output = `script/parpush -h`;
     ok(!$?, 'help: status 0');
     like($output, qr{Name:\s+parpush - Secure transfer of files via SSH},'help:Name');
     like($output, qr{Usage:\s+parpush}, 'help: Usage');
     like($output, qr{Options:\s+--configfile file :}, 'help:Options');
     like($output, qr{--xterm}, 'help: xterm option');
}



