#!/usr/bin/perl -w

use warnings;
use strict;

# Generates the tool tips body for Perl functions.

# The maximum number of lines for each function.
my $line_limit = 35;

# Generate the Tool Tips for Vim from perlpod -f.
while (my $func = <DATA>) {
    chomp ($func);
    my @tool_tip = `perldoc -t -f '$func'`;
    foreach (@tool_tip) {
         chomp;
         s/'/''/g;
         s/^ {4}//;
    }
    $#tool_tip-- unless $tool_tip[-1];
    if (scalar (@tool_tip) > $line_limit) {
        $#tool_tip = $line_limit - 1;
        $#tool_tip-- unless $tool_tip[-2];
        $tool_tip[-1] = '...';
    }
    print "    \\ '$func': [\n";
    foreach (@tool_tip) {
         print "    \\   '$_',\n";
    }
    print "    \\ ],\n";
}

# Manuall created entries.
# -X

# Automatically generated entries.
__DATA__
abs
accept
alarm
atan2
bind
binmode
bless
caller
chdir
chmod
chomp
chop
chown
chr
chroot
close
closedir
connect
continue
cos
crypt
dbmclose
dbmopen
defined
delete
die
do
dump
each
endgrent
endhostent
endnetent
endprotoent
endpwent
endservent
eof
eval
exec
exists
exit
exp
fcntl
fileno
flock
fork
format
formline
getc
getgrent
getgrgid
getgrnam
gethostbyaddr
gethostbyname
gethostent
getlogin
getnetbyaddr
getnetbyname
getnetent
getpeername
getpgrp
getppid
getpriority
getprotobyname
getprotobynumber
getprotoent
getpwent
getpwnam
getpwuid
getservbyname
getservbyport
getservent
getsockname
getsockopt
glob
gmtime
goto
grep
hex
import
index
int
ioctl
join
keys
kill
last
lc
lcfirst
length
link
listen
local
localtime
lock
log
lstat
m
map
mkdir
msgctl
msgget
msgrcv
msgsnd
my
next
no
package
prototype
oct
open
opendir
ord
our
pack
pipe
pop
pos
print
printf
push
q
qq
quotemeta
qw
qx
qr
rand
read
readdir
readline
readlink
readpipe
recv
redo
ref
rename
require
reset
return
reverse
rewinddir
rindex
rmdir
s
scalar
seek
seekdir
select
semctl
semget
semop
send
setgrent
sethostent
setnetent
setpgrp
setpriority
setprotoent
setpwent
setservent
setsockopt
shift
shmctl
shmget
shmread
shmwrite
shutdown
sin
sleep
socket
socketpair
sort
splice
split
sprintf
sqrt
srand
stat
study
sub
substr
symlink
syscall
sysopen
sysread
sysseek
system
syswrite
tell
telldir
tie
tied
time
times
tr
truncate
uc
ucfirst
umask
undef
unlink
unpack
unshift
untie
use
use 
utime
values
vec
wait
waitpid
wantarray
warn
write
y
