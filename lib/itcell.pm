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
    my $self = shift;
    my $q = $self->cgi;
    my $greeting = <<GREETING;
<p>MultiFit is a computational method for simultaneously fitting atomic structures
of components into their assembly density map at resolutions as low as 25 &#8491;.
The component positions and orientations are optimized with respect to a scoring
function that includes the quality-of-fit of components in the map, the protrusion
of components from the map envelope, as well as the shape complementarity between
pairs of components.
The scoring function is optimized by an exact inference optimizer DOMINO that
efficiently finds the global minimum in a discrete sampling space.
<br />&nbsp;</p>
GREETING

}

sub get_submit_page {
    # TODO
}

sub get_results_page {
    # TODO
}

1;
