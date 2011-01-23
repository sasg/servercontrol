#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package ServerControl::Module;

use strict;
use warnings;

use Switch;
use File::Copy qw(copy);
use Cwd qw(getcwd);
use Data::Dumper;

use ServerControl::Commons::FS;

sub Parameter {
   my $class  = shift;
   my $params = { @_ };

   if($class ne 'ServerControl::Module::Base') {
      $params->{'create'} = { isa => 'bool',   call => sub {
                                                               ServerControl->d_print("Creating directroy structure\n");
                                                               $class->create_directories;

                                                               ServerControl->d_print("Creating files\n");
                                                               $class->create_files;

                                                               $class->create; 
                                                           } };

      $params->{'start'} = { isa => 'bool', call => sub {
                                                            ServerControl->d_print("Starting instance\n");

                                                            my $wd = getcwd;
                                                            chdir(ServerControl::Args->get->{'path'});

                                                            $class->start;

                                                            chdir($wd);
                                                        } };
      $params->{'stop'} = { isa => 'bool', call => sub {
                                                            ServerControl->d_print("Stopping instance\n");

                                                            my $wd = getcwd;
                                                            chdir(ServerControl::Args->get->{'path'});

                                                            $class->stop;

                                                            chdir($wd);
                                                        } };
   }

   no strict 'refs';

   my $parameter = (ref($class) || $class) . '::parameter';
   $$parameter = $params;
   $$parameter;
}

sub Register {
   my ($class) = @_;
   return if ($class eq 'ServerControl::Module');
   push(@{$ServerControl::MODULES}, $class);
}

sub Directories {
   my $class = shift;
   my $dirs  = { @_ };

   no strict 'refs';

   my $dir_v = $class . '::dirs';
   $$dir_v = $dirs;
   $$dir_v;
}

sub Files {
   my $class  = shift;
   my $files  = { @_ };

   no strict 'refs';

   my $file_v = $class . '::files';
   $$file_v = $files;
   $$file_v;
}

sub import {
   my ($class) = @_;
   $class->Register;
}

sub get_options {
   my ($class) = @_;
   no strict 'refs';

   my $parameter = (ref($class) || $class) . '::parameter';
   my %ret;
   for my $key (keys %{$$parameter}) {
      my $opt = $$parameter->{$key};
      switch ($opt->{'isa'}) {
         case 'bool'   { $ret{$key} = $opt->{'call'}; }
         case 'string' { $ret{"$key=s"} = $opt->{'call'}; }
      }
   }

   return %ret;
}

sub load_module {
   my ($class, $mod) = @_;

   my $mod_class = "ServerControl::Module::$mod";
   my $mod_class_file = "ServerControl/Module/$mod.pm";

   ServerControl->d_print("mod_class: $mod_class\n");
   ServerControl->d_print("mod_class_file: $mod_class_file\n");

   eval {
      require $mod_class_file;
      $mod_class->import;
   };

   if($@) {
      die($@);
   }

   return $mod_class;
}

sub get_path {
   my ($class) = @_;

   return ServerControl::Args->get->{'path'};
}

sub get_name {
   my ($class) = @_;

   return ServerControl::Args->get->{'name'};
}

sub get_directories {
   my ($class) = @_;

   no strict 'refs';

   my $dirs = $class . '::dirs';
   $$dirs;
}

sub get_files {
   my ($class) = @_;

   no strict 'refs';

   my $files = $class . '::files';
   $$files;
}

sub create_directories {
   my ($class) = @_;

   my $path = $class->get_path;
   
   my $dirs = $class->get_directories;
   for my $dir (keys %{$dirs}) {
      my $c = $dirs->{$dir};
      recursive_mkdir($path . '/' . $dir, $c->{'chmod'});
      simple_chown($c->{'user'}, $c->{'group'}, $path . '/' . $dir);
   }
}

sub create_files {
   my ($class) = @_;

   my $path = $class->get_path;

   my $files = $class->get_files;
   for my $file (keys %{$files}) {
      my $c = $files->{$file};

      # wenn scalar, dann nur symlinken
      unless(ref($c)) {
         symlink($c, $path . '/' . $file);
         next;
      }

      if(exists $c->{'call'}) {
         my $code = $c->{'call'};
         &$code($path . '/' . $file);
      } elsif(exists $c->{'link'}) {
         symlink($c->{'link'}, $path . '/' . $file);
      } elsif(exists $c->{'copy'}) {
         copy($c->{'copy'}, $path . '/' . $file);
      }
   }
}

1;
