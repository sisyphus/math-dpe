use strict;
use warnings;
use Math::DPE qw(:all);

print "1..4\n";

my $op1 = dpe_init();		# NaN
my $op2 = dpe_init();		# NaN
my $rop = Math::DPE->new();	# NaN

dpe_set_ui($op1, 123);
dpe_set_ui($op2, 456);

dpe_sub($rop, $op1, $op2);
my $check = $op1 - $op2;

if($rop == $check) {print "ok 1\n"}
else {
  warn "\n\$rop: $rop\n\$check: $check\n";
  print "not ok 1\n";
}

if("$rop" =~ /\-3\.33\d+\*10\^2/ || "$rop" =~ /\-3\.329\d+\*10\^2/) { print "ok 2\n"}
else {
  warn "\n\$rop: $rop\n";
  print "not ok 2\n";
}

dpe_swap($op1, $op2);

dpe_sub($rop, $op1, $op2);
$check = $op1 - $op2;

if($rop == $check) {print "ok 3\n"}
else {
  warn "\n\$rop: $rop\n\$check: $check\n";
  print "not ok 3\n";
}

if("$rop" =~ /^\s?3\.33\d+\*10\^2/ || "$rop" =~ /^\s?3\.329\d+\*10\^2/) { print "ok 4\n"}
else {
  warn "\n\$rop: [$rop]\n";
  print "not ok 4\n";
}
