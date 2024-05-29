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
    graph road_network;
    // Simulated time in minutes since midnight (00:00)
    int current_time <- 260; // 6:00 AM in minutes
    int leaving_time <- 1020; // 5:00 PM in minutes
    // Time step in minutes
    float time_step <- 0.1;

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
        }
        road_network <- as_edge_graph(road);
        list<point> terminal_locations <- [{568,680}, {180,405}, {508,428}, {658,512}];
        list<point> house_locations <- [{450,500}, {500,450}, {350,460}, {590,450}];
        list<point> hotspot_locations <- [{540,570}, {700,525}, {130,405}, {570,490}];
        point start_terminal_location <- {300, 300};

        // Create the start terminal
       create house number: 4 {
            location <- house_locations[index];
        }

        // Create some terminals and hotspots for demonstration
        create terminal number: 4 {
            location <- terminal_locations[index];
        }

        create hotspot number: 4 {
         location <- hotspot_locations[index];
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
        create student number: 10 {
            start_terminal <- one_of(house);
            destination_terminal <- one_of(terminal);
            preferred_transport <- "jeepney";
            patience_level <- rnd(5.0, 15.0);
            current_terminal <- start_terminal;
            location <- start_terminal.location;
            destination <- destination_terminal.location;
            intermediate_hotspot <- one_of(hotspot);
        }
        create worker number: 50 {
            start_terminal <- one_of(house);
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
        draw square(1) color: #red;
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

species house {
    string type <- "house";
    rgb color <- #purple;
    aspect default {
        draw triangle(9) color: color;
    }
}

species hotspot {
    string type <- "hotspot";
    rgb color <- #red;
    aspect default {
        draw circle(5) color: color;
    }
}

species student skills: [moving] {
    house start_terminal;
    terminal destination_terminal;
    string preferred_transport;
    float patience_level;
    house current_terminal;
    point location;
    point destination;
    string objective <- "idle";
    point the_target <- nil;
    hotspot intermediate_hotspot;
    float speed <- 1.0;

    aspect default {
        draw circle(4) color: #pink;
    }

    reflex start_journey when: objective = "idle" {
        objective <- "travelling_to_hotspot";
        the_target <- intermediate_hotspot.location;
    }

    reflex move when: the_target != nil {
        do goto target: the_target on: road_network;
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

    // When it's time to leave, go back to the terminal
    reflex leave when: current_time >= leaving_time and objective != "returning_to_terminal" {
        the_target <- current_terminal.location;
        objective <- "returning_to_terminal";
    }

    reflex return_to_terminal when: objective = "returning_to_terminal" and the_target != nil {
        do goto target: the_target on: road;
        if (the_target = location) {
            the_target <- nil;
            objective <- "idle";
        }
    }

    // Reset for the next day
    reflex reset_day when: current_time = 0 {
        objective <- "idle";
        the_target <- nil;
        location <- start_terminal.location;
        current_terminal <- start_terminal;
    }
}

species worker skills: [moving] {
    house start_terminal;
    terminal destination_terminal;
    string preferred_transport;
    float patience_level;
    house current_terminal;
    point location;
    point destination;
    string objective <- "idle";
    point the_target <- nil;
    hotspot intermediate_hotspot;

    aspect default {
        draw circle(2) color: #green;
    }

    reflex start_journey when: objective = "idle" {
        objective <- "travelling_to_hotspot";
        the_target <- intermediate_hotspot.location;
    }

    reflex move when: the_target != nil {
        do goto target: the_target on: road_network;
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

    // Reset for the next day
    reflex reset_day when: current_time = 0 {
        objective <- "idle";
        the_target <- nil;
        location <- start_terminal.location;
        current_terminal <- start_terminal;
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
        do goto target: the_target on: road_network speed: 2.0;
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
            species student refresh: false;
            species worker refresh: false;
            species vehicle refresh: false;
            species house refresh: false;
        }
    }
}
