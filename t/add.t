use strict;
use warnings;
use Math::DPE qw(:all);

print "1..3\n";

my $op1 = dpe_init();		# NaN
my $op2 = dpe_init();		# NaN
my $rop = Math::DPE->new();	# NaN

if($op1 != $op1) {print "ok 1\n"}
else {
  warn "\n\$op1: $op1\n";
  print "not ok 1\n";
}

dpe_set_ui($op1, 123);
dpe_set_ui($op2, 456);

dpe_add($rop, $op1, $op2);
my $check = $op1 + $op2;

if($rop == $check) {print "ok 2\n"}
else {
  warn "\n\$rop: $rop\n\$check: $check\n";
  print "not ok 2\n";
}

if("$rop" =~ /5\.790+\*10\^2/) { print "ok 3\n"}
else {
  warn "\n\$rop: $rop\n";
  print "not ok 3\n";
}
