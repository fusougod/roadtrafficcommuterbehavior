/**
* Name: Prototype1
* Based on the internal empty template. 
* Author: Admin
* Tags: 
*/

model Prototype1

global {
    file roads_shapefile <- file("../includes/shapefiles/Crossing-Roads.shp");
    file buildings_shapefile <- file("../includes/shapefiles/Crossing-Buildings.shp");
    geometry shape <- envelope(roads_shapefile);

    init {
        create road from: roads_shapefile;
        create building from: buildings_shapefile;

        // Create some terminals and hotspots for demonstration
        create terminal number: 3 {
            location <- one_of(road).location;
        }
        create hotspot number: 5 {
            location <- one_of(road).location;
        }

        // Create some vehicles
        create vehicle number: 5 {
            type <- "jeepney";
            capacity <- 10;
            available <- true;
            current_terminal <- one_of(terminal);
            location <- current_terminal.location;
        }

        // Create some commuters
        create commuter number: 10 {
            start <- one_of(terminal);
            destination <- one_of(terminal);
            preferred_transport <- "jeepney";
            patience_level <- rnd(5, 15);
            current_terminal <- start;
            location <- start.location;
        }
    }
}

species building {
    string type; 
    rgb color <- #gray;

    aspect base {
        draw shape color: color;
    }
}

species road {
    rgb color <- #black;

    aspect base {
        draw shape color: color;
    }
}

species terminal {
    string type <- "terminal";
    rgb color <- #blue;

    aspect base {
        draw circle(5) color: color;
    }
}

species hotspot {
    string type <- "hotspot";
    rgb color <- #red;

    aspect base {
        draw circle(3) color: color;
    }
}

species commuter {
    terminal start;
    terminal destination;
    string preferred_transport;
    float patience_level;
    terminal current_terminal;

    aspect base {
        draw circle(2) color: #green;
    }
}

species vehicle {
    string type; // tricycle, jeepney
    int capacity;
    bool available;
    terminal current_terminal;

    aspect base {
        draw square(3) color: (type = "jeepney" ? #orange : #yellow);
    }
}

experiment road_traffic type: gui {
    output {
        display city_display {
            species building aspect: base;
            species road aspect: base;
            species terminal aspect: base;
            species hotspot aspect: base;
            species commuter aspect: base;
            species vehicle aspect: base;
        }
    }
}
