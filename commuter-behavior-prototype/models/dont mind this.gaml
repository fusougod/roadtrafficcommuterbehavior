/**
* Name: dontmindthis
* Based on the internal empty template. 
* Author: Admin
* Tags: 
*/


model dontmindthis

global {
    file roads_shapefile <- file("../includes/shapefiles/Crossing-Roads.shp");
    file buildings_shapefile <- file("../includes/shapefiles/Crossing-Buildings.shp");
    geometry shape <- envelope(roads_shapefile);
 
    init {
        create road from: roads_shapefile;
        create building from: buildings_shapefile;
    }

}


species road {
    geometry display_shape <- shape + 2.0;
    aspect default {
        draw display_shape color: #black depth: 3.0;
    }
}

species building {
    float height <- rnd(10#m, 20#m) ;
    aspect default {
        draw shape color: #blue border: #black depth: height;
    }
}

species agentType {
    int typeID;
    string typeName;
    float speed;

    aspect default {
        draw typeName;
    }
}

species vehicleMovement {
    int vehicleID;
    point currentLocation <- point(0, 0); // Default location (0, 0)
    point destination <- point(0, 0); // Default destination (0, 0)

    aspect default {
        draw currentLocation color: #red;
        draw destination color: #green;
    }

    reflex moveVehicle {
        // Define vehicle movement behavior
    }
}

species commuterBehavior {
    int commuterID;
    point currentLocation <- point(10, 0); // Default location (0, 0)
    point destination <- point(0, 0); // Default destination (0, 0)
    int patienceLevel;

    aspect default {
        draw currentLocation color: #red;
        draw destination color: #green;
    }

    reflex makeDecision {
        // Define commuter decision-making behavior
    }
}

species terminals {
    int terminalID;
    point terminalLocation <- point(0, 0); // Default location (0, 0)

    aspect default {
        draw terminalLocation color: #orange;
    }
}

species locations {
    int locationID;
    point locationPoint <- point(0, 0); // Default location (0, 0)

    aspect default {
        draw locationPoint color: #purple;
    }
}
experiment road_traffic type: gui {
    parameter "Shapefile for the buildings:" var: buildings_shapefile category: "GIS";
    parameter "Shapefile for the roads:" var: roads_shapefile category: "GIS";
    parameter "Number of people agents" var: nb_people category: "People";
    parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
    parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
    parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
    parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
    parameter "Minimal speed" var: min_speed category: "People" min: 0.1 #km/h;
    parameter "Maximal speed" var: max_speed category: "People" max: 10 #km/h;

		
	output {
		display city_display {
			species building transparency: 0.9;
			species road;
		}
	}
}

