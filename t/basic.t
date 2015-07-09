use strict;
use warnings;
use Config;
use Math::DPE qw(:all);

print "1..1\n";

Math::DPE::_defined_DPE_USE_DOUBLE()             ? warn "\nDPE_USE_DOUBLE             defined\n"
                                                 : warn "\nDPE_USE_DOUBLE             NOT defined\n";

Math::DPE::_defined_DPE_USE_LONGDOUBLE()         ? warn "DPE_USE_LONGDOUBLE         defined\n"
                                                 : warn "DPE_USE_LONGDOUBLE         NOT defined\n";

Math::DPE::_defined_LONGDOUBLE_IS_DOUBLEDOUBLE() ? warn "LONGDOUBLE_IS_DOUBLEDOUBLE defined\n"
                                                 : warn "LONGDOUBLE_IS_DOUBLEDOUBLE NOT defined\n";

Math::DPE::_defined_DPE_USE_FLOAT128()           ? warn "DPE_USE_FLOAT128           defined\n"
                                                 : warn "DPE_USE_FLOAT128           NOT defined\n";

Math::DPE::_defined_DPE_USE_LONG()               ? warn "DPE_USE_LONG               defined\n"
                                                 : warn "DPE_USE_LONG               NOT defined\n";

Math::DPE::_defined_DPE_USE_LONGLONG()           ? warn "DPE_USE_LONGLONG           defined\n"
                                                 : warn "DPE_USE_LONGLONG           NOT defined\n";

my $str_prec;
my $nvtype = $Config{nvtype};

$str_prec = $nvtype eq '__float128'
               ? 33
               : $nvtype eq 'double'
                  ? 16
                  : Math::DPE::_defined_LONGDOUBLE_IS_DOUBLEDOUBLE()
                     ? 31
                     : 18;

if($str_prec == dpe_str_prec()) {print "ok 1\n"}
else {
  warn "\n\$str_prec: $str_prec\ndpe_str_prec(): ", dpe_str_prec(), "\n";
  print "not ok 1\n";
}



