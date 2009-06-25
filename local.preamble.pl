# This code is executed in the local machine

# Redefine them if needed
#our $makebuilder = 'Makefile:PL';
#our $build = 'make';
#our $makebuilder_arg = ''; # s.t. like INSTALL_BASE=~/personalmodules
#our $build_arg = '';       # arguments for "make"/"Build"

#our $build_test_arg = 'TEST_VERBOSE=1';

# This code will be executed in the remote servers
our %preamble = (
  beowulf => q{ },
  orion   => q{ system(q{touch Makefile }) }
);

