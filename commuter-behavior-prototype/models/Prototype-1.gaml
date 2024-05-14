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
		
		
	}

	}


species building {
	string type; 
	rgb color <- #gray  ;
	
	aspect base {
		draw shape color: color ;
	}
}

species road  {
	rgb color <- #black ;
	aspect base {
		draw shape color: color ;
	}
}

experiment road_traffic type: gui {
	
		
	output {
		display city_display {
			species building aspect: base ;
			species road aspect: base ;
		}
	}
}


