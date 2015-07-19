use Config;
use ExtUtils::MakeMaker;

my $defines;

if($Config{nvtype} eq 'long double') {
  $defines = '-DDPE_USE_LONGDOUBLE';
  # Check whether we have DoubleDouble.
  my $nv1 = 1.0;
  my $nv2 = $nv1 + (2 ** -1000);
  if($nv1 != $nv2) {
    $defines .= ' -DLONGDOUBLE_IS_DOUBLEDOUBLE';
  }
}
elsif($Config{nvtype} eq 'double') {$defines = '-DDPE_USE_DOUBLE'}
elsif($Config{nvtype} =~ /float128/) {$defines = '-DDPE_USE_FLOAT128'}
else {
  warn "Couldn't determine perl's NV type - bailing out";
  exit 0;
}

# We can define either DPE_USE_LONG or DPE_USE_LONGLONG,
# but define the latter at your own risk.
$defines .= ' -DDPE_USE_LONG';


for(@ARGV) {
  if($_ eq 'WANT_GMP') {
    $defines .= ' -DWANT_GMP';
    last;
  }
}

my %options = %{
{
  'AUTHOR' => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  'ABSTRACT' => 'Double Plus Exponent - floats with bigger exponents',
  'TYPEMAPS' => [
    'C:/sisyphusion/working/math-dpe/Math-DPE-0.01/typemap'
  ],
  'NAME' => 'Math::DPE',
  'LICENSE'  => 'perl',
  'LIBS' => [
    '-lgmp -lm'
  ],
  'INC' => '-I.',
  'VERSION_FROM' => 'DPE.pm',
  'DEFINE'   => $defines,
  'META_MERGE' => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-dpe.git',
        web => 'https://github.com/sisyphus/math-dpe',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
