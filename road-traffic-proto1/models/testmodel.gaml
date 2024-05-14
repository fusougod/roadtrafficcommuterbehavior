/**
* Name: testmodel
* Based on the internal empty template. 
* Author: Admin
* Tags: 
*/


model testmodel

global {
	file roads_shapefile <- file("../includes/lspu-baybayin-road.shp");
	file buildings_shapefile <- file("../includes/lspu-baybayin-buildings.shp");
	geometry shape <- envelope(roads_shapefile);
	bool is_night <- true update: current_date.hour < 7 or current_date.hour > 20;
	

	init {
		create road from: roads_shapefile;
		create building from: buildings_shapefile;
		
		
	}

	}


species road {
	geometry display_shape <- shape + 2.0;
	aspect default {
		draw shape color: #black depth: 3.0;
	}
}

species building {
	float height <- rnd(10#m, 20#m) ;
	aspect default {
		draw shape color: #gray border: #black depth: height;
	}
}

experiment main_experiment type: gui {

	output {
	
	display map type: opengl {
		
		species road ;
		light #ambient intensity: 20;
		light #default intensity:(is_night ? 0 : 127);		
		species building  transparency: 0.5;
	}

	
		}
	}

