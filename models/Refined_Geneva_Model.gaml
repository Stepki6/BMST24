/**
* Name: RefinedGenevaModel
* Based on the internal empty template. 
* Author: stepi
* Tags: 
*/


model RefinedGenevaModel

global 
{
	bool small_model<-true;
	bool beautiful_display<-false;
	int daily_relocations<-600;
	//https://www.swisscommunity.org/en/news-media/swiss-review/article/electric-car-sales-are-booming-in-switzerland
	int switch_to_electric<-130;
	int switched_to_electric<-0;
	int total_switches<-0;
	int total_electric<-0;
	bool is_batch<-false;
	
	bool environment_without_tax<-false;
	bool tax_depends_on_car_usage <- true;
	float beginning_tax <-0.01/#km;
	float gas_tax_increment<-0.0025/#km;
	float diesel_tax_increment<-0.003/#km;
	float electric_tax_increment<-0/#km;
	
	float happiness_reduction_per_car_use<-0.00016;
	float increase_happiness_reduction_per_car_use<-0;
	
	int REDUCTION <- small_model? 12:1;
	file shape_file_buildings <- file("../includes/CAD_BATIMENT_HORSOL.shp");
	file shape_file_roads <- file("../includes/GMO_GRAPHE_ROUTIER.shp");
	file shape_file_lignes <- file("../includes/TPG_LIGNES.shp");
	file shape_file_stops <- file("../includes/TPG_SCHEMA_ARRETS.shp");
	file shape_file_cyclo <- file("../includes/OTC_CARTEVELO_ITINERAIRES.shp");
	file shape_file_perimeter <- file("../includes/PAV_PERIMETRE.shp");
	geometry shape <- envelope(shape_file_buildings);
	float original_step <- 60 #mn;
	float step<-original_step;
	graph roadGr;
	graph ligneGr;
	graph cycloGr;
	int init_nb_people <- 360000/REDUCTION;//360000;
	float emissions <- 0;
	
	int population_growth<-round(((504000*0.0097)/REDUCTION)/60);
	
	int PAV_work<-0;
	int PAV_housing<-0;
	
	list<building> residential_buildings;
	list<building> industrial_buildings;
	list<building> education_buildings;
	list<building> entertainment_buildings;
	
	int housingCap <- 0;
	int workingCap <- 0;
	
	date starting_date <- date("2019-01-01 05:00:00");
	int public_transport_speed <- 25 #km/#h;
	int car_speed <- 50 #km/#h;
	int bike_speed <- 20 #km/#h;
	int walk_speed <- 5 #km/#h;
	
	float public_transport_emissions <- 0;
	float car_emissions <- 0.01;
	float bike_emissions <- 0;
	
	int min_work_start <- 6;
    int max_work_start <- 9;
    int min_work_end <- 16; 
    int max_work_end <- 19; 
    float min_speed <- 30 #km / #h;
    float max_speed <- 50 #km / #h; 
    
    //https://8billiontrees.com/carbon-offsets-credits/how-much-co2-does-a-car-emit-per-mile/
    float gasoline_emissions_rate <- 0.192 #kg/#km;
    float diesel_emissions_rate <- 0.171 #kg/#km;
    float electric_emissions_rate <- 0.053 #kg/#km;
    
    //https://www.bfs.admin.ch/bfs/en/home/statistics/regional-statistics/regional-portraits-key-figures/cantons/geneva.html
    float has_car_probability <- 1.0; //0.44 is per 1000 people but kids dont drive. I only work with adults 18-65. I do not want to calculate it => anybody can use a car.
    
    int cars <-0;
    int nb_days<-0;
    
    float extra_time <- 0.25#h;
    
    bool displaying_walking <- false;
    bool displaying_biking <- false;
    bool displaying_public_transporting <- false;  
    bool displaying_car_riding <- false;
    
    int walk_display_counter<-0;
    int bike_display_counter<-0;
    int TPG_display_counter<-0;
    int car_display_counter<-0;
    
    float tax_sum<-0;
    float happiness_sum<-0;
    float total_time_to_work<-0;
    int walkers<-0;
    int bikers<-0;
    int TPG_users<-0;
    int car_users<-0;
    
    int tax_impact_on_relocation<-50;
    
    int nb_people->{length(person)};
    
    list<string> tram18_stop_names <-
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
	"Vernier, Blandonnet",
	"Vernier, Blandonnet",
	"Meyrin, Jardin-Alpin-Vivarium",
	"Meyrin, Bois-Du-Lan",
	"Meyrin, Village",
	"Meyrin, Hôpital De La Tour",
	"Meyrin, Maisonnex",
	"Meyrin, Cern"];
	list<string>tram18_stop_names2;
	list<int> list_of_days<-[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59];
	list<int> shuffled_list_of_days<-[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59];
	list<building> reference_buildings<-[];
	int total_relocations<-0;
	
	init 
	{
		create perim from: shape_file_perimeter;
		create ligne from: shape_file_lignes with: [_line::string(read("LIGNE"))];
		ligneGr <- as_edge_graph(ligne);
		
		
		tram18_stop_names2 <- [];
		loop n over: tram18_stop_names
		{
			tram18_stop_names2<<lower_case(n);
		}
		create stop from: shape_file_stops with: [name::string(read ("NOM_ARRET")), is_displayed::lower_case(string(read ("NOM_ARRET")))in(tram18_stop_names2) and beautiful_display];
		
		loop s over:stop
		{
			if "cartigny, village" in lower_case(s.name)
			{
				write("yes");
			}
		}
		
		list<stop> tram18_stops<-stop where (lower_case(each.name) in (tram18_stop_names2));
		write(tram18_stops);
		
		loop i from:0 to:5
		{
			create tram18 number: 1
			{
				stop first_stop;
				my_stops<-tram18_stops;
				loop st over: stop
				{
					if (lower_case(st.name) = (tram18_stop_names2[6*i]))
					{
						first_stop <- st;
						break;
					}
				}
				
				location <- any_location_in(first_stop);
				target <- nil;
				target_index<-6*i;
				speed <- public_transport_speed;
				reversed<-false;
			}
			
			create tram18 number: 1
			{
				stop first_stop;
				my_stops<-tram18_stops;
				loop st over: stop
				{
					if (lower_case(st.name) = (tram18_stop_names2[length(tram18_stop_names)-1-6*i]))
					{
						first_stop <- st;
						break;
					}
				}
				
				location <- any_location_in(first_stop);
				target <- nil;
				target_index<-length(tram18_stop_names)-1-6*i;
				speed <- public_transport_speed;
				reversed<-true;
			}
		}
		
		
		create cyclo_road from: shape_file_cyclo;
		cycloGr <- as_edge_graph(cyclo_road);
		
		create road from: shape_file_roads ;
		roadGr <- as_edge_graph(road);
		
		create building from: shape_file_buildings with: [dest::string(read ("DESTINAT")), comm::int(read("NO_COMM"))]
		{
			ppl_inside <- 0;
			is_reference<-false;
			if dest in (["WC public", "Temple", "Dépôt", "Garage privé", "Hangar", "EMS", "Stade", "Serre", "Garage", "Hôtel", "Chapelle", "Chauffage", "Cheminée", "Commerce", "Compostage", "Douane", "Déchetterie", "Ecurie", "Eglise", "Ferme", "Installation de chauffage", "Manége", "Mission permanente", "Poulailler", "Cabine T+T", "Caserne", "Silo", "Stand de tir", "Synagogue"]) 
			or "Autre" in(dest)
			or "Citerne" in(dest)
			or "pénitenciaire" in(dest)
			or "soins" in(dest)
			or "Halle" in(dest)
			or "Hangar" in(dest)
			or "Instal." in(dest)
			or "Jardin" in(dest)
			or "Chauffage" in(dest)
			or "Installation" in(dest)
			//or not(comm in([8, 21, 24, 31]))
			{
				ask self
				{
					do die;
				}
			}
			else
			{
				closest_stop <- stop closest_to(self);
			}			
		}
		
		//list<building>reference_buildings <- [];
		
		loop bb over: building
		{
			if city_cells(bb.location).reference_building = nil
			{
				city_cells(bb.location).reference_building <- bb;
				bb.is_reference<-true;
				//reference_buildings << bb;
			}
			
			if "Foyer " in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- max(1,round(60/REDUCTION));
				housingCap <- housingCap+bb.capacity;
			}
			else if "Hab. - rez" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- max(1,round(2/REDUCTION));
				housingCap <- housingCap+bb.capacity;
			}
			else if "Hab. deux" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- max(1,round(4/REDUCTION));
				housingCap <- housingCap+bb.capacity;
			}
			else if "Habitation - activ" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- max(1,round(5/REDUCTION));
				housingCap <- housingCap+bb.capacity;
			}
			else if "Habitation un" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- max(1,round(2/REDUCTION));
				housingCap <- housingCap+bb.capacity;
			}
			else if "Hab plus" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- max(1,round(29/REDUCTION));
				housingCap <- housingCap+bb.capacity;
			}
			else if "Internat" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- max(1,round(700/REDUCTION));
				housingCap <- housingCap+bb.capacity;
			} 
			else if "Résidence" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- max(1,round(2/REDUCTION));
				housingCap <- housingCap+bb.capacity;
			}  
			else if "Administration" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(300/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Arsenal" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(500/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Atelier" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(30/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Bureaux" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(200/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Central" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(15/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Centre c" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(150/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Centre d" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(25/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Centre s" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(10/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Cinéma" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(10/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Consultat" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(5/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Ecole" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(25/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Hôpi" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(100/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Mairie" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(20/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Man" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 1;
				workingCap <- workingCap+1;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 1;
			}  
			else if "Mus" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(15/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "ONU" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(10/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Ouvrage" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 1;
				workingCap <- workingCap+1;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 1;
			}  
			else if "Parking" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 1;
				workingCap <- workingCap+1;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 1;
			}  
			else if "Patinoire" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 1;
				workingCap <- workingCap+1;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 1;
			}  
			else if "Piscine" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(10/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Police" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(200/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Porcherie" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(2/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Poste" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(20/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Restaurant" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(5/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "feu" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(25/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Station" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(2/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Sécurité" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <-max(1,round(5/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Thé" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(15/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Usine" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- max(1,round(15/REDUCTION));
				workingCap <- workingCap+bb.capacity;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + bb.capacity;
			}  
			else if "Univ" in (bb.dest)
			{
				bb.type <- "EDUCATION";
				bb.capacity <- max(1,round(10000/REDUCTION));
			}  
			else if "CONSERVA" in (bb.dest)
			{
				bb.type <- "EDUCATION";
				bb.capacity <- max(1,round(500/REDUCTION));
			}  
			else if "Coll" in (bb.dest)
			{
				bb.type <- "EDUCATION";
				bb.capacity <- max(1,round(300/REDUCTION));
			}  
			else
			{
				bb.type <- "ENTERTAINMENT";
				bb.capacity <- -1;
			}
		}
		
		if housingCap>360000/REDUCTION+3000/REDUCTION
		{
			float survive<-(360000/REDUCTION)/housingCap;
			loop bb over: building where (each.type="RESIDENTIAL")
			{
				if !bb.is_reference and flip(1-survive)
				{
					housingCap<-housingCap-bb.capacity;
					residential_buildings>>bb;
					ask bb
					{
						do die;
					}
				}
			}
		}
		
		loop i from: length(building)-1 to:0
		{
			if dead(building[i])
			{
				building>>building[i];
			}
		}
		
		write("Housing"+housingCap);
		write("Work"+workingCap);
		
		/*
		if small_model
		{
			loop bb over: building
			{
				if bb.capacity>0
				{
					bb.capacity<-max(1, int(bb.capacity/REDUCTION));
				}
			}
			
			housingCap<-housingCap/REDUCTION-5;
			workingCap<-workingCap/REDUCTION-5;
		}
		*/
		
		/*
		loop bb over: building
		{
			if bb intersects perim[0].shape
			{
				bb.color <- #green;
				switch bb.type
				{
					match "RESIDENTIAL"
					{
						PAV_housing<-PAV_housing+bb.capacity;
					}
					match "INDUSTRIAL"
					{
						PAV_work<-PAV_work+bb.capacity;
					}
				}
			}
		}
		
		write(PAV_housing);
		write(PAV_work);
		*/
		
		residential_buildings <- shuffle(building where (each.type="RESIDENTIAL"));
		industrial_buildings <- shuffle(building where (each.type="INDUSTRIAL"));
		education_buildings <- shuffle(building where (each.type="EDUCATION"));
		entertainment_buildings <- shuffle(building where (each.type="ENTERTAINMENT"));
		
		
		loop cell over: city_cells
		{
			//cell.color <- rgb(255*max([(5000-cell.work_places)/5000,0]),255*max([(5000-cell.work_places)/5000,0]),255);
			cell.emissions_in_cell <- 0;
		}
		
		int living_index <-0;
		int education_index <-0;
		int work_index <-0;
		
		create person number: min(housingCap,workingCap)-1000/REDUCTION
		{
			target <- nil;
			living_place <- residential_buildings[living_index];
			living_place.ppl_inside <- living_place.ppl_inside+1;
			if living_place.ppl_inside>=living_place.capacity
			{
				living_index<-living_index+1;
			}
			
			if "Internat" in (living_place.dest)
			{
				is_student <- true;
				working_place <- education_buildings[education_index];
				working_place.ppl_inside <- working_place.ppl_inside+1;
				
				if working_place.ppl_inside>=working_place.capacity
				{
					education_index<-education_index+1;
				}
			}
			else
			{
				is_student <- false;
				working_place <- industrial_buildings[work_index];
				working_place.ppl_inside <- working_place.ppl_inside+1;
				
				if working_place.ppl_inside>=working_place.capacity
				{
					work_index<-work_index+1;
				}
			}
			
			location <- any_location_in(living_place);
			
			start_work <- rnd(min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			objective <- "resting";			
			speed <- rnd(min_speed, max_speed);
			
			has_car <- flip(has_car_probability);
			if has_car
			{
				float tmp <- rnd(1.0);
				if tmp <0.6
				{
					car_type <- "GAS";
				}
				else if tmp <0.955
				{
					car_type <- "DIESEL";
				}
				else
				{
					car_type <- "ELECTRIC";
					total_electric<-total_electric+1;
				}
			}
			else
			{
				car_type <- nil;
			}
			
			morning_choice <- nil;
			
			happiness <- 1.0;
			tax<-has_car and not("ELECTRIC" in car_type)?beginning_tax:0;
			wants_relocate<-false;
			relocation_attempted<-false;
			
			car_used <-0;
			car_not_used <-0;
			prev_car_used <-0;
			prev_car_not_used <-0;
			nb_car_used<-0;
			total_nb_car_used<-0;
			
			if 1.35*(living_place.location distance_to working_place.location)<5#km
			{
				commuting_time <- 0;
			}
			else if !has_car
			{
				commuting_time <- 1.35*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    			1.35*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed;
			}
			else
			{
				commuting_time<-min(1.35*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    			1.35*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed,
    			1.35*(living_place.location distance_to working_place.location)#m/car_speed);
			}
			
			distance_to_work<-1.35*(living_place.location distance_to working_place.location);
			
			if has_car
			{
				switch car_type
				{
					match "GAS"
					{
						tax_increase<-gas_tax_increment;
					}
					match "DIESEL"
					{
						tax_increase<-diesel_tax_increment;
					}
					match "ELECTRIC"
					{
						tax_increase<-electric_tax_increment;
					}
					default
					{
						tax_increase<-0;
					}
				}
			}
			
			days_for_car_usage<-[];
				loop i from:0 to:59
				{
					if shuffled_list_of_days index_of i < 30
					{
						days_for_car_usage<<i;
					}
				}
		}
		
		list<int> tot_dst<-[0,0,0,0,0,0,0,0,0,0,0];
		float d<-0;
		loop p over:person
		{
			float dst <-1.35*((p.living_place.location) distance_to (p.working_place.location));
			d<-d+dst;
			if dst<1#km
			{
				tot_dst[0]<-tot_dst[0]+1;
			} 
			else if dst<2#km
			{
				tot_dst[1]<-tot_dst[1]+1;
			} 
			else if dst<3#km
			{
				tot_dst[2]<-tot_dst[2]+1;
			} 
			else if dst<4#km
			{
				tot_dst[3]<-tot_dst[3]+1;
			} 
			else if dst<5#km
			{
				tot_dst[4]<-tot_dst[4]+1;
			} 
			else if dst<6#km
			{
				tot_dst[5]<-tot_dst[5]+1;
			} 
			else if dst<8#km
			{
				tot_dst[6]<-tot_dst[6]+1;
			} 
			else if dst<10#km
			{
				tot_dst[7]<-tot_dst[7]+1;
			} 
			else if dst<15#km
			{
				tot_dst[8]<-tot_dst[8]+1;
			} 
			else if dst<20#km
			{
				tot_dst[9]<-tot_dst[9]+1;
			} 
			else
			{
				tot_dst[10]<-tot_dst[10]+1;
			}
		}
		write(length(person));
		write(tot_dst);
		write(d/length(person));
		
		
		/*
		ask city_cells
		{
			if self.reference_building != nil
			{
				loop bb over: reference_buildings
				{
					self.paths << city_cells(bb.location)::path_between(roadGr, any_location_in(self.reference_building), bb.location);
				}
			}
			write(self.paths);
		}
		*/
		
		//write(length(reference_buildings));
		
		reference_buildings<-building where each.is_reference;
		write("Done");		
	}
	
	reflex step_adjustment3 when: "06 00:00:00" in(string(current_date)) and cycle>0
	{
		if month(current_date)in[1,3,5,7,8,10,12]
		{
			step<-26#d;
		}
		else if month(current_date)in[4,6,9,11]
		{
			step<-25#d;
		}
		else
		{
			if mod(year(current_date),4)=0 and mod(year(current_date),100)!=0
			{
				step<-24#d;
			}
			else
			{
				step<-23#d;
			}
		}
	}
	
	reflex step_adjustment4 when: "01 00:00:00" in(string(current_date)) and cycle>0
	{
		step <- original_step;
	}
		
	reflex adjust_step_for_display when: beautiful_display and "06:00:00" in string(current_date)
	{
		step<-15#s;
	}
	
	reflex adjust_step_for_display2 when: beautiful_display and "06:15:00" in string(current_date)
	{
		step<-45#mn;
	}
	
	reflex adjust_step_for_display3 when: beautiful_display and "07:00:00" in string(current_date)
	{
		step<-60#mn;
	}
	
	/*
	reflex stopsim when: "2040" in string(current_date)
	{
		do pause;
	}
	* 
	*/
	
	reflex writedate when: not is_batch
	{
		write(current_date);
	}
	
	reflex writeEmissions when: mod(cycle,12) = 0 and cycle > 0 and not is_batch
	{
		write(emissions);
	}
	
	reflex expand_population when: "23:00:00" in(string(current_date))
	{
		list<city_cells>cls <- [525,526,552,553];
		int len<-length(reference_buildings);
		reference_buildings<-shuffle(reference_buildings);
		loop i from: 0 to: round(population_growth)
		{
			create person
			{
				target <- nil;
				living_place <- city_cells(cls[mod(i,4)]).reference_building;
				living_place.capacity<-living_place.capacity+1;
				living_place.ppl_inside<-living_place.ppl_inside+1;
				
				if i<8
				{
					working_place <- city_cells([445,446,472,473,474,499,500,501][mod(i,8)]).reference_building;
				}
				else
				{
					working_place<-reference_buildings[mod(i,len)];
				}
				working_place.capacity <- working_place.capacity+1;
				working_place.ppl_inside <- working_place.ppl_inside+1;
			
				location <- any_location_in(living_place);
			
				start_work <- rnd(min_work_start, max_work_start);
				end_work <- rnd(min_work_end, max_work_end);
				objective <- "resting";			
				speed <- rnd(min_speed, max_speed);
			
				has_car <- flip(has_car_probability);
				if has_car
				{
					float tmp <- rnd(1.0);
					if tmp <0.6
					{
						car_type <- "GAS";
					}
					else if tmp <0.98
					{
						car_type <- "DIESEL";
					}
					else
					{
						car_type <- "ELECTRIC";
						total_electric<-total_electric+1;
					}
				}
				else
				{
					car_type <- nil;
				}
			
				morning_choice <- nil;
			
				happiness <- 1.0;
				tax<-has_car and not ("ELECTRIC" in car_type)?beginning_tax:0;
				wants_relocate<-false;
				relocation_attempted<-false;
			
				car_used <-0;
				car_not_used <-0;
				prev_car_used <-0;
				prev_car_not_used <-0;
				nb_car_used<-0;
				total_nb_car_used<-0;
			
				if 1.35*(living_place.location distance_to working_place.location)<5#km
				{
					commuting_time <- 0;
				}
				else if !has_car
				{
					commuting_time <- 1.35*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    				1.35*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed;
				}
				else
				{
					commuting_time<-min(1.35*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    				1.35*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed,
    				1.35*(living_place.location distance_to working_place.location)#m/car_speed);
				}
				distance_to_work<-1.35*(living_place.location distance_to working_place.location);
				if has_car
				{
					switch car_type
					{
						match "GAS"
						{
							tax_increase<-gas_tax_increment;
						}
						match "DIESEL"
						{
							tax_increase<-diesel_tax_increment;
						}
						match "ELECTRIC"
						{
							tax_increase<-electric_tax_increment;
						}
						default
						{
							tax_increase<-0;
						}
					}
				}
				
				shuffled_list_of_days<-shuffle(shuffled_list_of_days);
				
				days_for_car_usage<-[];

				//ppl.days_for_car_usage<-sort(ppl.days_for_car_usage);
				
				//TEST of order
				/*
				bool correct_order<-true;
				loop i from:0 to:ppl.nb_car_used-2
				{
					if ppl.nb_car_used=1
					{
						break;
					}
					else
					{
						correct_order<-correct_order and ppl.days_for_car_usage[i]<ppl.days_for_car_usage[i+1];
					}
				}
				if !correct_order
				{
					write(ppl.days_for_car_usage);
				}
				*/
				//END OF TEST of order
			}
		}
		population_growth<-round((nb_people*0.0097)/60);
	}
	
	reflex update_days when: "01:00:00" in(string(current_date)) and cycle>0
	{
		nb_days <- nb_days+1;
	}
	
	reflex relocate when: "01:00:00" in(string(current_date)) and cycle>0 //and day_of_week(current_date)=7
	{
		write("start");
		list<building> possible_locations <- residential_buildings where(each.ppl_inside<each.capacity);
		list<person> to_relocate<-[];
		loop ppl over: person
		{
			if ppl.wants_relocate and !ppl.relocation_attempted
			{
				to_relocate << ppl;
			}
			
			if length(to_relocate)>daily_relocations/REDUCTION
			{
				break;
			}
		}
		
		if length(to_relocate)=0
		{
			return;
		}
		
		write(length(to_relocate));
		
		//https://www.movu.ch/ratgeber/en/relocation-behavior-2021/
		loop i from: 0 to:min(daily_relocations/REDUCTION, length(to_relocate)-1)
		{
			total_relocations<-total_relocations+1;
			ask to_relocate[i]
			{
				relocation_attempted<-true;
				building tmp <- possible_locations closest_to(working_place);
				if tmp!=nil
				{
					living_place.ppl_inside<-living_place.ppl_inside-1;
					possible_locations << living_place;
					if tmp.ppl_inside = tmp.capacity-1
					{
						possible_locations>>tmp;
					}
					living_place <- tmp;
					living_place.ppl_inside<-living_place.ppl_inside+1;
					wants_relocate <- false;
					
					if 1.35*(living_place.location distance_to working_place.location)<5#km
					{
						commuting_time <- 0;
					}
					else if !has_car
					{
						commuting_time <- 1.35*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    					1.35*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed;
					}
					else
					{
						commuting_time<-min(1.35*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    					1.35*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed,
    					1.35*(living_place.location distance_to working_place.location)#m/car_speed);
					}
					
					tmp_transport_time <-0;
					tmp_car_time<-0;
					distance_to_work<-1.35*(living_place.location distance_to working_place.location);
					//days_for_car_usage<-[];
				}
			}
		}
		to_relocate<-[];
		write("end");
	}
	
	reflex update_taxes when: "01-01 00:00:00" in(string(current_date)) and cycle>0// and day_of_week(current_date)=7
	{
		happiness_reduction_per_car_use<-happiness_reduction_per_car_use+increase_happiness_reduction_per_car_use;
		
		loop ppl over: person
		{
			ppl.prev_car_used <- ppl.car_used;
			ppl.prev_car_not_used <- ppl.car_not_used;
			ppl.car_used <-0;
			ppl.car_not_used <-0;
			
			if emissions > 360000/REDUCTION and ppl.has_car
			{
				float tax_increment;
				switch ppl.car_type
				{
					match "GAS"
					{
						tax_increment <- gas_tax_increment;
					}
					match "DIESEL"
					{						
						tax_increment <- diesel_tax_increment;
					}
					match "ELECTRIC"
					{
						tax_increment <- electric_tax_increment;					
					}
				}
				ppl.tax<-ppl.tax+tax_increment;
			}
			
			
			shuffled_list_of_days<-shuffle(shuffled_list_of_days);
			ppl.days_for_car_usage<-[];
				loop i from:0 to:59
				{
					if shuffled_list_of_days index_of i < ppl.nb_car_used
					{
						ppl.days_for_car_usage<<i;
					}
				}
			ppl.nb_car_used<-0;
		}
		
		int c_passengers<-0;
		loop s over:stop
		{
			if "cartigny, village" in lower_case(s.name)
			{
				c_passengers<-c_passengers+s.boarding_passengers;
				s.boarding_passengers<-0;
			}
		}
		
		save [nb_people, total_electric, switched_to_electric, total_relocations, c_passengers] to: "electric.csv" format: csv rewrite:false;
		switched_to_electric<-0;
		
		
	}
	
	reflex relocation_reset when: "01-01 20:00:00" in(string(current_date)) //or "07-01 20:00:00" in(string(current_date))
	{
		loop ppl over: person
		{
			ppl.relocation_attempted <- false;
		}
	}
	
	reflex switch_to_electricR when: "01:00:00" in(string(current_date)) and cycle>0
	{
		//https://www.swisscommunity.org/en/news-media/swiss-review/article/electric-car-sales-are-booming-in-switzerland
		//https://www.bfs.admin.ch/bfs/en/home/statistics/mobility-transport/transport-infrastructure-vehicles/vehicles/road-vehicles-stock-level-motorisation.html#1652458516
		float to_ele<-(switch_to_electric/REDUCTION)*min(1,((emissions+1000*REDUCTION)/(600000/REDUCTION)));
		int switched<-0;
		loop p over:person
		{
			if (not("ELECTRIC" in p.car_type)) and switched<=to_ele-1
			{
				p.car_type<-"ELECTRIC";
				switched_to_electric<-switched_to_electric+1;
				total_switches<-total_switches+1;
				p.nb_car_used<-0;
				p.car_used<-0;
				total_electric<-total_electric+1;
				switched<-switched+1;
				p.tax_increase<-electric_tax_increment;
				p.tax<-0;
			}
		}
	}
	
	reflex reset_emissions when: "01:00:00" in(string(current_date)) and cycle>0
	{
		save [nb_people, total_time_to_work, emissions, walkers, bikers,TPG_users ,car_users, tax_sum] to: "save_data.csv" format: csv rewrite:false;
		write(emissions);
		emissions <-0;
		loop cell over: city_cells
		{
			cell.emissions_in_cell <- 0;
		}
		
		cars<-0;
		
		displaying_walking <- false;
     	displaying_biking <- false;
     	displaying_public_transporting <- false;  
     	displaying_car_riding <- false;
     	
     	walk_display_counter<-0;
     	bike_display_counter<-0;
     	TPG_display_counter<-0;
     	car_display_counter<-0;
     	
     	//switched_to_electric<-0;
     	
     	tax_sum<-0;
    	happiness_sum<-0;
    	
    	
    	total_time_to_work<-0;
    	walkers<-0;
    	bikers<-0;
    	TPG_users<-0;
    	car_users<-0;
	}
	
	reflex step_adjustment when: ("10:00:00" in(string(current_date))or"02:00:00" in(string(current_date))) and cycle>0
	{
		step <- 3#h;
	}
	
	reflex step_adjustment2 when: ("13:00:00" in(string(current_date))or"05:00:00" in(string(current_date))) and cycle>0
	{
		step <- original_step;
	}
}

species perim
{
	aspect base
	{
		draw shape color: #cyan;
	}
}

species building 
{
	string dest;
	string type; 
	int comm;
	int capacity;
	int ppl_inside;
	rgb color <- #red;
	stop closest_stop;
	path path_to_closest_stop;
	bool is_reference;
	
	aspect base 
	{
		draw shape color: color ;
	}
}

species stop
{
	rgb color <- #magenta;
	bool is_displayed;
	int boarding_passengers<-0;
	int disembarking_passengers<-0;
	aspect base
	{
		if is_displayed
		{
			draw square(100#m) color: color;	
		}
	}
}

species road  
{
	rgb color <- #black ;
	aspect base 
	{
		draw shape color: color ;
	}
}

species cyclo_road
{
	rgb color <- #yellow;
	aspect base
	{
		draw shape color: color;
	}
	
}

species ligne  
{
	string _line;
	rgb color <- #green ;
	aspect base 
	{
		if _line in(["11", "14","15","17","18", "21"])
		{
			draw shape color: color ;
		}
		
	}
}

species transport
{
	float emissions_produced;
}

species public_transport skills: [moving] parent: transport
{
	rgb color <- #purple;
	float emissions_produced;
	aspect base
	{
		draw triangle(20 #m) color: color;
	}
}

species tram skills:[moving]
{
	rgb color <- #red; 
	point target;
	int target_index;
	bool reversed;
	list<stop> my_stops;
	
	reflex update_target when: target = nil
	{
		target_index <- reversed?target_index-1:target_index+1;
			
		if target_index = length(my_stops) or target_index<0 //tram is on the terminus
		{
			reversed<-!reversed;
			target_index <- reversed?length(my_stops)-2:1;
		}
		
		stop next_stop;
		loop st over: my_stops
		{
			if (lower_case(st.name) = (tram18_stop_names2[target_index]))
			{
				next_stop <- st;
				break;
			}
		}
			
		target <- any_location_in(next_stop);
	}
	
	reflex move
	{
		do goto(target: target) on: ligneGr;
		if location=target
		{
			target<-nil;
		}
	}
	
	aspect base
	{
		if beautiful_display
		{
			draw circle(150#m) color: color;
		}
	}
}

species tram18 skills:[moving] parent:tram
{
	list<stop> my_stops;
}

species car skills: [moving] parent: transport
{
	rgb color <- #purple;
	float emissions_produced;
	aspect base
	{
		draw triangle(20 #m) color: color;
	}
}

species bike skills: [moving] parent: transport
{
	rgb color <- #purple;
	float emissions_produced;
	aspect base
	{
		draw triangle(20 #m) color: color;
	}
}

species person skills: [moving]
{
	rgb color <- #red;
	point target;
	building living_place;
	building working_place;
	bool is_student;
	
	int start_work ;
    int end_work  ;
    string objective ; 
    
    path path_car;
    path path_bike;
    path path_public;
    
    bool has_car;
    string car_type;
    
    string morning_choice;
    
    float happiness;
    float commuting_time;
    
    float tmp_transport_time<-0;
    float tmp_car_time<-0;
    float tmp_bike_time<-0;
    float tmp_walk_time<-0;
    
    float car_used;
    float car_not_used;
    float prev_car_used;
    float prev_car_not_used;
    int nb_car_used;
    int total_nb_car_used;
    list<int> days_for_car_usage;
    
    float tax;
    float tax_increase;
    float happines;
    
    bool wants_relocate;
    bool relocation_attempted;
    bool is_displayed<-false;
    
    bool goes_to_platform<-false;
    bool ready_for_TPG<-false;
    bool in_TPG<-false;
    bool goes_to_target<-false;
    point tmp_target<-nil;
    tram followed_tram<-nil;
    
    float distance_to_work;
    
    bool block_pass<-false;
	
	aspect default
	{
		draw circle(5 #m) color: color;
	}
	
	aspect not_breaking
	{
		if is_displayed
		{
			draw circle(100 #m) color: color;
		}
	}
	
	reflex time_to_work when: current_date.hour = start_work and objective = "resting" //and not(day_of_week(current_date) in([6,7])) 
    {
    	target <- any_location_in (working_place);
    	objective <- "working";
    }
    
    reflex time_to_go_home when: current_date.hour = end_work and objective = "working"
    {
    	target <- any_location_in (living_place);
    	objective <- "resting";
    }
    
    reflex move when: target != nil 
    {	
    	if morning_choice = nil
    	{
    		morning_choice <- choose_transport();
    		if morning_choice = "CAR"
    		{
    			car_used <- car_used+2*distance_to_work;
    		}
    		else
    		{
    			car_not_used <- car_not_used +1;
    		}
    	}
    	
    	switch morning_choice
    	{
    		match "WALK"
    		{
    			
    			if beautiful_display and !displaying_walking
    			{
    				displaying_walking <- true;
    				color <- #blue;
    				is_displayed <- true;
    			}
    			
    			if beautiful_display and walk_display_counter<10 and location distance_to target < 1#km
    			{
    				is_displayed <- true;
    				color <- #blue;
    				walk_display_counter<-walk_display_counter+1;
    			}
    			
    			if is_displayed
    			{
    				self.speed <- walk_speed;
    				do goto(target) on: roadGR;	
					if target = location 
					{
	    				target <- nil ;
					}
    			}
    			else
    			{
    				location <- target;
					target<-nil;
    			}				
    		}
    		match "BIKE"
    		{
    			
    			if beautiful_display and !displaying_biking
    			{
    				displaying_biking <- true;
    				color <- #yellow;
    				is_displayed <- true;
    			}
    			
    			if beautiful_display and bike_display_counter<10 and location distance_to target < 2#km
    			{
    				is_displayed <- true;
    				color <- #yellow;
    				bike_display_counter<-bike_display_counter+1;
    			}
    			
    			if is_displayed
    			{
    				self.speed <- bike_speed;
    				do goto(target) on: cycloGr;	
					if target = location 
					{
	    				target <- nil ;
					}
    			}
    			else
    			{
    				location <- target;
					target<-nil;
    			}				
    		}
    		match "PUBLIC_TRANSPORT"
    		{
    			if self.objective = "working" and "cartigny, village" in lower_case(working_place.closest_stop.name) and not block_pass
				{
					working_place.closest_stop.boarding_passengers<-working_place.closest_stop.boarding_passengers+1;
					block_pass<-true;
				}
				
				if self.objective = "working" and "cartigny, village" in lower_case(living_place.closest_stop.name) and not block_pass
				{
					living_place.closest_stop.boarding_passengers<-living_place.closest_stop.boarding_passengers+1;
					block_pass<-true;
				}
    			
    			if beautiful_display and !displaying_public_transporting
    			{
    				displaying_public_transporting <- true;
    				color <- #magenta;
    				is_displayed <- true;
    			}
    			
    			if beautiful_display and TPG_display_counter<10 and 
    			lower_case(working_place.closest_stop.name) in(tram18_stop_names2) and
    			lower_case(living_place.closest_stop.name) in(tram18_stop_names2) 
    			{
    				is_displayed <- true;
    				color <- #magenta;
    				TPG_display_counter<-TPG_display_counter+1;
    			}
    			
    			if is_displayed
    			{
    				self.speed <- walk_speed;
    				goes_to_platform<-true;
    				tmp_target<-any_location_in(living_place.closest_stop);
    				if self.objective = "working"
    				{
    					if goes_to_platform
    					{
    						do goto(tmp_target) on: roadGr;
    						if location=tmp_target
    						{
    							tmp_target<-nil;
    							goes_to_platform<-false;
    							ready_for_TPG<-true;
    						}
    					}
    					
    					if ready_for_TPG
    					{
    						loop tr over: tram18
    						{
    							if location distance_to tr.location <250#m and tr.reversed=(tram18_stop_names2 index_of lower_case(living_place.closest_stop.name)>tram18_stop_names2 index_of (lower_case(working_place.closest_stop.name)))
    							{
    								followed_tram<-tr;
    								ready_for_TPG<-false;
    								in_TPG<-true;
    								break;
    							}
    						}
    					}
    					
    					if in_TPG
    					{
    						location<-followed_tram.location;
    						if location distance_to working_place.closest_stop.location<250#m
    						{
    							location<-working_place.closest_stop.location;
    							in_TPG<-false;
    							goes_to_target<-true;
    							followed_tram<-nil;
    							break;
    						}
    					}
    					
    					if goes_to_target
    					{
    						do goto(target) on: roadGr;	
							if target = location 
							{
	    						target <- nil ;
	    						goes_to_target<-false;
							}						
						}
    				} 
    				else
    				{
    					//do goto(any_location_in(working_place.closest_stop)) on: roadGr;
    					//self.speed <- public_transport_speed;
  		  				//do goto(any_location_in(living_place.closest_stop)) on: lineGr;
    					//self.speed <- walk_speed;
    					//do goto(target) on: roadGr;	
    					//if target = location 
						//{
	    				//	target <- nil ;
						//}
						location <- target;
						target<-nil;
    				}
    			}
    			else
    			{
    				location <- target;
					target<-nil;
    			}    			    			
    		}
    		match "CAR"
    		{
    			if beautiful_display and !displaying_car_riding
    			{
    				displaying_car_riding <- true;
    				color <- #orange;
    				is_displayed <- true;
    			}
    			
    			if beautiful_display and car_display_counter<10 and location distance_to target < 5#km
    			{
    				is_displayed <- true;
    				color <- #orange;
    				car_display_counter<-car_display_counter+1;
    			}
    			
    			float dst <- 1.35*(self.location distance_to target);
    			float emission_update <- 0;
    			switch car_type
    			{
    				match "GAS"
    				{
    					emission_update <- dst*gasoline_emissions_rate;
    				}
    				match "DIESEL"
    				{
    					emission_update <- dst*diesel_emissions_rate;
    				}
    				match "ELECTRIC"
    				{
    					emission_update <- dst*electric_emissions_rate;
    				}
    				default
    				{
    					emission_update <- 0;
    				}
    			}
    			emissions <- emissions + emission_update; 			
    			
    			if is_displayed
    			{
    				//THIS WORKS
    			
    				self.speed <- car_speed;
    				list<city_cells> passed_cells <- [];
    				do goto(target) on: roadGr;	
    			
    				if !(city_cells(location) in(passed_cells))
    				{
    					passed_cells<<city_cells(location);
    				} 
    			
					if target = location 
					{
						if !(city_cells(location) in(passed_cells))
    					{
    						passed_cells<<city_cells(location);
    					} 
	    				target <- nil ;
	    				int len<- length(passed_cells);
	    				loop cell over: passed_cells
	    				{
	    					cell.emissions_in_cell <- cell.emissions_in_cell + (emission_update/len);
	    				}
	    				passed_cells <- [];
					}
				
				//END OF THIS WORKS
    			}
    			else
    			{
    				//TEST
    				location <- target;
					target<-nil;
					city_cells(location).emissions_in_cell<-city_cells(location).emissions_in_cell+emission_update;
    				//END OF TEST
    			}
    							
				/*
				path path_followed <- goto(target: target, on:roadGr, return_path: true);
				list<geometry> segments <- path_followed.segments;
				int len <- max(1, length(segments));
				loop line over: segments {
	    			ask city_cells(line.location) 
	    			{ 
						emissions_in_cell <- emissions_in_cell + (emission_update/len);
	    			}
				}
				if target = location {
	    			target <- nil ;
				}
				*/
    		}
    		default
    		{
    			write("HELP ME");
    		}
    	}    	
    }
    
    string choose_transport
    {
    	if morning_choice != nil
    	{
    		return morning_choice;
    	}
    	
    	if tmp_transport_time=0 or tmp_car_time=0 or tmp_bike_time = 0 or tmp_walk_time=0
    	{
    		tmp_transport_time <- 1.35*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    		1.35*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed;
    		tmp_car_time <-1.35*(living_place.location distance_to working_place.location)#m/car_speed;
    		tmp_bike_time<-1.35*(living_place.location distance_to working_place.location)#m/bike_speed;
    		tmp_walk_time<-1.35*(living_place.location distance_to working_place.location)#m/walk_speed;
    	}    	
    	
    	float ds<-distance_to_work;
    	float total_tax<-tax_function(true,ds);
    	float coef<-total_nb_car_used*happiness_reduction_per_car_use+total_tax/800;
    	
    	/*
    	if length(days_for_car_usage)<60 and not(mod(nb_days,60) in days_for_car_usage)
    	{
    		total_tax <- tax_depends_on_car_usage?(tax+tmp_taxIncrease)*(car_used+2*distance_to_work*(length(days_for_car_usage)+1)):tax;
    	}
    	else
    	{
    		total_tax <- tax_depends_on_car_usage?(tax+tmp_taxIncrease)*(car_used+2*distance_to_work):tax;
    	}
    	*     	*
    	*/
    	
    	
    	
    	if ds < 1000#m//and flip(0.8+min(0.15, total_tax/5))
    	{
    		morning_choice <-"WALK";
    		return "WALK";
    	}

    	
    	float f <- rnd(1.0);
    	
    	if ds < 2000#m +2*(coef-total_tax/800)#km
    	{
    		if f<0.72+min(0.03, total_tax/10000)
    		{
    			morning_choice <-"WALK";
    			return "WALK";
    		}
    		else if f <0.87+min(0.08, total_tax/5000)
    		{
    			morning_choice <-"BIKE";
    			return "BIKE";
    		}
    		else if !has_car or
    		((f<(0.87+min(0.1, (coef/3)))) and
    		tmp_transport_time < tmp_car_time + extra_time+min(0.25#h,(coef/2)#h)
    		and
    		living_place.location distance_to living_place.closest_stop.location<500#m and
    		working_place.location distance_to working_place.closest_stop.location<500#m)
    		{
    			morning_choice <-"PUBLIC_TRANSPORT";
    			return "PUBLIC_TRANSPORT";
    		}
    		else
    		{
    			nb_car_used<-nb_car_used+1;
    			total_nb_car_used<-total_nb_car_used+1;
    			cars <- cars+1;
    			morning_choice <-"CAR";
    			return "CAR";
    		}
    	}
    	
    	if ds < 3000#m +2*(coef-total_tax/800)#km
    	{
    		if f<0.42+min(0.035, total_tax/10000)
    		{
    			morning_choice <-"WALK";
    			return "WALK";
    		}
    		else if f <0.66+min(0.07, total_tax/5000)
    		{
    			morning_choice <-"BIKE";
    			return "BIKE";
    		}
    		else if !has_car or
    		((f<(0.85+min(0.1, (coef/3)))) and
    		tmp_transport_time < tmp_car_time + extra_time+min(0.25#h, (coef/2)#h) 
    		and
    		living_place.location distance_to living_place.closest_stop.location<500#m and
    		working_place.location distance_to working_place.closest_stop.location<500#m)
    		{
    			morning_choice <-"PUBLIC_TRANSPORT";
    			return "PUBLIC_TRANSPORT";
    		}
    		else
    		{
    			nb_car_used<-nb_car_used+1;
    			total_nb_car_used<-total_nb_car_used+1;
    			cars <- cars+1;
    			morning_choice <-"CAR";
    			return "CAR";
    		}
    	}
    	
    	if ds < 4000#m +2*(coef-total_tax/800)#km
    	{
    		if f<0.20+min(0.03, total_tax/10000)
    		{
    			morning_choice <-"WALK";
    			return "WALK";
    		}
    		else if f <0.35+min(0.06, total_tax/5000)
    		{
    			morning_choice <-"BIKE";
    			return "BIKE";
    		}
    		else if !has_car or
    		((f<(0.7+min(0.1, (coef/3)))) and
    		tmp_transport_time < tmp_car_time + extra_time+min(0.25#h, (coef/2)#h) 
    		and
    		living_place.location distance_to living_place.closest_stop.location<500#m and
    		working_place.location distance_to working_place.closest_stop.location<500#m)
    		{
    			morning_choice <-"PUBLIC_TRANSPORT";
    			return "PUBLIC_TRANSPORT";
    		}
    		else
    		{
    			nb_car_used<-nb_car_used+1;
    			total_nb_car_used<-total_nb_car_used+1;
    			cars <- cars+1;
    			morning_choice <-"CAR";
    			return "CAR";
    		}
    	}
    	
    	if ds < 5000#m +2*(coef-total_tax/800)#km
    	{
    		if f<0.19+min(0.04, total_tax/10000)
    		{
    			morning_choice <-"WALK";
    			return "WALK";
    		}
    		else if f <0.35+min(0.1, total_tax/5000)
    		{
    			morning_choice <-"BIKE";
    			return "BIKE";
    		}
    		else if !has_car or
    		((f<(0.7+min(0.1,(coef/3)))) and
    		tmp_transport_time < tmp_car_time + extra_time+min(0.25#h, (coef/2)#h) 
    		and
    		living_place.location distance_to living_place.closest_stop.location<500#m and
    		working_place.location distance_to working_place.closest_stop.location<500#m)
    		{
    			morning_choice <-"PUBLIC_TRANSPORT";
    			return "PUBLIC_TRANSPORT";
    		}
    		else
    		{
    			nb_car_used<-nb_car_used+1;
    			total_nb_car_used<-total_nb_car_used+1;
    			cars <- cars+1;
    			morning_choice <-"CAR";
    			return "CAR";
    		}
    	}
    	
    	if ds < 6000#m +2*(coef-total_tax/800)#km
    	{
    		if f<0.14+min(0.03, total_tax/10000)
    		{
    			morning_choice <-"WALK";
    			return "WALK";
    		}
    		else if f <0.28+min(0.07, total_tax/5000)
    		{
    			morning_choice <-"BIKE";
    			return "BIKE";
    		}
    		else if !has_car or
    		((f<(0.6+min(0.1,(coef/3)))) and
    		tmp_transport_time < tmp_car_time + extra_time+min(0.25#h, (coef/2)#h) 
    		and
    		living_place.location distance_to living_place.closest_stop.location<500#m and
    		working_place.location distance_to working_place.closest_stop.location<500#m)
    		{
    			morning_choice <-"PUBLIC_TRANSPORT";
    			return "PUBLIC_TRANSPORT";
    		}
    		else
    		{
    			nb_car_used<-nb_car_used+1;
    			total_nb_car_used<-total_nb_car_used+1;
    			cars <- cars+1;
    			morning_choice <-"CAR";
    			return "CAR";
    		}
    	}
    	
    	if ds < 8000#m +2*(coef-total_tax/800)#km
    	{
    		if f <0.2+min(0.03, total_tax/5000)
    		{
    			morning_choice <-"BIKE";
    			return "BIKE";
    		}
    		else if !has_car or
    		((f<(0.75+min(0.15, (coef/3)))) and
    		tmp_transport_time < tmp_car_time + extra_time+min(0.25#h, (coef/2)#h) 
    		and
    		living_place.location distance_to living_place.closest_stop.location<500#m and
    		working_place.location distance_to working_place.closest_stop.location<500#m)
    		{
    			morning_choice <-"PUBLIC_TRANSPORT";
    			return "PUBLIC_TRANSPORT";
    		}
    		else
    		{
    			nb_car_used<-nb_car_used+1;
    			total_nb_car_used<-total_nb_car_used+1;
    			cars <- cars+1;
    			morning_choice <-"CAR";
    			return "CAR";
    		}
    	}
    	
    	if ds < 10000#m +2*(coef-total_tax/800)#km
    	{
    		if f <0.1+min(0.07, total_tax/5000)
    		{
    			morning_choice <-"BIKE";
    			return "BIKE";
    		}
    		else if !has_car or
    		((f<(0.7+min(0.1, (coef/3)))) and
    		tmp_transport_time < tmp_car_time + extra_time+min(0.25#h,(coef/2)#h) 
    		and
    		living_place.location distance_to living_place.closest_stop.location<500#m and
    		working_place.location distance_to working_place.closest_stop.location<500#m)
    		{
    			morning_choice <-"PUBLIC_TRANSPORT";
    			return "PUBLIC_TRANSPORT";
    		}
    		else
    		{
    			nb_car_used<-nb_car_used+1;
    			total_nb_car_used<-total_nb_car_used+1;
    			cars <- cars+1;
    			morning_choice <-"CAR";
    			return "CAR";
    		}
    	}
    	
    	if ds < 15000#m +2*(coef-total_tax/800)#km
    	{
    		if f <0.07+min(0.02, total_tax/5000)
    		{
    			morning_choice <-"BIKE";
    			return "BIKE";
    		}
    		else if !has_car or
    		((f<(0.5+min(0.15, (coef/3)))) and
    		tmp_transport_time < tmp_car_time + extra_time+min(0.25#h, (coef/2)#h) 
    		and
    		living_place.location distance_to living_place.closest_stop.location<500#m and
    		working_place.location distance_to working_place.closest_stop.location<500#m)
    		{
    			morning_choice <-"PUBLIC_TRANSPORT";
    			return "PUBLIC_TRANSPORT";
    		}
    		else
    		{
    			nb_car_used<-nb_car_used+1;
    			total_nb_car_used<-total_nb_car_used+1;
    			cars <- cars+1;
    			morning_choice <-"CAR";
    			return "CAR";
    		}
    	}
    	
    	if ds < 20000#m +2*(coef-total_tax/800)#km
    	{
    		if f <0.01+min(0.02, total_tax/5000)
    		{
    			morning_choice <-"BIKE";
    			return "BIKE";
    		}
    		else if !has_car or
    		((f<(0.5+min(0.1,(coef/3)))) and
    		tmp_transport_time < tmp_car_time + extra_time+min(0.25#h, (coef/2)#h) 
    		and
    		living_place.location distance_to living_place.closest_stop.location<500#m and
    		working_place.location distance_to working_place.closest_stop.location<500#m)
    		{
    			morning_choice <-"PUBLIC_TRANSPORT";
    			return "PUBLIC_TRANSPORT";
    		}
    		else
    		{
    			nb_car_used<-nb_car_used+1;
    			total_nb_car_used<-total_nb_car_used+1;
    			cars <- cars+1;
    			morning_choice <-"CAR";
    			return "CAR";
    		}
    	}
    	
    	if f <0.01+min(0.02, total_tax/5000)
   		{
   			morning_choice <-"BIKE";
   			return "BIKE";
    	}
   		else if !has_car or
    	((flip(0.5+min(0.45, (coef/3)))) and
    	tmp_transport_time < tmp_car_time + extra_time+min(0.25#h, (coef/2)#h) 
    	and
    	living_place.location distance_to living_place.closest_stop.location<500#m and
    	working_place.location distance_to working_place.closest_stop.location<500#m)
    	{
    		morning_choice <-"PUBLIC_TRANSPORT";
    		return "PUBLIC_TRANSPORT";
    	}
    	
    	nb_car_used<-nb_car_used+1;
    	total_nb_car_used<-total_nb_car_used+1;
    	cars <- cars+1;
    	morning_choice <-"CAR";
    	return "CAR";
    }
    
    reflex stats_update when: "22:00:00" in(string(current_date))
    {
    	float total_tax <- tax_function(false,0);
    	tax_sum<-tax_sum+total_tax;
    	float happiness_diminish <- commuting_time > 30#mn or
    	(tmp_transport_time>20#mn
    	and total_tax > tax_impact_on_relocation)? 0.5:0;
    	happiness <- 1-happiness_diminish-min(total_tax/200, 0.5);
    	happiness <- (prev_car_used=0 and happiness_diminish=0)?min(1,happiness+0.5):happiness;
    	//happiness<-calculate_new_happiness();
    	happiness_sum<-happiness_sum+happiness;
    	wants_relocate <- happiness<=0.5;
    	
    	switch morning_choice
    	{
    		match "CAR"
    		{
    			total_time_to_work<-total_time_to_work+tmp_car_time;
    		}
    		match "PUBLIC_TRANSPORT"
    		{
    			total_time_to_work<-total_time_to_work+tmp_transport_time;
    		}
    		match "BIKE"
    		{
    			total_time_to_work<-total_time_to_work+tmp_bike_time;
    		}
    		match "WALK"
    		{
    			total_time_to_work<-total_time_to_work+tmp_walk_time;
    		}
    	}
    	
    	
    	switch morning_choice
    	{
    		match "CAR"
    		{
    			car_users<-car_users+1;
    		}
    		match "PUBLIC_TRANSPORT"
    		{
    			TPG_users<-TPG_users+1;
    		}
    		match "BIKE"
    		{
    			bikers<-bikers+1;
    		}
    		match "WALK"
    		{
    			walkers<-walkers+1;
    		}
    		default
    		{

    		}
    	}
    	
    	morning_choice<-nil;
    	is_displayed <- false;
    	block_pass<-false;
		//happiness<-1.0;	
		
		/*
		if mod(nb_days,60) in days_for_car_usage
		{
			days_for_car_usage>>mod(nb_days,60);
		}
		*/
    }
    
    float calculate_coefficient
    {
    	float new_happiness<-max(0, 1-total_nb_car_used*happiness_reduction_per_car_use-tax_function(false,0));
    	return new_happiness;
    }
    
    float tax_function (bool for_transport_choice, float distance)
    {
    	if environment_without_tax
    	{
    		return 0;
    	}
    	
    	if not(tax_depends_on_car_usage)
    	{
    		return 50*tax;
    	}
    	
    	if for_transport_choice //how much the person will be paying next year if he choses to use car
    	{
    		int len<-length(days_for_car_usage);
    		if len=0
    		{
    			return (car_used+2*distance)*(tax+tax_increase);
    		}
    		else
    		{
    			//DEMONSTRATION PURPOSES ONLY
    			//return (car_used+2*distance)*(tax+tax_increase);
    			
    			if mod(nb_days, 60)=days_for_car_usage[0]
    			{
    				days_for_car_usage>>days_for_car_usage[0];
    				return (car_used+2*distance)*(tax+tax_increase);
    			}
    			else
    			{
    				return (car_used+2*distance*len)*(tax+tax_increase);
    			}
    		}
    	}
    	else
    	{
    		return prev_car_used*tax;//how much a person is paying this year
    	}
    }
}

grid city_cells neighbors: 4 cell_height: 1000 #m cell_width: 1000 #m
{
	int work_places <- 0;
	building reference_building <- nil;
	map<city_cells,path> paths <- [];
	float emissions_in_cell <- 0;
	rgb color <- rgb(255, 255*max([(1000#kg-emissions_in_cell)/1000#kg,0]),255*max([(1000#kg-emissions_in_cell)/1000#kg,0]))
	update: rgb(255, 255*max([(1000#kg-emissions_in_cell)/1000#kg,0]),255*max([(1000#kg-emissions_in_cell)/1000#kg,0]));
}

experiment gen_traffic type: gui 
{
	parameter "Small model" var: small_model category: "Model";
	parameter "Granulation" var: REDUCTION min:1 max:100 category: "Model";
	parameter "Beautiful display" var: beautiful_display category: "Model";
	parameter "Daily relocations (full city)" var: daily_relocations min: 0 max: 1000 category: "Model";
	parameter "Daily population growth (full city)" var: population_growth min: 0 max: 1000 category: "Model";
	parameter "Daily switch to electric (full city)" var: switch_to_electric min: 0 max: 500 category: "Model";
	
	parameter "Tax depends on car usage" var: tax_depends_on_car_usage category: "Taxes";
	parameter "Environment without tax" var: environment_without_tax category: "Taxes";
	parameter "Starting tax" var: beginning_tax min:0 max: 0.00005 category: "Taxes";
	parameter "Tax increment for gas cars" var: gas_tax_increment min:0 max: 0.00005 category: "Taxes";
	parameter "Tax increment for diesel cars" var: diesel_tax_increment min:0 max: 0.00005 category: "Taxes";
	parameter "Tax increment for electric cars" var: electric_tax_increment min:0 max: 0.00005 category: "Taxes";
	parameter "Tax impact on relocations (400 - almost no impact, 1 - huge impact)" var: tax_impact_on_relocation min:1 max: 400 category: "Taxes";
	
	parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
	parameter "Shapefile for the lines:" var: shape_file_roads category: "GIS" ;
	parameter "Shapefile for the stops:" var: shape_file_roads category: "GIS" ;
	parameter "Shapefile for the cycloroads:" var: shape_file_roads category: "GIS" ;
	
	parameter "Car speed" var: car_speed min: 30#km/#h max:90#km/#h category: "Transport";
	parameter "TPG speed" var: public_transport_speed min: 30#km/#h max:90#km/#h category: "Transport";
	parameter "Bike speed" var: bike_speed min: 10#km/#h max:50#km/#h category:  "Transport";
	parameter "Walk speed" var: walk_speed min: 1#km/#h max:10#km/#h category: "Transport";
	
	parameter "Minimal work start"var: min_work_start min:4 max:8 category: "Work";
	parameter "Maximal work start"var: min_work_start min:8 max:11 category: "Work";
	parameter "Minimal work end"var: min_work_start min:12 max:16 category: "Work";
	parameter "Maximal work end"var: min_work_start min:16 max:20 category: "Work";
	
	parameter "Gasoline cars emission rate" var: gasoline_emissions_rate  min: 0.1#kg/#km max:0.3#kg/#km category: "Emission";
	parameter "Diesel cars emission rate" var: diesel_emissions_rate  min: 0.1#kg/#km max:0.3#kg/#km category: "Emission";
	parameter "Electric cars emission rate" var: electric_emissions_rate  min: 0#kg/#km max:0.1#kg/#km category:  "Emission";
		
	output {
		display city_display type:3d antialias: true
		{
			grid city_cells lines: #black;
			//species perim aspect: base;
			//species building aspect: base;
			species road aspect: base;
			species ligne aspect: base;
			species stop aspect: base;
			species tram18 aspect:base;
			species person aspect: not_breaking;			
		}
		monitor "Number of cars" value: cars;
		monitor "Day: " value: nb_days;
		monitor "Number of people " value: nb_people;
		monitor "Switched to electric " value: total_switches;
		
		display chart_display refresh: "23:00:00" in string(current_date) 
		{
             chart "Tax" type: series size: {0.5, 0.25} position: {0, 0} 
             {
                data "Average Tax" value: tax_sum/nb_people style: line color: #red ;
	     	 }
	     	 
	     	 chart "Average Time to Work" type: series size: {0.5, 0.25} position: {0.5, 0} 
             {              
	         	data "Average Time to Work" value: total_time_to_work/nb_people style: line color: #blue ;	         	
	     	 }
	     	 
	     	 chart "Electric cars" type: series size: {0.5, 0.25} position: {0, 0.25} 
             {
	         	data "Electric cars" value: total_electric/nb_people style: line color: #green ;
	     	 }
	     	 
	     	 chart "Emissions" type: series size: {0.5, 0.25} position: {0.5, 0.25} 
             {
	         	data "Emissions" value: emissions style: line color: #black ;
	     	 }
	     	
	     	chart "types of commuting" type: series size: {1, 0.5} position: {0, 0.5}
	     	{
	       		data "Car" value: car_users style:line color: #red ;
	       		data "TPG" value: TPG_users style:line color: #magenta ;
	       		data "Bike" value: bikers style:line color: #yellow ;
	       		data "Walk" value: walkers style:line color: #blue ;
	  		}
		}
	}
}

experiment exploration type: batch repeat: 1 keep_seed: true until: ( "2035-07-01 00:00:00" in string(current_date) ) {
	parameter "Batch mode:" var: is_batch<-true;
	method exploration with: [
		["gas_tax_increment"::0.001/#km,
		"diesel_tax_increment"::0.0012/#km],
		["gas_tax_increment"::0.002/#km,
		"diesel_tax_increment"::0.0024/#km],
		["gas_tax_increment"::0.003/#km,
		"diesel_tax_increment"::0.0036/#km],
		["gas_tax_increment"::0.004/#km,
		"diesel_tax_increment"::0.0048/#km],
		["gas_tax_increment"::0.005/#km,
		"diesel_tax_increment"::0.006/#km],
		["gas_tax_increment"::0.006/#km,
		"diesel_tax_increment"::0.0072/#km],
		["gas_tax_increment"::0.007/#km,
		"diesel_tax_increment"::0.0084/#km],
		["gas_tax_increment"::0.008/#km,
		"diesel_tax_increment"::0.0096/#km],
		["gas_tax_increment"::0.009/#km,
		"diesel_tax_increment"::0.0108/#km],
		["gas_tax_increment"::0.01/#km,
		"diesel_tax_increment"::0.012/#km],
		["gas_tax_increment"::0.02/#km,
		"diesel_tax_increment"::0.024/#km],
		["gas_tax_increment"::0.03/#km,
		"diesel_tax_increment"::0.036/#km],
		["gas_tax_increment"::0.04/#km,
		"diesel_tax_increment"::0.048/#km],
		["gas_tax_increment"::0.05/#km,
		"diesel_tax_increment"::0.06/#km],
		["gas_tax_increment"::0.06/#km,
		"diesel_tax_increment"::0.072/#km],
		["gas_tax_increment"::0.07/#km,
		"diesel_tax_increment"::0.084/#km],
		["gas_tax_increment"::0.08/#km,
		"diesel_tax_increment"::0.096/#km],
		["gas_tax_increment"::0.09/#km,
		"diesel_tax_increment"::0.108/#km],
		["gas_tax_increment"::0.1/#km,
		"diesel_tax_increment"::0.12/#km],
		["gas_tax_increment"::0.2/#km,
		"diesel_tax_increment"::0.24/#km],
		["gas_tax_increment"::0.3/#km,
		"diesel_tax_increment"::0.36/#km],
		["gas_tax_increment"::0.4/#km,
		"diesel_tax_increment"::0.48/#km],
		["gas_tax_increment"::0.5/#km,
		"diesel_tax_increment"::0.6/#km],
		["gas_tax_increment"::0.6/#km,
		"diesel_tax_increment"::0.72/#km],
		["gas_tax_increment"::0.7/#km,
		"diesel_tax_increment"::0.84/#km],
		["gas_tax_increment"::0.8/#km,
		"diesel_tax_increment"::0.96/#km],
		["gas_tax_increment"::0.9/#km,
		"diesel_tax_increment"::1.08/#km],
		["gas_tax_increment"::1/#km,
		"diesel_tax_increment"::1.2/#km],
		["gas_tax_increment"::2/#km,
		"diesel_tax_increment"::2.4/#km],
		["gas_tax_increment"::3/#km,
		"diesel_tax_increment"::3.6/#km],
		["gas_tax_increment"::4/#km,
		"diesel_tax_increment"::4.8/#km],
		["gas_tax_increment"::5/#km,
		"diesel_tax_increment"::6/#km],
		["gas_tax_increment"::6/#km,
		"diesel_tax_increment"::7.2/#km],
		["gas_tax_increment"::7/#km,
		"diesel_tax_increment"::8.4/#km],
		["gas_tax_increment"::8/#km,
		"diesel_tax_increment"::9.6/#km],
		["gas_tax_increment"::9/#km,
		"diesel_tax_increment"::10.8/#km],
		["gas_tax_increment"::10/#km,
		"diesel_tax_increment"::12/#km]];
		
    reflex save_results_explo {
		ask simulations {
			save [int(self),gas_tax_increment,diesel_tax_increment,self.emissions,self.tax_sum,self.total_switches] 
		   		to: "results.csv" format:"csv" rewrite: (int(self) = 0) ? true : false header: true;
		}		
	}
}

/* Insert your model definition here */


/* Insert your model definition here */

