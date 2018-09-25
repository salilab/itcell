#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';

BEGIN {
    use_ok('itcell');
}

my $t = new saliweb::Test('itcell');

# Test get_navigation_links
{
    my $self = $t->make_frontend();
    my $links = $self->get_navigation_links();
    isa_ok($links, 'ARRAY', 'navigation links');
    like($links->[0], qr#<a href="http://modbase/top/">ITcell Home</a>#,
         'Index link');
    like($links->[1],
         qr#<a href="http://modbase/top/help.cgi\?type=help">Help</a>#,
         'Help link');
}

# Test get_project_menu
{
    my $self = $t->make_frontend();
    my $txt = $self->get_project_menu();
    is($txt, "", 'get_project_menu');
}

# Test get_header
{
    my $self = $t->make_frontend();
    my $txt = $self->get_header();
    like($txt, qr/Integrative T\-cell epitope/ms,
         'get_header');
}

# Test get_footer
{
    my $self = $t->make_frontend();
    my $txt = $self->get_footer();
    like($txt, qr/Contact:.*escramble/ms,
         'get_footer');
}

# Test get_index_page
{
    my $self = $t->make_frontend();
    my $txt = $self->get_index_page();
    like($txt, qr/Select MHC type or upload/ms,
         'get_index_page');
}
