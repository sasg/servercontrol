#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package ServerControl::Args;

use strict;
use warnings;
use Data::Dumper;

use vars qw($ARGS);

sub get {
   return $ARGS || {};
}

sub set {
   $ARGS = pop;
}

sub import {
   foreach my $o (@ARGV) {

      # damit man auch ./control start eingeben kann...
      unless($o =~ m/^--/) {
         $o = "--$o";
      }

      my($key, $val) = ($o =~ m/^--([a-zA-Z0-9_\-\.\/]+)=(.*)$/);
      if(!$key && ! defined $val) {
         $o =~ m/^--(.*?)$/;
         $key = $1;
         $val = 1;
      }

      if(exists $ARGS->{$key}) {
         my @tmp;
         if(ref($ARGS->{$key})) {
            @tmp = @{$ARGS->{$key}};
         }
         else {
            @tmp = ($ARGS->{$key});
         }

         $ARGS->{$key} = [];
         push @tmp, $val;

         push(@{$ARGS->{$key}}, @tmp);
      }
      else {
         $ARGS->{$key} = $val;
      }
   }

}

1;
