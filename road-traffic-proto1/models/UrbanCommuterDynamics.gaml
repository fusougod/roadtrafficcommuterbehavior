/**
* Name: Definition of people agents
* Author:
* Description: second part of the tutorial: Road Traffic
* Tags: gis
*/

model UrbanCommuterDynamics

global {
	file roads_shapefile <- file("../includes/lspu-baybayin-road.shp");
	file buildings_shapefile <- file("../includes/lspu-baybayin-buildings.shp");
	geometry shape <- envelope(roads_shapefile);
	

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
		draw shape color: #blue border: #black depth: height;
	}
}


experiment main_experiment type: gui {

	output {
	
	display map type: opengl {
		
		species road ;
		
		species building transparency: 0.7 ;
	}

	
		}
	}
