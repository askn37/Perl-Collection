#!/usr/bin/env perl -w
# $Id: SpaceRemover.pl 2 2019-12-13 06:33:47Z askn $
use FindBin qw($Bin);
# use lib "$Bin/../lib";
use strict;
use warnings;
use utf8;
use File::Find;
use Text::Tabs;
$tabstop = 2;

#
# 所定のテキストファイルについて
#   改行は (CR)LFに統一
#   末尾の空文字を削除
#   行頭のタブを2文字の空白に変換
#

find(\&process, $ARGV[0] || '.');
sub process {
  return unless -f $_ && m{\.(bat|c|cpp|h|md|ino|js|json|svg|txt|css|pl|pm|html|sh)$}io;
  my $file = $_;
  my($FH, @lines);
  my $count = 0;

  # 処理例外
  if ($file eq 'keywords.txt') {
      printf "%s (skip)\n", $file;
    return;
  }
  return unless open $FH, "<", $file;
  while (<$FH>) {
    chomp;
    $count -= length($_);
    ($_) = expand($_);
    $count += s{\s+$}{}o;
    $count += length($_);
    push @lines, $_, "\n";
  }
  $FH->close;
  if ($count) {
    printf "%s count:%d\n", $file, $count;
    if (open $FH, ">", $file) {
      print $FH @lines;
      $FH->close;
    }
    else {
      warn $!;
    }
  }
}
1;
__END__
