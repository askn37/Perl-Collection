#!/usr/bin/env perl -w

use strict;
use warnings;
use version;
use utf8;
use feature ':5.10';
use File::Basename qw/basename dirname/;
use Getopt::Std;
use Data::Dumper;
my %opts; getopts("hSR", \%opts);

sub usage {
  print <<__EOL__;
Usage: ${\(basename $0)} <input

  -S    Print in single-byte format..
  -R    not Remove lines filled with 0xFF.
  -h    Print this message.

__EOL__
  exit($? || 1);
}

usage() if $opts{h};

my $cc = "\e[45m";
my $ac = "\e[42m";
my $tc = "\e[41m";
my $bc = "\e[43m";
my $sc = "\e[46m";
my $ce = "\e[0m";

my ($long, $max) = ('0000', 32);
while (<>) {
  my($count, $addr, $type, $data, $sum, $comment) = $_ =~
    m{^:([\dA-F]{2})([\dA-F]{4})([\dA-F]{2})([\dA-F]*)([\dA-F]{2})(.*)$};
  next unless defined $count; # skip not iHex format
  my($mtype) = $comment =~ m{( [_/\w]+)\s*$};
  $data //= '';
  $mtype //= '';
  next if !$opts{R} && length($mtype) == 0 && $data =~ m{^F+$}; # Remove all F
  if ($type eq '04') {
    $long = $data;
  }
  elsif ($type eq '00') {
    unless (defined($comment) && $comment =~ m{^\S+$}) {
      $max = length($data) if length($data) > $max;
      $comment = ' ' x ($max - length($data));
      $comment .= " // " . $long . ',' . $addr . ': ';
      my ($idx, $sep) = (0, '');
      my $binary = pack 'H*', $data;
      if ($opts{S} || $mtype =~ m{fuse|lock}) {
        foreach my $c (split //, $binary) {
          $comment .= $sep . unpack 'H*', $c;
          $sep = (++$idx) & 3 ? ',' : ', ';
        }
      }
      else {
        foreach my $c (split //, $binary) {
          $c = '.' unless $c gt ' ' && $c le '~';
          $comment .= $c;
        }
      }
    }
  }
  print ':';
  if (-t STDOUT) {
    say $cc, $count, $ac, $addr, $tc, $type, $bc, $data, $sc, $sum, $ce, $comment, $mtype;
  }
  else {
    say $count, $addr, $type, $data, $sum, $comment, $mtype;
  }
}

1;
__END__
