package itcell;
use saliweb::frontend;
use strict;

our @ISA = "saliweb::frontend";

sub new {
    return saliweb::frontend::new(@_, @CONFIG@);
}

sub get_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    return [
        $q->a({-href=>$self->index_url}, "Integrative T-Cell Epitope Prediction Home"),
        $q->a({-href=>$self->queue_url}, "Integrative T-Cell Epitope Prediction Current queue"),
        $q->a({-href=>$self->help_url}, "Integrative T-Cell Epitope Prediction Help"),
        $q->a({-href=>$self->contact_url}, "Integrative T-Cell Epitope Prediction Contact")
        ];
}

sub get_project_menu {
    # TODO
}

sub get_footer {
    # TODO
}

sub get_index_page {
    # TODO
}

sub get_submit_page {
    # TODO
}

sub get_results_page {
    # TODO
}

1;
