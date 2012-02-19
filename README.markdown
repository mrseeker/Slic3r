_Q: Oh cool, a new RepRap slicer?_

A: Yes.

# Slic3r

## What's it?

Slic3r is an STL-to-GCODE translator for RepRap 3D printers, aiming to
be a modern and fast alternative to Skeinforge.

See the [project homepage](http://slic3r.org/) at slic3r.org
for more information.

## What language is it written in?

Proudly Perl, with some parts in C++.
If you're wondering why Perl, see http://xkcd.com/224/

## What's its current status?

Slic3r current key features are:

* multi-platform (Linux/Mac/Win) and packaged as standalone-app with no dependencies required;
* easy configuration/calibration;
* read binary and ASCII STL files as well as AMF;
* powerful command line interface;
* easy GUI;
* multithreaded;
* multiple infill patterns, with customizable density and angle;
* retraction;
* skirt;
* infill every N layers (like the "Skin" plugin for Skeinforge);
* detect optimal infill direction for bridges;
* save configuration profiles;
* center print around bed center point;
* multiple solid layers near horizontal external surfaces;
* ability to scale, rotate and duplicate input object;
* customizable initial and final GCODE;
* support material;
* use different speed for bottom layer and perimeters.

Experimental features include:

* generation of G2/G3 commands for native arcs;
* G0 commands for fast retraction.

Roadmap includes the following goals:

* output some statistics;
* support material for internal perimeters;
* new and better GUI;
* cool;
* more fill patterns.

## Is it usable already? Any known limitation?

Sure, it's very usable. Remember that:

* it doesn't generate support material;
* it only works well with manifold and clean models (check them with Meshlab or Netfabb or http://cloud.netfabb.com/).

## How to install?

It's very easy. See the bottom of the [project homepage](http://slic3r.org/)
for instructions and links to the precompiled packages.

## Can I help?

Sure! Send patches and/or drop me a line at aar@cpan.org. You can also 
find me in #reprap on FreeNode with the nickname _Sound_.

## What's Slic3r license?

Slic3r is licensed under the _GNU Affero General Public License, version 3_.
The author is Alessandro Ranellucci (me).

## How can I invoke slic3r.pl using the command line?

    Usage: slic3r.pl [ OPTIONS ] file.stl
    
        --help              Output this usage screen and exit
        --save <file>       Save configuration to the specified file
        --load <file>       Load configuration from the specified file. It can be used 
                            more than once to load options from multiple files.
        -o, --output <file> File to output gcode to (by default, the file will be saved
                            into the same directory as the input file using the 
                            --output-filename-format to generate the filename)
        
      Output options:
        --output-filename-format
                            Output file name format; all config options enclosed in brackets
                            will be replaced by their values, as well as [input_filename_base]
                            and [input_filename] (default: [input_filename_base].gcode)
      
      Printer options:
        --nozzle-diameter   Diameter of nozzle in mm (default: 0.5)
        --print-center      Coordinates in mm of the point to center the print around 
                            (default: 100,100)
        --use-relative-e-distances
                            Use relative distances for extrusion in GCODE output
        --extrusion-axis    The axis used for extrusion; leave empty to disable extrusion
                            (default: E)
        --z-offset          Additional height in mm to add to vertical coordinates
                            (+/-, default: 0)
        --gcode-arcs        Use G2/G3 commands for native arcs (experimental, not supported
                            by all firmwares)
        --g0                Use G0 commands for retraction (experimental, not supported by all
                            firmwares)
        --gcode-comments    Make GCODE verbose by adding comments (default: no)
        
      Filament options:
        --filament-diameter Diameter in mm of your raw filament (default: 3)
        --extrusion-multiplier
                            Change this to alter the amount of plastic extruded. There should be
                            very little need to change this value, which is only useful to 
                            compensate for filament packing (default: 1)
        --temperature       Extrusion temperature in degree Celsius, set 0 to disable (default: 200)
        
      Speed options:
        --travel-speed      Speed of non-print moves in mm/s (default: 130)
        --perimeter-speed   Speed of print moves for perimeters in mm/s (default: 30)
        --small-perimeter-speed
                            Speed of print moves for small perimeters in mm/s (default: 30)
        --infill-speed      Speed of print moves in mm/s (default: 60)
        --solid-infill-speed Speed of print moves for solid surfaces in mm/s (default: 60)
        --bridge-speed      Speed of bridge print moves in mm/s (default: 60)
        --bottom-layer-speed-ratio
                            Factor to increase/decrease speeds on bottom 
                            layer by (default: 0.3)
        
      Accuracy options:
        --layer-height      Layer height in mm (default: 0.4)
        --first-layer-height-ratio
                            Multiplication factor for the height to slice and print the first
                            layer with (> 0, default: 1)
        --infill-every-layers
                            Infill every N layers (default: 1)
      
      Print options:
        --perimeters        Number of perimeters/horizontal skins (range: 1+, 
                            default: 3)
        --solid-layers      Number of solid layers to do for top/bottom surfaces
                            (range: 1+, default: 3)
        --fill-density      Infill density (range: 0-1, default: 0.4)
        --fill-angle        Infill angle in degrees (range: 0-90, default: 45)
        --fill-pattern      Pattern to use to fill non-solid layers (default: rectilinear)
        --solid-fill-pattern Pattern to use to fill solid layers (default: rectilinear)
        --start-gcode       Load initial gcode from the supplied file. This will overwrite
                            the default command (home all axes [G28]).
        --end-gcode         Load final gcode from the supplied file. This will overwrite 
                            the default commands (turn off temperature [M104 S0],
                            home X axis [G28 X], disable motors [M84]).
        --support-material  Generate support material for overhangs
      
      Retraction options:
        --retract-length    Length of retraction in mm when pausing extrusion 
                            (default: 1)
        --retract-speed     Speed for retraction in mm/s (default: 30)
        --retract-restart-extra
                            Additional amount of filament in mm to push after
                            compensating retraction (default: 0)
        --retract-before-travel
                            Only retract before travel moves of this length in mm (default: 2)
        --retract-lift      Lift Z by the given distance in mm when retracting (default: 0)
       
       Skirt options:
        --skirts            Number of skirts to draw (0+, default: 1)
        --skirt-distance    Distance in mm between innermost skirt and object 
                            (default: 6)
        --skirt-height      Height of skirts to draw (expressed in layers, 0+, default: 1)
       
       Transform options:
        --scale             Factor for scaling input object (default: 1)
        --rotate            Rotation angle in degrees (0-360, default: 0)
        --duplicate-x       Number of items along X axis (1+, default: 1)
        --duplicate-y       Number of items along Y axis (1+, default: 1)
        --duplicate-distance Distance in mm between copies (default: 6)
    
       Miscellaneous options:
        --notes             Notes to be added as comments to the output file
      
      Flow options (advanced):
        --extrusion-width-ratio
                            Calculate the extrusion width as the layer height multiplied by
                            this value (> 0, default: calculated automatically)
        --bridge-flow-ratio Multiplier for extrusion when bridging (> 0, default: 1)

If you want to change a preset file, just do

    slic3r.pl --load config.ini --layer-height 0.25 --save config.ini

If you want to slice a file overriding an option contained in your preset file:

    slic3r.pl --load config.ini --layer-height 0.25 file.stl

## How can I integrate Slic3r with Pronterface?

Put this into *slicecommand*:

    slic3r.pl $s --load config.ini --output $o

And this into *sliceoptscommand*:

    slic3r.pl --load config.ini --ignore-nonexistent-config

Replace `slic3r.pl` with the full path to the slic3r executable and `config.ini`
with the full path of your config file (put it in your home directory or where
you like).
On Mac, the executable has a path like this:

    /Applications/Slic3r.app/Contents/MacOS/slic3r

## How can I specify a custom filename format for output G-code files?

You can specify a filename format by using any of the config options. 
Just enclose them in square brackets, and Slic3r will replace them upon
exporting.
The additional `[input_filename]` and `[input_filename_base]` options will
be replaced by the input file name (in the second case, the .stl extension 
is stripped).

The default format is `[input_filename_base].gcode`, meaning that if you slice
a *foo.stl* file, the output will be saved to *foo.gcode*.

See below for more complex examples:

    [input_filename_base]_h[layer_height]_p[perimeters]_s[solid_layers].gcode
    [input_filename]_center[print_center]_[layer_height]layers.gcode

