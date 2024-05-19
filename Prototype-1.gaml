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

    int step_count <- 0;
    bool commuters_reached_hotspot <- false;

    init {
        create road from: roads_shapefile;
        create building from: buildings_shapefile;

        // Create some terminals and hotspots for demonstration
        create terminal number: 10 {
            location <- one_of(road).location;
        }
        create hotspot number: 10 {
            location <- one_of(road).location;
        }
        create commuter_starting_point number: 10 {
            location <- one_of(road).location;
        }

        // Create some vehicles
        create vehicle number: 100 {
            type <- "jeepney";
            capacity <- 10;
            available <- true;
            current_terminal <- one_of(terminal);
            location <- current_terminal.location;
        }

        // Create some commuters
        create commuter number: 100 {
            start_terminal <- one_of(terminal);
            destination_terminal <- one_of(terminal);
            preferred_transport <- "jeepney";
            patience_level <- rnd(5, 15);
            current_terminal <- start_terminal;
            location <- one_of(commuter_starting_point).location;  // Modified to start at commuter_starting_point
            destination <- destination_terminal.location;
            intermediate_hotspot <- one_of(hotspot);
        }
    }

    reflex update_step_count {
        step_count <- step_count + 1;
    }
}

species commuter_starting_point {
    rgb color <- #purple;

    aspect base {
        draw triangle(10) color: color;
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
        draw circle(5) color: color;
    }
}

species commuter skills: [moving] {
    terminal start_terminal;
    terminal destination_terminal;
    string preferred_transport;
    float patience_level;
    terminal current_terminal;
    point location;
    point destination;
    string objective <- "idle";
    point the_target <- nil;
    hotspot intermediate_hotspot;

    aspect base {
        draw circle(2) color: #green;
    }

    reflex start_journey when: objective = "idle" {
        objective <- "travelling_to_hotspot";
        the_target <- intermediate_hotspot.location;
    }

    reflex move when: the_target != nil {
        do goto target: the_target on: road;
        if (the_target = location) {
            if (location = intermediate_hotspot.location) {
                the_target <- destination;
                objective <- "travelling_to_terminal";
            } else {
                the_target <- nil;
                objective <- "idle";
                current_terminal <- destination_terminal;
                commuters_reached_hotspot <- true;
            }
        }
    }
}

species vehicle skills: [moving] {
    string type; // tricycle, jeepney
    int capacity;
    bool available;
    terminal current_terminal;
    point location;
    point destination;
    string objective <- "waiting";
    point the_target <- nil;
    hotspot intermediate_hotspot;

    aspect base {
        draw square(5) color: (type = "jeepney" ? #orange : #yellow);
    }

    reflex assign_trip when: objective = "waiting" and available = true and commuters_reached_hotspot {
        intermediate_hotspot <- one_of(hotspot);
        the_target <- intermediate_hotspot.location;
        objective <- "moving_to_hotspot";
        available <- false;
    }

    reflex move_to_hotspot when: the_target != nil and objective = "moving_to_hotspot" {
        do goto target: the_target on: road;
        if (the_target = location) {
            the_target <- nil;
            destination <- one_of(terminal).location;
            the_target <- destination;
            objective <- "moving_to_terminal";
        }
    }

    reflex move_to_terminal when: the_target != nil and objective = "moving_to_terminal" {
        do goto target: the_target on: road;
        if (the_target = location) {
            the_target <- nil;
            objective <- "waiting";
            current_terminal <- one_of(terminal);
            location <- current_terminal.location;
            available <- true;
        }
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
            species commuter_starting_point aspect: base;
        }
    }
}
