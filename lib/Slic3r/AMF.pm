package Slic3r::AMF;
use Moo;

use XML::Simple;
use Math::Clipper qw(integerize_coordinate_sets is_counter_clockwise);
use Slic3r::Geometry qw(X Y Z three_points_aligned longest_segment);
use XXX;

sub read_file {
    my $self = shift;
    my ($file) = @_;
    
    my $facets = [];
       _read_ascii($file, $facets);
       return Slic3r::TriangleMesh->new(facets => $facets);
}

sub _read_ascii {
    my ($file, $facets) = @_;
	my $facet;
	my $count = 0;
	my $simple = XML::Simple->new( ); # initialize the object
	my $tree = $simple->XMLin($file); # read the object
	my @coordinates = $tree->{object}->{mesh}->{vertices}->{vertex};
	my @regions = $tree->{object}->{mesh}->{region}->{triangle};
	while ($regions[0][$count])
	{
		my $v1 = $regions[0][$count]->{v1};
		my $v2 = $regions[0][$count]->{v2};
		my $v3 = $regions[0][$count]->{v3};		
		#We dont have a normal facet yet.
		$facet = [ [0, 0, 0] ];
		#pushing facets...
		push(@$facet, [$coordinates[0][$v1]->{coordinates}->{x}, $coordinates[0][$v1]->{coordinates}->{y}, $coordinates[0][$v1]->{coordinates}->{z}]);
		push(@$facet, [$coordinates[0][$v2]->{coordinates}->{x}, $coordinates[0][$v2]->{coordinates}->{y}, $coordinates[0][$v2]->{coordinates}->{z}]);
		push(@$facet, [$coordinates[0][$v3]->{coordinates}->{x}, $coordinates[0][$v3]->{coordinates}->{y}, $coordinates[0][$v3]->{coordinates}->{z}]);
		push @$facets, $facet;		
                undef $facet;
		$count++;
	}
}

sub _read_binary {
    my ($fh, $facets) = @_;
    
    die "bigfloat" unless length(pack "f", 1) == 4;
    
    binmode $fh;
    seek $fh, 80 + 4, 0;
    while (read $fh, $_, 4*4*3+2) {
        my @v = unpack '(f<3)4';
        push @$facets, [ [@v[0..2]], [@v[3..5]], [@v[6..8]], [@v[9..11]] ];
    }
}

sub write_file {
    my $self = shift;
    my ($file, $mesh, $binary) = @_;
    
    open my $fh, '>', $file;
    
    $binary
        ? _write_binary($fh, $mesh->facets)
        : _write_ascii($fh, $mesh->facets);
    
    close $fh;
}

sub _write_binary {
    my ($fh, $facets) = @_;
    
    die "bigfloat" unless length(pack "f", 1) == 4;
    
    binmode $fh;
    print $fh pack 'x80';
    print $fh pack 'L', ($#$facets + 1);
    print $fh pack '(f<3)4S', (map @$_, @$_), 0 for @$facets;
}

sub _write_ascii {
    my ($fh, $facets) = @_;
    
    printf $fh "solid\n";
    foreach my $facet (@$facets) {
        printf $fh "   facet normal %f %f %f\n", @{$facet->[0]};
        printf $fh "      outer loop\n";
        printf $fh "         vertex %f %f %f\n", @$_ for @$facet[1,2,3];
        printf $fh "      endloop\n";
        printf $fh "   endfacet\n";
    }
    printf $fh "endsolid\n";
}
1;
