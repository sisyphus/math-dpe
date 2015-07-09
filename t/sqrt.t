use strict;
use warnings;
use Math::DPE qw(:all);

print "1..4\n";

my $op1 = dpe_init();		# NaN
my $op2 = dpe_init();		# NaN
my $rop = Math::DPE->new();	# NaN


dpe_set_ui($op1, 125316);


dpe_sqrt($rop, $op1);
my $check = sqrt($op1);

if($rop == $check) {print "ok 1\n"}
else {
  warn "\n\$rop: $rop\n\$check: $check\n";
  print "not ok 1\n";
}

if("$rop" =~ /3\.540\d+\*10\^2$/) { print "ok 2\n"}
else {
  warn "\n\$rop: $rop\n";
  print "not ok 2\n";
}

dpe_set_si($op2, -125316);

dpe_sqrt($rop, $op2);
$check = sqrt($op2);

if(dpe_nan_p($rop)) {print "ok 3\n"}
else {
  warn "\n\$rop: $rop\n";
  print "not ok 3\n";
}

if(dpe_nan_p($check)) {print "ok 4\n"}
else {
  warn "\n\$check: $check\n";
  print "not ok 4\n";
}
