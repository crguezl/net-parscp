package Net::HostLanguage;
use strict;
use warnings;

use Set::Scalar;

use base 'Exporter';

our @EXPORT = qw{
  parse_configfile
  translate
};

our $VERSION = '0.12';
our $VERBOSE = 0;
our $DRYRUN = 0;

# Create methods for each defined machine or cluster
sub create_machine_alias {
  my %cluster = @_;

  my %method; # keys: machine addresses. Values: the unique name of the associated method

  no strict 'refs';
  for my $m (keys(%cluster)) {
    my $name  = uniquename($m);
    *{__PACKAGE__.'::'.$name} = sub { 
      $cluster{$m} 
     };
    $method{$m} = $name;
  }

  return \%method;
}

# read_configfile: Return an array with the relevant lines of the config file
# Configuration dump produced by 'cssh -u'
# Example of .csshrc file:
# window_tiling=yes
# window_tiling_direction=right
# clusters = beno ben beo bno bco be bo eo et num beat local beow
# beow = beowulf europa orion tegasaste
# beno = beowulf europa nereida orion
# ben = beowulf europa nereida 
# beo = beowulf europa orion
# bno = beowulf nereida orion
# bco = beowulf casnereida orion
# be  = beowulf europa
# bo  = beowulf orion
# eo  =  europa orion
# et  = europa etsii
# #     europa          etsii
# num = 193.145.105.175 193.145.101.246
# # With @
# beat  = casiano@beowulf casiano@europa
# local = local1 local2 local3 
sub read_configfile {
  my $configfile = $_[0];

  if (defined($configfile) && -r $configfile) {
    open(my $f, $configfile);
    my @desc = <$f>;
    chomp(@desc);
    return @desc;
  }

  # Configuration file not found. Try with ~/.csshrc of cssh
  $configfile = $_[0] = "$ENV{HOME}/.csshrc";
  if (-r $configfile) {
    open(my $f, $configfile);

    # We are interested in lines matching 'option = values'
    my @desc = grep { m{^\s*(\S+)\s*=\s*(.*)} } <$f>;
    close($f);

    my %config = map { m{^\s*(\S+)\s*=\s*(.*)} } @desc;

    # From cssh man page:
    # extra_cluster_file = <null>
    # Define an extra cluster file in the format of /etc/clusters.  
    # Multiple files can be specified, seperated by commas.  Both ~ and $HOME
    # are acceptable as a to reference the users home directory, i.e.
    # extra_cluster_file = ~/clusters, $HOME/clus
    # 
    if (defined($config{extra_cluster_file})) {
      $config{extra_cluster_file} =~ s/(\~|\$HOME)/$ENV{HOME}/ge;
      my @extra = split /\s*,\s*/, $config{extra_cluster_file};
      for my $extra (@extra) {
        if (-r $extra) {
          open(my $e, $extra);
          push @desc, grep { 
                        my $def = $_ =~ m{^\s*(\S+)\s*=\s*(.*)};
                        my $cl = $1;
                        $config{clusters} .= " $cl" if ($cl && $config{clusters} !~ /\b$cl\b/);
                        $def;
                      } <$e>;
          close($e);
        }
      }
    }
    chomp(@desc);

    # Get the clusters. It starts 'cluster = ... '
    #    clusters = beno ben beo bno bco be bo eo et num beat local beow
    my $regexp = $config{clusters};

    # We create a regexp to search for the clusters definitions.
    # The regexp is the "or" of the cluster names followed by '='
    #            (^beo\s*=)|(^be\s*=) | ...
    $regexp =~ s/\s*(\S+)\s*/(^$1\\s*=)|/g;
    # (beno\s*=) | (ben\s*=) | ... | (beow\s*=) |
    # Chomp the final or '|'
    $regexp =~ s/[|]\s*$//;

    # Select the lines that correspond to clusters
    return grep { m{$regexp}x } @desc;
  }

  warn("Warning. Configuration file not found!\n") if $VERBOSE;

  return ();
}

############################################################
sub parse_configfile {
  my $configfile = $_[0];
  my %cluster;

  my @desc = read_configfile($_[0]);

  for (@desc) {
    next if /^\s*(#.*)?$/;

    my ($cluster, $members) = split /\s*=\s*/;
    die "Error in configuration file $configfile invalid cluster name $cluster" unless $cluster =~ /^[\w.]+$/;

    my @members = split /\s+/, $members;

    for my $m (@members) {
      die "Error in configuration file $configfile invalid name $m" unless $m =~ /^[\@\w.]+$/;
      $cluster{$m} = Set::Scalar->new($m) unless exists $cluster{$m};
    }
    $cluster{$cluster} = Set::Scalar->new(@members);
  }

  # keys: machine and cluster names; values: name of the associated method 
  my $method = create_machine_alias(%cluster); 

  return (\%cluster, $method);
}

############################################################
{
  my $pc = 0;

  sub uniquename {
    my $m = shift;

    $m =~ s/\W/_/g;
    $pc++;
    return "_$pc"."_$m";
  }
}

sub warnundefined {
  my ($configfile, @errors) = @_;

  local $" = ", ";
  my $prefix = (@errors > 1) ?
      "Machine identifiers (@errors) do"
    : "Machine identifier (@errors) does";
  warn "$prefix not correspond to any cluster or machine defined in ".
       " cluster description file '$configfile'.\n";
}

sub non_declared_machines {
  my $configfile = shift;
  my $clusterexp = shift;
  my %cluster = @_;

  my @unknown;
  my @clusterexp = $clusterexp =~ m{([a-zA-Z_][\w.\@]*)}g;
  if (@unknown = grep { !exists($cluster{$_}) } @clusterexp) {
    warnundefined($configfile, @unknown) if $VERBOSE;
  }
  return @unknown;
}

sub translate {
  my ($configfile, $clusterexp, $cluster, $method) = @_;

  # Autodeclare unknown machine identifiers
  my @unknown = non_declared_machines($configfile, $clusterexp, %$cluster);
  my %unknown = map { $_ => Set::Scalar->new($_)} @unknown;
  %$cluster = (%$cluster, %unknown); # union: add non declared machines
  %$method = (%$method, %{create_machine_alias(%unknown)});

  # Translation: transform user's formula into a valid Perl expression
  # Cluster names are translated into a call to the associated method
  # The associated method returns the set of machines for that cluster
  $clusterexp =~ s/(\w[\w.\@]*)/$method->{$1}()/g;

  my $set = eval $clusterexp;

  unless (defined($set) && ref($set) && $set->isa('Set::Scalar')) {
    $clusterexp =~ s/_\d+_//g;
    $clusterexp =~ s/[()]//g;
    warn "Error. Expression '$clusterexp' has errors. Skipping.\n";
    return;
  }
  return $set;
}

1;

__END__

