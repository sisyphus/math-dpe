use strict;
use warnings;
use Math::DPE qw(:all);

print "1..2\n";

my $op1 = dpe_init();		# NaN
my $op2 = dpe_init();		# NaN
my $rop = Math::DPE->new();	# NaN


dpe_set_ui($op1, 3000);
dpe_set_ui($op2, 20);

dpe_div($rop, $op1, $op2);
my $check = $op1 / $op2;

if($rop == $check) {print "ok 1\n"}
else {
  warn "\n\$rop: $rop\n\$check: $check\n";
  print "not ok 1\n";
}

if("$rop" =~ /1\.50+\*10\^2$/) { print "ok 2\n"}
else {
  warn "\n\$rop: $rop\n";
  print "not ok 2\n";
}
