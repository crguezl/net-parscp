
---

# NAME #

parpush - Secure parallel transfer of files between clusters via SSH



---

# SYNOPSIS #

```
  parpush [options] 'sourcefile' cluster1:path1 cluster2:path2 ...

  # For instance, the command:

    parpush somefile 127.0.0.1..5:/tmp/somefile.@=

  # is equivalent to:
  #         scp  somefile 127.0.0.1:/tmp/somefile.127.0.0.1
  #         scp  somefile 127.0.0.2:/tmp/somefile.127.0.0.2
  #         scp  somefile 127.0.0.3:/tmp/somefile.127.0.0.3
  #         scp  somefile 127.0.0.4:/tmp/somefile.127.0.0.4
  #         scp  somefile 127.0.0.5:/tmp/somefile.127.0.0.5

  # You need to set first a configuration file describing the
  # set of clusters:

      $ cat $HOME/.clustersrc
      cluster1 = machine1 machine2 machine3
      cluster2 = machine2 machine4 machine5
      num = 193.140.101.175 193.140.101.246
      # Comments are allowed
      # same as range = cc100 cc101 cc102
      range = cc100..102
```



---

# OPTIONS #

  * `--configfile file` File describing the clusters. If not specified parpush will look for the files:
```
  $HOME/.clustersrc
  $HOME/.csshrc
  /etc/clusters
```

in this order

  * `--scpoptions 'options for scp'`
A string with the options for `scp`. The default is no options and `-r` if sourcefile is a directory

  * `--program '/usr/local/bin/scp'`
A string with the name of the program to use for secure copy. The default is 'scp'

  * `--name machine1=string1 --name machine2=string2`
It may appear several times. The value associated used with `machine1` will be used in the `@#` and `@=` macros instead the machine name. See an example. The command:

```
  $ parpush -v -n m1=o -n m2=b -n m3=e file m1+m2+m3:/tmp/file.@=
```

is equivalent to:

```
        scp  file m1/tmp/file.o
        scp  file m2/tmp/file.b
        scp  file m1/tmp/file.e
```

  * `--processes`
Maximum number of concurrent processes

  * `--verbose`
  * `--xterm`
Runs `cssh` to the target machines

  * `--dryrun`
It shows the `scp` commands that will be issued but does not transfer the files

  * `--help`
  * `--Version`



---

# EXAMPLES #

```
  # Copy 'sourcefile' to the union of cluster1 and cluster2
  $ parpush sourcefile  cluster1+cluster2:/tmp

  # Copy 'sourcefile' to the /tmp/ directory in machine1, machine2, machine3
  # machine4 and machine 5
  $ parpush sourcefile machine1..5:/tmp/

  # Copy 'sourcefile' to the intersection of cluster1 and cluster2
  # i.e. to 'machine2'
  $ parpush sourcefile  cluster1*cluster2:/tmp

  # Copy 'sourcefile' to the machines in cluster1 that don't belong to cluster2
  # i. e. to 'machine1', 'machine2'
  $ parpush sourcefile  cluster1-cluster2:/tmp

  # Copies file 'sourcefile' to file 'tfmachine1.txt' in 'machine1'
  # and to 'tfmachine2.txt' in 'machine2'. The macro '@=' inside
  # a path is substituted by the name of the target machine
  $ parpush sourcefile  cluster1-cluster2:/tmp/tf@=.txt

  # Copies all the files with name '.bashrc' in the home directories
  # of machines in cluster1 to the '/tmp/' directories of machines
  # in cluster2. The macro '@#' stands for the name of the source machine.
  # Thus, the file .bashrc in machine1 will be copied as
  # '/tmp/bashrc_at_machine1' in the machines in 'cluster2':
  $ parpush -v cluster1:.bashrc cluster2:/tmp/bashrc_at_@#

  # Copies .bashrc in machine1 and .bashrc in machine2
  # to machine3:/tmp/bashrc.ORION and machine3:/tmp/bashrc.BEO
  $ parpush -n machine1=ORION -n machine2=BEO \
            'machine1:.bashrc beowulf:.bashrc' \
            machine3:/tmp/bashrc.@#

  # A more complicated formula.
  # Though 'machine2' is an alias for 193.140.101.175, (see the
  # cluster definition above) they aren't
  # considered equal by parpush. The file will be transferred to
  # 'machine2'
  $ parpush 'sourcefile'  '(cluster1+cluster2)-num:/tmp'


  # Several cluster expressions may appear as targets.
  # Send 'sourcefile' to machines in cluster1 but not in cluster2
  # and store it in /tmp. Send it to machines in cluster2 but not cluster1
  # and store it at the home directory
  $ parpush sourcefile  cluster1-cluster2:/tmp  cluster2-cluster1:

  # Copy from remote machine 'machine1' the file 'file.txt' to
  # all the machines in 'cluster1' other than 'machine1':
  $ parpush machine1:file.txt cluster1-machine1:

  # You can also transfer several files from several source clusters/machines to
  # some set of machines. In such case
  # protect the source with single quotes.
  $ parpush  'machine1:file1.txt machine2:file2.txt' cluster1-machine1-machine2:

  # You can "rename" the names of the source machines. In this example
  # the file '.bashrc' at machine1 will be copied as 'dog_bashrc' in
  # all the machines in 'cluster2' (other than 'machine1'):
  $ parpush -n machine1=dog -n machine2=cat -n machine3=mouse -v cluster1:.bashrc \
                                                  cluster2-machine1/tmp/@#_bashrc

  # A combination of local and remote files can be sent.
  # Protect the source with single quotes. The following command
  # sends 'localfile.txt' in the local machine and 'remote.txt' in 'machine4'
  # to machine3
  $ parpush  'localfile.txt machine4:remote.txt' cluster1-machine1-machine2:


  # Globs can be used in the sourcefile argument.
  # All the files matching the glob 'file*' in the local machine will be sent.
  # Also those in machine1 matching the glob '*.pl'
  $ parpush  'file* machine1:*.pl' cluster2-machine2:/tmp

  # All the files matching the glob 'file*' in the 'machine1' will be sent
  # to the local machine.  The directory 'dir/' in machine2 will be also sent
  # to '/tmp/dir/' in the local machine.
  $ parpush  'machine1:*.pl machine2:dir/' :/tmp

  # The macro '@#' stands for the "source machine". Thus, in the example
  # below file 'file.txt' in machine1 will be copied to file '/tmp/file.txt.machine1'
  # in machine3. File 'file.txt' in machine2 will be copied to
  # file '/tmp/file.txt.machine2' in machine3.
  $ parpush 'machine1:file.txt machine2:file.txt' machine3/tmp/file_txt.@#

  # You have to write a colon for any target, even if the target is the local host.
  # in the example below 'file.txt' in machine1 will be copied to
  # file '/tmp/file.txt.machine1' in the local machine. File 'file.txt' in machine2
  # will be copied to file '/tmp/file.txt.machine2' in the local machine
  $ parpush 'machine1:file.txt machine2:file.txt' :/tmp/file_txt.@#
```



---

# INSTALLATION #

Install Set::Scalar first. Then the installation uses the traditional procedure. The program `cssh` (`clustercssh`) is not needed but I recommend its installation. Then issue the usual commands (or use `cpan`):

```
   perl Makefile.PL
   make
   make test
   make install
```



---

# DESCRIPTION #

`parpush` push files and directories across sets of remote machines.


## Syntax of Cluster Description Files ##

Unless the option `--configfile` is specified `parpush` will look for a filename named `~/.clusterrc` in the home directory. If it does not exists, the looks for `~/.csshrc`. Last, it looks for the file `/etc/clusters`.

```
      $ cat Cluster
      cluster1 = machine1 machine2 machine3
      cluster2 = machine2 machine4 machine5
      num = 193.140.101.175 193.140.101.246
      range = cc10..11a4..5
```

Ranges are allowed. Thus, the definition above

```
      range = cc10..11a4..5
```

is equivalent to:

```
      range = cc10a4 cc10a5 cc11a4 cc11a5
```

See `man cssh` to find out how to describe a cluster in the `~/.csshrc` file.


## parpush Syntax ##

When calling `parpush` you have to specify the source and the targets. Each target is split in two parts: the cluster description and the path. You have to write a colon for any target, even if the target is the local host. This behavior differs from `scp`. in the example below `'file.txt'` in `machine1` will be copied to file `'/tmp/file.txt.machine1'` in the local machine. File `'file.txt'` in `machine2` will be copied to file `'/tmp/file.txt.machine2'` in the local machine

```
  $ parpush 'machine1..2:file.txt' :/tmp/file_txt.@#
```


## The Syntax of Cluster Expressions ##

  * `s + t` union
  * `s * t` intersection
  * `s - t` difference
  * `s % t` symmetric\_difference
  * Ranges are allowed. Use `..` to define them. Thus `cc101..102.4..5` defines the set of machines
```
   cc101.4
   cc101.5
   cc102.4
   cc102.5
```



## Path Syntax. The @= macro ##

Inside a path the macro `@=` stands for the name of the current machine. Thus, the command:

```
  $ parpush file.txt machine1+machine2:/tmp/@=.txt
```

copies `file.txt` to `machine1.txt` in `machine1` and to `machine2.txt` in `machine2`.


## Path Syntax. The @# macro ##

Inside a path the macro `@#` stands for the name of the source machine. Thus, the command:

```
  $ parpush 'machine1:file.txt machine2:file.txt' :/tmp/file_txt.@#
```

copies `file.txt` in `machine1` to `/tmp/file.txt.machine1` in the local machine and the file with the same name in `machine2` to the file `/tmp/file.txt.machine2`.


## Source Syntax ##

If your source is a file or directory nothing is needed. If you are going to send several files you must protect them inside single quotes as in:

```
  $ parpush  'machine1:file1.txt machine2:file2.txt' cluster1-machine1-machine2:
```

cluster expressions can be used in the source description argument as in:

```
  $ parpush -v 'machine1+machine2:.bashrc' machine3:/tmp/bashrc_at_@#
  Executing system command:
          scp  machine1:.bashrc machine3:/tmp/bashrc_at_machine1
  Executing system command:
          scp  machine2:.bashrc machine3:/tmp/bashrc_at_machine2
  machine3 output:

  machine3 output:
```



---

# SETTING SSH AUTOMATIC AUTHENTICATION #

To use this script you have to set automatic authentication via SSH between the source machine (your machine) and the other destiny machines. This section explains the simplified procedure.

SSH includes the ability to authenticate users using public keys. Instead of authenticating the user with a password, the SSH server on the remote machine will verify a challenge signed by the user's _private key_ against its copy of the user's _public key_. To achieve this automatic ssh-authentication you have to:

  * Generate a public key use the `ssh-keygen` utility. For example:
```
  local.machine$ ssh-keygen -t dsa -N ''
```

The option `-t` selects the type of key you want to generate. There are three types of keys: _rsa1_, _rsa_ and _dsa_. The `-N` option is followed by the _passphrase_. The `-N ''` setting indicates that no passphrase will be used. This is useful when used with key restrictions or when dealing with cron jobs, batch commands and automatic processing which is the context in which this module was designed. By default, in !OpenSSH, your identification will be saved in a file `/home/user/.ssh/id_dsa`. Your public key will be saved in `/home/user/.ssh/id_dsa.pub`.

  * If still you don't like to have a private key without passphrase, provide a passphrase and use `ssh-agent` to avoid the inconvenience of typing the passphrase each time. `ssh-agent` is a program you run once per login session and load your keys into. Keys are added to the `ssh-agent` using the program `ssh-add`. From that moment on, any `ssh` client will contact `ssh-agent` and no more passphrase typing will be needed. Use the program `keychain` to manage the communication with the agent from different sessions.
  * Once you have generated a key pair, you must install the public key on the remote machine. To do it, append the public component of the key in
```
           /home/user/.ssh/id_rsa.pub
```

to file

```
           /home/user/.ssh/authorized_keys

```

on the remote machine. If the `ssh-copy-id` script is available, you can do it using:

```
  local.machine$ ssh-copy-id -i ~/.ssh/id_rsa.pub user@remote.machine
```

Alternatively you can write the following command:

```
  $ ssh remote.machine "umask 077; cat >> .ssh/authorized_keys" \
                                  < /home/user/.ssh/id_rsa.pub
```

The `umask` command is needed since the SSH server will refuse to read a `/home/user/.ssh/authorized_keys` files which have loose permissions.

  * Edit your local configuration file `/home/user/.ssh/config` (see `man ssh_config` in UNIX) and create a new section for `GRID::Machine` connections to that host. Here follows an example:
```
 ...

 # A new section inside the config file:
 # it will be used when writing a command like:
 #                     $ ssh gridyum

 Host gridyum

 # My username in the remote machine
 user my_login_in_the_remote_machine

 # The actual name of the machine: by default the one provided in the
 # command line
 Hostname real.machine.name

 # The port to use: by default 22
 Port 2048

 # The identitiy pair to use. By default ~/.ssh/id_rsa and ~/.ssh/id_dsa
 IdentityFile /home/user/.ssh/yumid

 # Useful to detect a broken network
 BatchMode yes

 # Useful when the home directory is shared across machines,
 # to avoid warnings about changed host keys when connecting
 # to local host
 NoHostAuthenticationForLocalhost yes


 # Another section ...
 Host another.remote.machine an.alias.for.this.machine
 user mylogin_there

 ...
```

This way you don't have to specify your _login_ name on the remote machine even if it differs from your _login_ name in the local machine, you don't have to specify the _port_ if it isn't 22, etc. This is the _recommended_ way to work with `GRID::Machine`. Avoid cluttering the constructor `new`.

  * Once the public key is installed on the server and the key added to the agent, you should be able to authenticate using your private key
```
  $ ssh remote.machine
  Linux remote.machine 2.6.15-1-686-smp #2 SMP Mon Mar 6 15:34:50 UTC 2006 i686
  Last login: Sat Jul  7 13:34:00 2007 from local.machine
  user@remote.machine:~$
```




---

# SEE ALSO #

  * Set::Scalar
  * Cluster ssh: cssh http://sourceforge.net/projects/clusterssh/
  * Project C3 http://www.csm.ornl.gov/torc/C3/
  * http://code.google.com/p/net-parscp/
  * GRID::Cluster
  * GRID::Machine
  * `keychain` article: http://www.ibm.com/developerworks/linux/library/l-keyc2/



---

# AUTHOR #

Casiano Rodriguez-Leon <casiano.rodriguez.leon@gmail.com>



---

# COPYRIGHT AND LICENSE #

Copyright (C) 2009-2009 by Casiano Rodriguez-Leon

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.




