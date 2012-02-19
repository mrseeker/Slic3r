package Slic3r::ExtrusionPath;
use Moo;

use Slic3r::Geometry qw(PI X Y epsilon deg2rad rotate_points);
use XXX;

# the underlying Slic3r::Polyline objects holds the geometry
has 'polyline' => (
    is          => 'ro',
    required    => 1,
    handles     => [qw(merge_continuous_lines lines)],
);

# this integer represents the vertical thickness of the extrusion
# expressed in layers
has 'depth_layers' => (is => 'ro', default => sub {1});

has 'flow_spacing' => (is => 'rw');

# perimeter/fill/solid-fill/bridge/skirt/support-material
has 'role'         => (is => 'rw', required => 1);

sub BUILD {
    my $self = shift;
    bless $self->polyline, 'Slic3r::Polyline';
}

sub clip_end {
    my $self = shift;
    my ($distance) = @_;
    
    while ($distance > 0) {
        my $last_point = pop @{$self->points};
        last if !@{$self->points};
        
        my $last_segment_length = $last_point->distance_to($self->points->[-1]);
        if ($last_segment_length <= $distance) {
            $distance -= $last_segment_length;
            next;
        }
        
        my $new_point = Slic3r::Geometry::point_along_segment($last_point, $self->points->[-1], $distance);
        push @{$self->points}, Slic3r::Point->new($new_point);
        $distance = 0;
    }
}

sub clip_with_expolygon {
    my $self = shift;
    my ($expolygon) = @_;
    
    my @paths = ();
    foreach my $polyline ($self->polyline->clip_with_expolygon($expolygon)) {
        push @paths, (ref $self)->new(
            polyline        => $polyline,
            depth_layers    => $self->depth_layers,
            flow_spacing    => $self->flow_spacing,
            role            => $self->role,
        );
    }
    return @paths;
}

sub points {
    my $self = shift;
    return $self->polyline;
}

sub endpoints {
    my $self = shift;
    return ($self->points->[0], $self->points->[-1]);
}

sub reverse {
    my $self = shift;
    @{$self->points} = reverse @{$self->points};
}

sub is_printable { 1 }

sub split_at_acute_angles {
    my $self = shift;
    
    # calculate angle limit
    my $angle_limit = abs(Slic3r::Geometry::deg2rad(40));
    my @points = @{$self->p};
    
    my @paths = ();
    
    # take first two points
    my @p = splice @points, 0, 2;
    
    # loop until we have one spare point
    while (my $p3 = shift @points) {
        my $angle = abs(Slic3r::Geometry::angle3points($p[-1], $p[-2], $p3));
        $angle = 2*PI - $angle if $angle > PI;
        
        if ($angle < $angle_limit) {
            # if the angle between $p[-2], $p[-1], $p3 is too acute
            # then consider $p3 only as a starting point of a new
            # path and stop the current one as it is
            push @paths, (ref $self)->new(
                polyline        => Slic3r::Polyline->new(\@p),
                role            => $self->role,
                depth_layers    => $self->depth_layers,
             );
            @p = ($p3);
            push @p, grep $_, shift @points or last;
        } else {
            push @p, $p3;
        }
    }
    push @paths, (ref $self)->new(
        polyline        => Slic3r::Polyline->new(\@p),
        role            => $self->role,
        depth_layers    => $self->depth_layers,
    ) if @p > 1;
    
    return @paths;
}

sub detect_arcs {
    my $self = shift;
    my ($max_angle, $len_epsilon) = @_;
    
    $max_angle = deg2rad($max_angle || 15);
    $len_epsilon ||= 10 / $Slic3r::resolution;
    
    my @points = @{$self->points};
    my @paths = ();
    
    # we require at least 3 consecutive segments to form an arc
    CYCLE: while (@points >= 4) {
        POINT: for (my $i = 0; $i <= $#points - 3; $i++) {
            my $s1 = Slic3r::Line->new($points[$i],   $points[$i+1]);
            my $s2 = Slic3r::Line->new($points[$i+1], $points[$i+2]);
            my $s3 = Slic3r::Line->new($points[$i+2], $points[$i+3]);
            my $s1_len = $s1->length;
            my $s2_len = $s2->length;
            my $s3_len = $s3->length;
            
            # segments must have the same length
            if (abs($s3_len - $s2_len) > $len_epsilon) {
                # optimization: skip a cycle
                $i++;
                next;
            }
            next if abs($s2_len - $s1_len) > $len_epsilon;
            
            # segments must have the same relative angle
            my $s1_angle = $s1->atan;
            my $s2_angle = $s2->atan;
            my $s3_angle = $s3->atan;
            $s1_angle += 2*PI if $s1_angle < 0;
            $s2_angle += 2*PI if $s2_angle < 0;
            $s3_angle += 2*PI if $s3_angle < 0;
            my $s1s2_angle = $s2_angle - $s1_angle;
            my $s2s3_angle = $s3_angle - $s2_angle;
            next if abs($s1s2_angle - $s2s3_angle) > $Slic3r::Geometry::parallel_degrees_limit;
            next if abs($s1s2_angle) < $Slic3r::Geometry::parallel_degrees_limit;     # ignore parallel lines
            next if $s1s2_angle > $max_angle;  # ignore too sharp vertices
            my @arc_points = ($points[$i], $points[$i+3]),  # first and last points
            
            # now look for more points
            my $last_line_angle = $s3_angle;
            my $last_j = $i+3;
            for (my $j = $i+3; $j < $#points; $j++) {
                my $line = Slic3r::Line->new($points[$j], $points[$j+1]);
                last if abs($line->length - $s1_len) > $len_epsilon;
                my $line_angle = $line->atan;
                $line_angle += 2*PI if $line_angle < 0;
                my $anglediff = $line_angle - $last_line_angle;
                last if abs($s1s2_angle - $anglediff) > $Slic3r::Geometry::parallel_degrees_limit;
                
                # point $j+1 belongs to the arc
                $arc_points[-1] = $points[$j+1];
                $last_j = $j+1;
                
                $last_line_angle = $line_angle;
            }
            
            # s1, s2, s3 form an arc
            my $orientation = $s1->point_on_left($points[$i+2]) ? 'ccw' : 'cw';
            
            # to find the center, we intersect the perpendicular lines
            # passing by midpoints of $s1 and last segment
            # a better method would be to draw all the perpendicular lines
            # and find the centroid of the enclosed polygon, or to
            # intersect multiple lines and find the centroid of the convex hull
            # around the intersections
            my $arc_center;
            {
                my $s1_mid = $s1->midpoint;
                my $last_mid = Slic3r::Line->new($points[$last_j-1], $points[$last_j])->midpoint;
                my $rotation_angle = PI/2 * ($orientation eq 'ccw' ? -1 : 1);
                my $ray1     = Slic3r::Line->new($s1_mid,   rotate_points($rotation_angle, $s1_mid,   $points[$i+1]));
                my $last_ray = Slic3r::Line->new($last_mid, rotate_points($rotation_angle, $last_mid, $points[$last_j]));
                $arc_center = $ray1->intersection($last_ray, 0) or next POINT;
            }
            
            my $arc = Slic3r::ExtrusionPath::Arc->new(
                polyline    => Slic3r::Polyline->new(\@arc_points),
                role        => $self->role,
                orientation => $orientation,
                center      => $arc_center,
                radius      => $arc_center->distance_to($points[$i]),
            );
            
            # points 0..$i form a linear path
            push @paths, (ref $self)->new(
                polyline        => Slic3r::Polyline->new(@points[0..$i]),
                role            => $self->role,
                depth_layers    => $self->depth_layers,
            ) if $i > 0;
            
            # add our arc
            push @paths, $arc;
            Slic3r::debugf "ARC DETECTED\n";
            
            # remove arc points from path, leaving one
            splice @points, 0, $last_j, ();
            
            next CYCLE;
        }
        last;
    }
    
    # remaining points form a linear path
    push @paths, (ref $self)->new(
        polyline        => Slic3r::Polyline->new(\@points),
        role            => $self->role,
        depth_layers    => $self->depth_layers,
    ) if @points > 1;
    
    return @paths;
}

1;
