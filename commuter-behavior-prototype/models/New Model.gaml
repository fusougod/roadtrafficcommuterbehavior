model Prototype1

global {
    // Map used to filter the object to build from the OSM file according to attributes.
    map filtering <- map(["highway"::["primary", "secondary", "tertiary", "motorway", "living_street", "residential", "unclassified"], "building"::["yes"]]);
    // OSM file to load
    file osmfile;

    // Compute the size of the environment from the envelope of the OSM file
    geometry shape <- envelope(osmfile);

    int step_count <- 0;
    bool commuters_reached_hotspot <- false;

    init {
        // Load the OSM file and create osm_agent species
        create osm_agent from: osmfile with: [highway_str::string(read("highway")), building_str::string(read("building"))];

        // From the created generic agents, creation of the selected agents
        ask osm_agent {
            if (length(shape.points) = 1 and highway_str != nil) {
                create node_agent with: [shape::shape, type:: highway_str];
            } else {
                if (highway_str != nil) {
                    create road with: [shape::shape, type:: highway_str];
                } else if (building_str != nil) {
                    create building with: [shape::shape];
                }
            }
            // Do the generic agent die
            do die;
        }

        // Create some terminals and hotspots for demonstration
        create terminal number: 10 {
            location <- one_of(road).location;
        }
        create hotspot number: 10 {
            location <- one_of(road).location;
        }

        // Create some vehicles
        create vehicle number: 10 {
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
            location <- start_terminal.location;
            destination <- destination_terminal.location;
            intermediate_hotspot <- one_of(hotspot);
        }
    }

    reflex update_step_count {
        step_count <- step_count + 1;
    }
}

species osm_agent {
    string highway_str;
    string building_str;
}

species road {
    rgb color <- rnd_color(255);
    string type;
    aspect default {
        draw shape color: color;
    }
}

species node_agent {
    string type;
    aspect default {
        draw square(5) color: #red;
    }
}

species building {
    aspect default {
        draw shape color: #grey;
    }
}

species terminal {
    string type <- "terminal";
    rgb color <- #blue;
    aspect default {
        draw circle(5) color: color;
    }
}

species hotspot {
    string type <- "hotspot";
    rgb color <- #red;
    aspect default {
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

    aspect default {
        draw circle(5) color: #green;
    }

    reflex start_journey when: objective = "idle" {
        objective <- "travelling_to_hotspot";
        the_target <- intermediate_hotspot.location;
    }

    reflex move when: the_target != nil {
        do goto(target: the_target) speed: 1.0;
        if (the_target = location) {
            if (the_target = intermediate_hotspot.location) {
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

    aspect default {
        draw square(5) color: (type = "jeepney" ? #orange : #yellow);
    }

    reflex assign_trip when: objective = "waiting" and available = true and commuters_reached_hotspot {
        intermediate_hotspot <- one_of(hotspot);
        the_target <- intermediate_hotspot.location;
        objective <- "moving_to_hotspot";
        available <- false;
    }

    reflex move_to_hotspot when: the_target != nil and objective = "moving_to_hotspot" {
        do goto(target: the_target) speed: 2.0;
        if (the_target = location) {
            the_target <- nil;
            destination <- one_of(terminal).location;
            the_target <- destination;
            objective <- "moving_to_terminal";
        }
    }

    reflex move_to_terminal when: the_target != nil and objective = "moving_to_terminal" {
        do goto(target: the_target) speed: 2.0;
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
    parameter "File:" var: osmfile <- file (osm_file("../includes/eto don sa crossing.osm", filtering));
    output {
        display city_display {
            species building refresh: false;
            species road refresh: false;
            species node_agent refresh: false;
            species terminal refresh: false;
            species hotspot refresh: false;
            species commuter refresh: false;
            species vehicle refresh: false;
        }
    }
}
