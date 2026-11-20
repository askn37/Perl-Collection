#!/usr/bin/env perl -w

use strict;
use warnings;
use version;
use utf8;
use feature ':5.10';
use File::Basename qw/basename dirname/;
use File::Copy qw/copy/;
use File::Find;
use File::Path qw/mkpath/;
use File::Slurp qw/read_file write_file/;
use File::Spec;
# use Data::Dumper;
use Getopt::Std;
my %opts; getopts("hb:", \%opts);

sub usage {
  print <<__EOL__;
Usage: ${\(basename $0)} [options]...

  If `gcc/dev` is not found within the DFP,
  a conversion from `xc8/avr` is attempted. 

  -b <DFPDIR>
      Specify the directory where the DFP is extracted. 
      If `gcc/dev` does not exist there,
      it will be created from `xc8/avr`.
  -h  Print this message.

__EOL__
  exit($? || 1);
}

### MARK: セットアップ
usage() if $opts{h} || !$opts{b};
chdir($opts{b}) or die "-b <DFPDIR>: $!\n";
-d "xc8/avr" or die "-d \"xc8/avr\": $!\n";
-d "gcc/dev" or mkpath "gcc/dev" or die "mkdir \"gcc/dev\": $!\n";

### MARK: xc8ファイルリスト取得
my @xc8_specs; find({wanted => sub { -f $_ and push @xc8_specs, $_; }, no_chdir => 1}, "xc8/avr/device-specs");

# ディレクトリ構造
foreach my $specfile (@xc8_specs) {
  my $sname = basename $specfile;
  my($mcpu) = $sname =~ m/(\w+)$/s;
  my $dname = File::Spec->catfile("gcc/dev", $mcpu);
  my $fname = File::Spec->catfile($dname, "device-specs", $sname);
  -d $dname or mkpath $dname or die "mkpath \"$dname\": $!\n";
  my $data = read_file $specfile;
  my $mmcu;

  ### 要素置換

  # *avrlibc_startfile:
  $data =~ s<%\{mno-interrupts\|mcvt:crt$mcpu\.cvt\.o; :crt$mcpu\.o\}%s><crt$mcpu.o%s>m;

  # *asm_gccisr:
  $data =~ s<(%\{mrmw\}\n\n)><$1*asm_gccisr:\n\t%{!mno-gas-isr-prologues: -mgcc-isr}\n\n>m;

  # *link_data_start:
  $data =~ s<-Tdata 0x([\da-fA-F]+)><%{!Tdata:-Tdata 0x$1}>m;

  # *self_spec:
  $data =~ s{\*link_fuse_action_define_appdata:[\s\S]+\-mmcu=(\w+)[\s\S]+%<msp8}
    { $mmcu = $1; "*self_spec:\n\t%<mmcu=* -mmcu=$mmcu %<mshort-calls %<msp8" }em;
  
  # %rename
  $data =~ s{(# End of file)}{%rename link old_link\n\n*link:\n\t%(old_link)--defsym=__RODATA_PM_OFFSET__=0x8000\n\n$1}m;

  ### ファイル保存

  my $mmcudir = File::Spec->catfile($dname, $mmcu);
  -d $mmcudir or mkpath $mmcudir or die "mkpath \"$mmcudir\": $!\n";

  my $specdir = dirname $fname;
  -d $specdir or mkpath $specdir or die "mkpath \"$specdir\": $!\n";

  write_file($fname, $data);

  my $crtname = "crt$mcpu.o";
  copy(File::Spec->catfile("xc8/avr/lib/", $mmcu, $crtname),
       File::Spec->catfile($mmcudir, $crtname)) or die "$!\n";

  my $libname = "lib$mcpu.a";
  copy(File::Spec->catfile("xc8/avr/lib/", $mmcu, $libname),
       File::Spec->catfile($mmcudir, $libname)) or die "$!\n";

  # print Dumper [$specfile, $sname, $mcpu, $dname, $fname, $mmcudir, $specdir];
  # print Dumper $data, $mmcu;
}

exit 0;

1;
__END__
使用法: xc8toDev [オプション]...

  DFP内に`gcc/dev`がなければ`xc8/avr`からの変換を試みます。

  -b <DFPDIR>
      DFPを展開したディレクトリを指定します。
      ここに`gcc/dev`が存在しなければ`xc8/avr`から作成されます。
  -h  この文章を印刷します.
