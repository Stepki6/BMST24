/**
* Name: NewModel
* Based on the internal empty template. 
* Author: stepi
* Tags: 
*/


model NewModel

global 
{
	bool small_model<-true;
	bool tax_depends_on_car_usage <- true;
	int REDUCTION <- small_model? 6:1;
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
	
	int PAV_work<-0;
	int PAV_housing<-0;
	
	list<building> residential_buildings;
	list<building> industrial_buildings;
	list<building> education_buildings;
	list<building> entertainment_buildings;
	
	int housingCap <- 0;
	int workingCap <- 0;
	
	date starting_date <- date("2024-02-19 05:00:00");
	int public_transport_speed <- 30 #km/#h;
	int car_speed <- 50 #km/#h;
	int bike_speed <- 15 #km/#h;
	int walk_speed <- 4 #km/#h;
	
	float public_transport_emissions <- 0;
	float car_emissions <- 0.01;
	float bike_emissions <- 0;
	
	int min_work_start <- 6;
    int max_work_start <- 9;
    int min_work_end <- 14; 
    int max_work_end <- 18; 
    float min_speed <- 30 #km / #h;
    float max_speed <- 50 #km / #h; 
    
    //https://8billiontrees.com/carbon-offsets-credits/how-much-co2-does-a-car-emit-per-mile/
    float gasoline_emissions_rate <- 0.192 #kg/#km;
    float diesel_emissions_rate <- 0.171 #kg/#km;
    float electric_emissions_rate <- 0.053 #kg/#km;
    
    //https://www.bfs.admin.ch/bfs/en/home/statistics/regional-statistics/regional-portraits-key-figures/cantons/geneva.html
    float has_car_probability <- 1.0; //0.44 is per 1000 people but kids dont drive. I only work with adults 18-65. SCREW IT anybody can use a car.
    
    int cars <-0;
    int nb_days<-0;
    
    float extra_time <- 0.25#h;
    
    bool displaying_walking <- false;
    bool displaying_biking <- false;
    bool displaying_public_transporting <- false;  
    bool displaying_car_riding <- false;
    
    float tax_sum<-0;
    float happiness_sum<-0;
    float total_time_to_work<-0;
    float walkers<-0;
    float bikers<-0;
    float TPG_users<-0;
    float car_users<-0;
    
    int nb_people->{length(person)};
    int displayCounter<-0;
	
	init 
	{
		create perim from: shape_file_perimeter;
		create ligne from: shape_file_lignes with: [_line::string(read("LIGNE"))];
		ligneGr <- as_edge_graph(ligne);
		
		create stop from: shape_file_stops with: [nom::string(read ("NOM_ARRET"))];
		
		create cyclo_road from: shape_file_cyclo;
		cycloGr <- as_edge_graph(cyclo_road);
		
		create road from: shape_file_roads ;
		roadGr <- as_edge_graph(road);
		
		create building from: shape_file_buildings with: [dest::string(read ("DESTINAT")), comm::int(read("NO_COMM"))]
		{
			ppl_inside <- 0;
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
				//reference_buildings << bb;
			}
			
			if "Foyer " in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- 700;
				housingCap <- housingCap+700;
			}
			else if "Hab. - rez" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- 2;
				housingCap <- housingCap+2;
			}
			else if "Hab. deux" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- 4;
				housingCap <- housingCap+4;
			}
			else if "Habitation - activ" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- 5;
				housingCap <- housingCap+5;
			}
			else if "Habitation un" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- 2;
				housingCap <- housingCap+2;
			}
			else if "Hab plus" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- 29;
				housingCap <- housingCap+29;
			}
			else if "Internat" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- 700;
				housingCap <- housingCap+700;
			} 
			else if "Résidence" in (bb.dest)
			{
				bb.type <- "RESIDENTIAL";
				bb.capacity <- 2;
				housingCap <- housingCap+2;
			}  
			else if "Administration" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 600/2;
				workingCap <- workingCap+600/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 300;
			}  
			else if "Arsenal" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 1000/2;
				workingCap <- workingCap+1000/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 500;
			}  
			else if "Atelier" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 60/2;
				workingCap <- workingCap+60/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 50;
			}  
			else if "Bureaux" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 200;
				workingCap <- workingCap+200;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 300;
			}  
			else if "Central" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 30/2;
				workingCap <- workingCap+30/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 15;
			}  
			else if "Centre c" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 300/2;
				workingCap <- workingCap+300/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 150;
			}  
			else if "Centre d" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 50/2;
				workingCap <- workingCap+50/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 25;
			}  
			else if "Centre s" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 20/2;
				workingCap <- workingCap+20/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 10;
			}  
			else if "Cinéma" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 20/2;
				workingCap <- workingCap+20/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 10;
			}  
			else if "Consultat" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 10/2;
				workingCap <- workingCap+10/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 15;
			}  
			else if "Ecole" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 50/2;
				workingCap <- workingCap+50/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 25;
			}  
			else if "Hôpi" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 200/2;
				workingCap <- workingCap+200/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 200;
			}  
			else if "Mairie" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 40/2;
				workingCap <- workingCap+40/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 25;
			}  
			else if "Man" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 2/2;
				workingCap <- workingCap+2/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 1;
			}  
			else if "Mus" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 30/2;
				workingCap <- workingCap+30/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 25;
			}  
			else if "ONU" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 20/2;
				workingCap <- workingCap+20/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 10;
			}  
			else if "Ouvrage" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 2/2;
				workingCap <- workingCap+2/2;
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
				bb.capacity <- 20/2;
				workingCap <- workingCap+20/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 10;
			}  
			else if "Police" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 200;
				workingCap <- workingCap+200;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 350;
			}  
			else if "Porcherie" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 4/2;
				workingCap <- workingCap+4/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 2;
			}  
			else if "Poste" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 40/2;
				workingCap <- workingCap+40/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 50;
			}  
			else if "Restaurant" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 10/2;
				workingCap <- workingCap+10/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 5;
			}  
			else if "feu" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 50/2;
				workingCap <- workingCap+50/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 25;
			}  
			else if "Station" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 5/2;
				workingCap <- workingCap+5/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 2;
			}  
			else if "Sécurité" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 10/2;
				workingCap <- workingCap+10/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 5;
			}  
			else if "Thé" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 30/2;
				workingCap <- workingCap+30/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 15;
			}  
			else if "Usine" in (bb.dest)
			{
				bb.type <- "INDUSTRIAL";
				bb.capacity <- 30/2;
				workingCap <- workingCap+30/2;
				city_cells(bb.location).work_places <- city_cells(bb.location).work_places + 15;
			}  
			else if "Univ" in (bb.dest)
			{
				bb.type <- "EDUCATION";
				bb.capacity <- 10000;
			}  
			else if "CONSERVA" in (bb.dest)
			{
				bb.type <- "EDUCATION";
				bb.capacity <- 500;
			}  
			else if "Coll" in (bb.dest)
			{
				bb.type <- "EDUCATION";
				bb.capacity <- 300;
			}  
			else
			{
				bb.type <- "ENTERTAINMENT";
				bb.capacity <- -1;
			}
		}
		
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
		
		
		write("Housing"+housingCap);
		write("Work"+workingCap);
		
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
		*/
		
		write(PAV_housing);
		write(PAV_work);
		
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
		
		create person number: min(housingCap,workingCap)-1000
		{
			target <- nil;
			living_place <- residential_buildings[living_index];
			living_place.ppl_inside <- living_place.ppl_inside+1;
			if living_place.ppl_inside>=living_place.capacity
			{
				living_index<-living_index+1;
			}
			
			if "Foyer" in (living_place.dest) or "Internat" in (living_place.dest)
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
				else if tmp <0.9
				{
					car_type <- "DIESEL";
				}
				else
				{
					car_type <- "ELECTRIC";
				}
			}
			else
			{
				car_type <- nil;
			}
			
			morning_choice <- nil;
			
			happiness <- 1.0;
			tax<-0;
			wants_relocate<-false;
			relocation_attempted<-false;
			
			car_used <-0;
			car_not_used <-0;
			prev_car_used <-0;
			prev_car_not_used <-0;
			
			if living_place.location distance_to working_place.location<5#km
			{
				commuting_time <- 0;
			}
			else if !has_car
			{
				commuting_time <- 1.4*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    			1.4*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed;
			}
			else
			{
				commuting_time<-min(1.4*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    			1.4*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed,
    			1.4*(living_place.location distance_to working_place.location)#m/car_speed);
			}
		}
		
		
		
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
		write("Done");		
	}
	
	reflex writedate
	{
		write(current_date);
	}
	
	reflex writeEmissions when: mod(cycle,12) = 0 and cycle > 0
	{
		write(emissions);
	}
	
	reflex expand_population when: "21:00:00" in(string(current_date))
	{
		list<city_cells>cls <- [525,526,552,553];
		loop i from: 0 to: 51
		{
			create person
			{
				target <- nil;
				living_place <- city_cells(cls[mod(i,4)]).reference_building;
				living_place.capacity<-living_place.capacity+1;
				living_place.ppl_inside<-living_place.ppl_inside+1;
			
				working_place <- city_cells([445,446,472,473,474,499,500,501][mod(i,8)]).reference_building;
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
					else if tmp <0.9
					{
						car_type <- "DIESEL";
					}
					else
					{
						car_type <- "ELECTRIC";
					}
				}
				else
				{
					car_type <- nil;
				}
			
				morning_choice <- nil;
			
				happiness <- 1.0;
				tax<-person[i].tax;
				wants_relocate<-false;
				relocation_attempted<-false;
			
				car_used <-0;
				car_not_used <-0;
				prev_car_used <-0;
				prev_car_not_used <-0;
			
				if living_place.location distance_to working_place.location<5#km
				{
					commuting_time <- 0;
				}
				else if !has_car
				{
					commuting_time <- 1.4*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    				1.4*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed;
				}
				else
				{
					commuting_time<-min(1.4*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    				1.4*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed,
    				1.4*(living_place.location distance_to working_place.location)#m/car_speed);
				}
			}
		}
	}
	
	reflex update_days when: "00:00:00" in(string(current_date)) and cycle>0
	{
		nb_days <- nb_days+1;
	}
	
	reflex relocate when: "00:00:00" in(string(current_date)) and cycle>0 //and day_of_week(current_date)=7
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
			
			if length(to_relocate)>3000
			{
				break;
			}
		}
		
		if length(to_relocate)=0
		{
			return;
		}
		
		//https://www.movu.ch/ratgeber/en/relocation-behavior-2021/
		loop i from: 0 to:min(3000, length(to_relocate)-1)
		{
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
					
					if living_place.location distance_to working_place.location<5#km
					{
						commuting_time <- 0;
					}
					else if !has_car
					{
						commuting_time <- 1.4*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    					1.4*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed;
					}
					else
					{
						commuting_time<-min(1.4*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    					1.4*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed,
    					1.4*(living_place.location distance_to working_place.location)#m/car_speed);
					}
					
					tmp_transport_time <-0;
					tmp_car_time<-0;
				}
			}
		}
		write("end");
	}
	
	reflex reset when: "00:00:00" in(string(current_date)) and cycle>0 and day_of_week(current_date)=7
	{
		loop ppl over: person
		{
			ppl.prev_car_used <- ppl.car_used;
			ppl.prev_car_not_used <- ppl.car_not_used;
			ppl.car_used <-0;
			ppl.car_not_used <-0;
		}
	}
	
	reflex relocation_reset when: "01 20:00:00" in(string(current_date)) //or "07-01 20:00:00" in(string(current_date))
	{
		loop ppl over: person
		{
			ppl.relocation_attempted <- false;
		}
	}
	
	reflex reset_emissions when: "00:00:00" in(string(current_date)) and cycle>0
	{
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
	
	aspect base 
	{
		draw shape color: color ;
	}
}

species stop
{
	rgb color <- #magenta;
	string nom;
	aspect base
	{
		if true
		{
			draw square(150#m) color: color;	
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
    
    int car_used;
    int car_not_used;
    int prev_car_used;
    int prev_car_not_used;
    
    float tax;
    float happines;
    
    bool wants_relocate;
    bool relocation_attempted;
    bool is_displayed<-false;
	
	aspect default
	{
		draw circle(5 #m) color: color;
	}
	
	aspect not_breaking
	{
		if is_displayed
		{
			draw circle(150 #m) color: color;
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
    			car_used <- car_used+1;
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
    			/*
    			if !displaying_walking
    			{
    				displaying_walking <- true;
    				color <- #blue;
    				is_displayed <- true;
    			}
    			
    			self.speed <- walk_speed;
    			do goto(target) on: roadGR;	
				if target = location 
				{
	    			target <- nil ;
				}
				*/
				location <- target;
				target<-nil;
    		}
    		match "BIKE"
    		{
    			/*
    			if !displaying_biking
    			{
    				displaying_biking <- true;
    				color <- #yellow;
    				is_displayed <- true;
    			}
    			
    			self.speed <- bike_speed;
    			do goto(target) on: cycloGr;	
				if target = location 
				{
	    			target <- nil ;
				}
				*/
				location <- target;
				target<-nil;
    		}
    		match "PUBLIC_TRANSPORT"
    		{
    			/*
    			if !displaying_public_transporting
    			{
    				displaying_public_transporting <- true;
    				color <- #magenta;
    				is_displayed <- true;
    			}
    			
    			
    			self.speed <- walk_speed;
    			if self.objective = "working"
    			{
    				do goto(any_location_in(living_place.closest_stop)) on: roadGr;
    				self.speed <- public_transport_speed;
    				do goto(any_location_in(working_place.closest_stop)) on: lineGr;
    				self.speed <- walk_speed;
    				do goto(target) on: roadGr;	
					if target = location 
					{
	    				target <- nil ;
					}
    			} 
    			else
    			{
    				do goto(any_location_in(working_place.closest_stop)) on: roadGr;
    				self.speed <- public_transport_speed;
    				do goto(any_location_in(living_place.closest_stop)) on: lineGr;
    				self.speed <- walk_speed;
    				do goto(target) on: roadGr;	
    				if target = location 
					{
	    				target <- nil ;
					}
    			}
    			*/
    			location <- target;
				target<-nil;
    			    			
    		}
    		match "CAR"
    		{
    			if !displaying_car_riding
    			{
    				displaying_car_riding <- true;
    				color <- #orange;
    				is_displayed <- true;
    			}
    			
    			float dst <- 1.4*(self.location distance_to target);
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
    			
    			//TEST
    			location <- target;
				target<-nil;
				city_cells(location).emissions_in_cell<-city_cells(location).emissions_in_cell+emission_update;
    			//END OF TEST
    			
    			//THIS WORKS
    			/*
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
				*/
				//END OF THIS WORKS
				
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
    		tmp_transport_time <- 1.4*(living_place.location distance_to living_place.closest_stop.location + working_place.location distance_to working_place.closest_stop.location)#m/walk_speed +
    		1.4*(living_place.closest_stop.location distance_to working_place.closest_stop.location)#m/public_transport_speed;
    		tmp_car_time <-1.4*(living_place.location distance_to working_place.location)#m/car_speed;
    		tmp_bike_time<-1.4*(living_place.location distance_to working_place.location)#m/bike_speed;
    		tmp_walk_time<-1.4*(living_place.location distance_to working_place.location)#m/walk_speed;
    	}    	
    	
    	if target distance_to location < min(2000,500+100*tax)#m and flip(0.5+min(0.4, tax/50))
    	{
    		morning_choice <-"WALK";
    		return "WALK";
    	}
    	
    	if target distance_to location < min(10, 2+5*tax)#km and flip(0.2+min(0.7, tax/50))
    	{
    		morning_choice <-"BIKE";
    		return "BIKE";
    	}
    	
    	if !has_car or
    	(flip(0.5+min(0.4, tax/50)) and
    	tmp_transport_time < tmp_car_time + extra_time+min(0.4#h, 0.05#h*10*tax))
    	{
    		morning_choice <-"PUBLIC_TRANSPORT";
    		return "PUBLIC_TRANSPORT";
    	}
    	
    	cars <- cars+1;
    	morning_choice <-"CAR";
    	return "CAR";
    }
    
    reflex stats_update when: "22:00:00" in(string(current_date))
    {
    	float total_tax <- tax_depends_on_car_usage?tax*prev_car_used:tax;
    	tax_sum<-tax_sum+total_tax;
    	float happiness_diminish <- commuting_time > 30#mn or
    	(tmp_transport_time>45#mn
    	and total_tax > 2)? 0.5:0;
    	happiness <- 1-happiness_diminish-min(total_tax/20, 0.5);
    	happiness <- (prev_car_used=0 and happiness_diminish=0)?min(1,happiness+0.5):happiness;
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
    	
    	if emissions > 70000/REDUCTION and has_car
		{
			float tax_increment;
			switch car_type
			{
				match "GAS"
				{
					tax_increment <- 0.16;
				}
				match "DIESEL"
				{						
					tax_increment <- 0.2;
				}
				match "ELECTRIC"
				{
					tax_increment <- 0.02;					
				}
			}
			tax<-tax+tax_increment;
		}
		happiness<-1.0;	
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
	parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
		
	output {
		display city_display type:3d antialias: true
		{
			grid city_cells lines: #black;
			//species perim aspect: base;
			//species building aspect: base;
			species road aspect: base;
			species ligne aspect: base;
			//species stop aspect: base;
			species person aspect: not_breaking;
		}
		monitor "Number of cars" value: cars;
		monitor "Day: " value: nb_days;
		monitor "Number of people " value: nb_people;
		
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
	     	 
	     	 chart "Average Happiness" type: series size: {0.5, 0.25} position: {0, 0.25} 
             {
	         	data "Average Happiness" value: happiness_sum/nb_people style: line color: #blue ;
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
/* Insert your model definition here */

