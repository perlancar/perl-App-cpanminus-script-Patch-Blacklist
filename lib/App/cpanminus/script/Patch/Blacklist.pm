package App::cpanminus::script::Patch::Blacklist;

# DATE
# VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

use Config::IOD::Reader;

our %config;

my $p_search_module = sub {
    my $ctx = shift;
    my $orig = $ctx->{orig};
    my $res = $orig->(@_);
    return $res unless $res;

    unless ($App::cpanminus::script::Blacklist) {
        $App::cpanminus::script::Blacklist =
            Config::IOD::Reader->new->read_file(
                $ENV{HOME} . "/cpanm-blacklist.conf");
    }

    my $module_bl = $App::cpanminus::script::Blacklist->{GLOBAL}{module} // [];
    $module_bl = [$module_bl] unless ref $module_bl eq 'ARRAY';
    if (grep { $res->{module} eq $_ } @$module_bl) {
        die "Won't install $res->{module}: blacklisted by module blacklist";
    }

    my $author_bl = $App::cpanminus::script::Blacklist->{GLOBAL}{author} // [];
    $author_bl = [$author_bl] unless ref $author_bl eq 'ARRAY';
    if (grep { $res->{cpanid} eq $_ } @$author_bl) {
        die "Won't install $res->{module}: blacklisted by author blacklist ".
            "(author=$res->{cpanid})";
    }

    $res;
};

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'wrap',
                sub_name    => 'search_module',
                code        => $p_search_module,
            },
        ],
   };
}

1;
# ABSTRACT: Blacklist modules from being installed

=for Pod::Coverage ^(patch_data)$

=head1 SYNOPSIS

In F<~/cpanm-blacklist.conf>:

 module=Some::Module
 module=Another::Module
 author=SOMEID

In the command-line:

 % PERL5OPT=-MModule::Load::In::INIT=App::cpanminus::script::Patch::Blacklist `which cpanm` ...


=head1 DESCRIPTION

This patch adds blacklisting feature to L<cpanm>.

=cut
