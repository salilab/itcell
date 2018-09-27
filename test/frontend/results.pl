#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp qw(tempdir);

BEGIN {
    use_ok('itcell');
    use_ok('saliweb::frontend');
}

my $t = new saliweb::Test('itcell');

# Check results page

# Test allow_file_download
{
    my $self = $t->make_frontend();
    is($self->allow_file_download('bad.log'), '',
       "allow_file_download bad file");

    is($self->allow_file_download('scores.txt'), 1,
       "                    good file 1");
    is($self->allow_file_download('itcell.log'), 1,
       "                    good file 2");
    is($self->allow_file_download('antigen_seq.txt.out'), 1,
       "                    good file 3");
}

# Check get_results_page
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $tmpdir = tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");

    my $ret = $frontend->get_results_page($job);
    like($ret, '/Your job.*testjob.*failed to produce any output/',
         'get_results_page (failed job)');

    ok(open(FH, "> scores.txt"), "Open scores.txt");
    print FH "testrank 2|3|4|5|6|7|8|9\n";
    ok(close(FH), "Close scores.txt");

    $ret = $frontend->get_results_page($job);
    like($ret, '/Rank.*Number.*Peptide.*testrank/ms',
         '                 (successful job)');

    chdir("/");
}
