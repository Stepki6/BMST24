/**
* Name: tramDisplay
* Based on the internal empty template. 
* Author: stepi
* Tags: 
*/


model tramDisplay

global
{
	file shape_file_stops <- file("../includes/TPG_SCHEMA_ARRETS.shp");
	file shape_file_tracks <- file("../includes/TPG_LIGNES.shp");
	graph tracks_graph;

	list<string> tram_stop_names <-
	["Grand-Lancy, Palettes",
	"Grand-Lancy, Pontets",
	"Plan-Les-Ouates, Trèfle-Blanc",
	"Lancy-Bachet, Gare",
	"Grand-Lancy, De-Staël",
	"Carouge Ge, Rondeau",
	"Carouge Ge, Ancienne",
	"Carouge Ge, Marché",
	"Carouge Ge, Armes",
	"Genève, Blanche",
	"Genève, Augustins",
	"Genève, Pont-D'Arve",
	"Genève, Plainpalais",
	"Genève, Place De Neuve",
	"Genève, Bel-Air",
	"Genève, Coutance",
	"Genève, Gare Cornavin",
	"Genève, Lyon",
	"Genève, Poterie",
	"Genève, Servette",
	"Genève, Vieusseux",
	"Vernier, Bouchet",
	"Vernier, Balexert",
	"Vernier, Avanchet",
	"Vernier, Blandonnet",
	"Meyrin, Jardin-Alpin-Vivarium",
	"Meyrin, Bois-Du-Lan",
	"Meyrin, Village",
	"Meyrin, Hôpital De La Tour",
	"Meyrin, Maisonnex",
	"Meyrin, Cern"];
	list<string>tram_stop_names2;
	
	geometry shape <- envelope(shape_file_stops);
	
	init
	{
		list<int> testinglist <- [0,1,2,5,4,3];
		loop i from:5 to:0
		{
			testinglist>>3;
		}
		
		float tot<-0;
		loop i from:0 to:180
		{
			tot<-tot+sin(i/2)+cos(i/2);
		}
		write(tot/181);
		write(testinglist);
		create stops from: shape_file_stops with:[name::(read("NOM_ARRET"))];
		create tracks from: shape_file_tracks with:[line::string(read("LIGNE"))];
		list<string> tram_18_stops<-[];
		
		//removes tracks not osed by tram 18
		loop tr over: tracks
		{
			if tr.line != "18"
			{
				ask tr
				{
					do die;
				}
			}
		}
		
		tracks_graph <- as_edge_graph(tracks);
		
		//removes stops not used by tram 18. Note that stops on the internet and in the shapefile may differ.
		//For example, uppercase/lowercase is a huge problem!! 
		tram_stop_names2 <- [];
		loop n over: tram_stop_names
		{
			tram_stop_names2<<lower_case(n);
		}
		
		loop st over: stops
		{
			if not(lower_case(st.name) in (tram_stop_names2))
			{
				ask st
				{
					do die;
				}
			}
		}
		
		create tram number: 1
		{
			stops first_stop;
			loop st over: stops
			{
				if (lower_case(st.name) = (tram_stop_names2[0]))
				{
					first_stop <- st;
					break;
				}
			}
			
			location <- any_location_in(first_stop);
			target <- nil;
			target_index<-0;
			speed <- 30 #km/#h;
			reversed<-false;
		}
	}
}

species tracks
{
	rgb color <- #black;
	string line;
	aspect base
	{
		draw shape color: color;
	}
}

species stops
{
	rgb color <- #magenta;
	aspect base
	{
		draw square(150#m) color: color;
	}
}

species tram skills:[moving]
{
	rgb color <- #red; 
	point target;
	int target_index;
	bool reversed;
	
	reflex update_target when: target = nil
	{
		target_index <- reversed?target_index-1:target_index+1;
			
		if target_index = length(tram_stop_names) or target_index<0 //tram is on the terminus
		{
			write("Terminus, please exit the tram.");
			reversed<-!reversed;
			target_index <- reversed?length(tram_stop_names)-2:1;
		}
		
		stops next_stop;
		loop st over: stops
		{
			if (lower_case(st.name) = (tram_stop_names2[target_index]))
			{
				next_stop <- st;
				write("The next stop is "+next_stop.name);
				break;
			}
		}
			
		target <- any_location_in(next_stop);
	}
	
	reflex move
	{
		do goto(target: target) on: tracks_graph;
		if location=target
		{
			write(tram_stop_names[target_index]);
			target<-nil;
		}
	}
	
	aspect base
	{
		draw circle(150#m) color: color;
	}
}

experiment tram_display type: gui
{
	output
	{
		display tram_moving
		{
			species tracks aspect: base;
			species stops aspect: base;
			species tram aspect: base;
		}
	}
}
/* Insert your model definition here */

