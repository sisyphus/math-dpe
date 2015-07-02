use Config;
use ExtUtils::MakeMaker;

my $defines;

if($Config{nvtype} eq 'double') {$defines = '-DDPE_USE_DOUBLE'}
elsif($Config{nvtype} eq 'long double') {$defines = '-DDPE_USE_LONG_DOUBLE'}
elsif($Config{nvtype} eq 'float128') {$defines = '-DDPE_USE_FLOAT128'}
else {
  warn "Couldn't determine perl's NV type - bailing out";
  exit 0;
}

if($Config{ivtype} eq 'long') {$defines .= ' -DDPE_USE_LONG'}
elsif($Config{ivtype} eq 'long long') {$defines .= ' -DDPE_USE_LONG_LONG'}
else {
  warn "Couldn't determine IV type - bailing out";
  exit 0;
}

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
  'PREFIX' => 'XS_',
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
