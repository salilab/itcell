#!/usr/bin/perl -w

# A file handle object that behaves similarly to those returned by CGI's
# upload() method
package TestFh;
use Fcntl;
use overload
    '""' => \&asString;

$FH='fh00000';

sub DESTROY {
    my $self = shift;
    close $self;
}

sub asString {
    my $self = shift;
    # get rid of package name
    (my $i = $$self) =~ s/^\*(\w+::fh\d{5})+//;
    $i =~ s/%(..)/ chr(hex($1)) /eg;
    return $i;
}

sub new {
    my ($pack, $name, $reported_name) = @_;
    if (not defined $reported_name) {
        $reported_name = $name;
    }
    my $fv = ++$FH . $reported_name;
    my $ref = \*{"TestFh::$fv"};
    sysopen($ref, $name, Fcntl::O_RDWR(), 0600) || die "could not open: $!";
    return bless $ref, $pack;
}

package main;

use saliweb::Test;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp;

BEGIN {
    use_ok('itcell');
}

my $t = new saliweb::Test('itcell');

# Check job submission

# Check basic get_submit_page usage
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");
    ok(mkdir("incoming"), "mkdir incoming");

    $cgi->param('mhctype', 'None');
    $cgi->param('email', 'test@example.com');
    $cgi->param('jobname', 'testjob');

    # Will fail without mhcpdbfile
    $cgi->param('mhcpdbfile', '');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "no input PDB";

    ok(open(FH, "> test.pdb"), "Open test.pdb");
    print FH "ATOM   foo\n";
    print FH "HETATM bar\n";
    ok(close(FH), "Close test.pdb");
    $cgi->param('mhcpdbfile', (TestFh->new('test.pdb',
                                           '../../../fo=o b;&a.r')));

    # Will fail without tcr file
    $cgi->param('tcrfile', '');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "no TCR file";

    # Reopen PDB file after failed test
    $cgi->param('mhcpdbfile', (TestFh->new('test.pdb',
                                           '../../../fo=o b;&a.r')));

    ok(open(FH, "> tcr.pdb"), "Open tcr.pdb");
    print FH "ATOM   foo\n";
    print FH "HETATM bar\n";
    ok(close(FH), "Close tcr.pdb");
    $cgi->param('tcrfile', (TestFh->new('tcr.pdb',
                                              '../../../fo=o b;&a.r')));

    # Will fail without antigen sequence
    $cgi->param('antigen', '');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "no antigen sequence";

    $cgi->param('mhcpdbfile', (TestFh->new('test.pdb',
                                           '../../../fo=o b;&a.r')));
    $cgi->param('tcrfile', (TestFh->new('tcr.pdb',
                                              '../../../fo=o b;&a.r')));
    $cgi->param('antigen', 'AAAA');

    my $ret = $self->get_submit_page();
    like($ret, qr/Your job testjob has been submitted.*You will receive/ms,
         "submit page HTML");

    ok(open(FH, "incoming/pMHC.pdb"), "Open pMHC.pdb");
    my $contents;
    {
        local $/ = undef;
        $contents = <FH>
    }
    ok(close(FH), "Close pMHC.pdb");
    like($contents, qr/ATOM   foo/ms,
         "submit page output pMHC file");

    chdir('/') # Allow the temporary directory to be deleted
}
