within examples;

model AnnualOpticalBeamDown

  import SolarTherm.Models.CSP.CRS.HeliostatsField.Optical.SolsticeOELT;
  import SI = Modelica.SIunits;
  import nSI = Modelica.SIunits.Conversions.NonSIunits;
  import metadata = SolarTherm.Utilities.Metadata_Optics;

  parameter String wea_file = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/Data/Weather/AUS_WA_Leinster_Airport_954480_TMY.motab");
  parameter Real metadata_list[10] = metadata(opt_file);
  parameter nSI.Angle_deg lon = 120.70 "Longitude (+ve East)";
  parameter nSI.Angle_deg lat = -27.85 "Latitude (+ve North)";
  parameter nSI.Time_hour t_zone = 9.5 "Local time zone (UCT=0)";
  parameter Integer year = 1996 "Meteorological year";
  parameter String opt_file(fixed=false);
  parameter String casefolder = "optic" "dont change this";
  
  /*
      Reading metadata from $casefolder/OELT_Solstice.motab
          n_helios, A_helio, A_secref, A_cpc, Eff_design, H_rcv, W_rcv, H_tower, Q_in_rcv, A_land
  */
  parameter Real n_h=metadata_list[1] "Number of heliostats";
  parameter SI.Area A_h=metadata_list[2] "Heliostat's area in m2";
  parameter Real A_secref=metadata_list[3] "Secondary reflector area in m2";
  parameter SI.Area A_cpc=metadata_list[4] "CPC area in m2";
  parameter Real eta_field_design=metadata_list[5] "Field eff. at design point";
  parameter SI.HeatFlowRate Q_in_rcv_from_OELT = metadata_list[9] "Incident heat flow rate on the aperture at design point after ray tracing [W]";
  parameter SI.Area A_land = metadata_list[10] "Land area in m2";

  /*System size*/
  parameter SI.HeatFlowRate Q_in_rcv = 50e6 "Incident thermal power to the receiver";
  
  /*Iron sample*/
  parameter String iron_sample = "A_1" "Which iron sample used"; 
  
  /*Heliostat and tower parameters*/
  parameter nSI.Angle_deg cpc_theta_deg=26 "acceptance half angle of the CPC in degree";
  parameter Real cpc_h_ratio=0.6 "ratio of CPC critical height [0,1]";
  parameter nSI.Angle_deg aperture_angle_x=160 "aperture angle of the heliostat field in the xOz plan in degree [0,180] ";
  parameter nSI.Angle_deg aperture_angle_y=0 "aperture angle of the heliostat field in the yOz plan in degree [0,180] ";
  parameter nSI.Angle_deg secref_offset = 0.  "Offset of the mirror central line with regards to the hyperboloid axis of symmetry [-100,100]";
  parameter Real secref_inv_eccen=0.7 "Secondary Reflector (hyperboloid) inverse eccentricity [0,1]";
  parameter SI.Length H_tower=80.64 "Tower height";
  parameter Real fb=0.9618 "factor to grow the field layout";
  parameter nSI.Angle_deg tilt_secref=-5 "tilt angle of the secondary mirror (hyperboloid) central axis along the N-S axis in degree";
  parameter SI.Length W_rcv=8 "Polygon receiver width";
  parameter SI.Length H_rcv= W_rcv "Polygon receiver length. Made square";
  parameter SI.Length R1=15. "distance between the first row heliostat and the tower";
  parameter SI.Length W_helio = 6.1 "width of heliostat in m";
  parameter SI.Length H_helio = 6.1 "height of heliostat in m";
  parameter SI.Angle slope_error_bd = 1e-3 "slope error of all reflective surfaces in mrad";
  parameter SI.Efficiency rho_secref = 0.95 "reflectivity of the secondary reflector (hyperboloid)";
  parameter SI.Efficiency rho_cpc = 0.95 "reflectivity of the CPC";
  parameter Real cpc_nfaces=4 "2D-crossed cpc with n faces";

  /*Optical parameters*/
  parameter Real n_rays = 5e6 "number of rays for the optical simulation";
  parameter Real n_row_oelt = 5 "number of rows of the look up table (simulated days in a year)";
  parameter Real n_col_oelt = 22 "number of columns of the lookup table (simulated hours per day)";
  parameter SI.Length Z_helio = 0.0 "heliostat center z location in m";
  parameter Real n_H_rcv=40 "rendering of flux map on receiver";
  parameter SI.Length Z_rcv=0 "Polygon receiver z position, 0 is on the ground";
  
  //Environmental variables to run the interpolation functions
  parameter String ppath_sintering = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/Resources/Include") "Path to the directory where the Python script is hosted";
  parameter String pname_sintering = "run_sintering_thermal_model" "The name of the Python script";
  parameter String pfunc_sintering = "run_interpolate" "Name of the function inside pname.py that will be called";
  parameter String modelica_wd = Modelica.Utilities.Files.loadResource(casefolder) "Folder in which the CSVs storing flux map are located absolute p";
  parameter String SolarTherm_path = Modelica.Utilities.Files.loadResource("modelica://SolarTherm");
  
  //Parameters to generate the training data
  parameter String thermal_model_name_parameters[:] = {
    "T_sky", "k_s", "alpha", "eps_r", "h_ext", "eps",
    "T_i_s_HX1", "T_o_s_HX1", "T_i_g_HX1", "d_p_HX1", "H_HX1", "W_HX1", "t_wall_HX1",
    "T_i_s_HX2", "T_o_s_HX2", "T_i_g_HX2", "W_HX2", "d_p_HX2",
    "flux_multiple_off"
  };
  
  parameter Real thermal_model_parameters[:] = {
      T_sky -273.15, k_s, alpha, eps_r, h_ext, eps,
      T_i_s_HX1 -273.15, T_o_s_HX1 -273.15, T_i_g_HX1 -273.15, d_p_HX1 * 1000, H_HX1, W_HX1, t_wall_HX1 * 100,
      T_i_s_HX2 - 273.15, T_o_s_HX2 - 273.15, T_i_g_HX2 - 273.15, W_HX2, d_p_HX2 * 1000,
      1
  };
  
  //Ambient condition parameters
  parameter SI.Temperature T_sky = 40 + 273.15 "Sky temperature [K]";
  parameter SI.ThermalConductivity k_s = 6.5 "Thermal conductivity [W/(m.K)]";
  parameter Real alpha = 0.95 "Absorptivity [-]";
  parameter Real eps_r = 0.9 "Emmissivity [-]-";
  parameter SI.CoefficientOfHeatTransfer h_ext = 20 "Coefficient of convective heat transfer [W/(m2.K)]";
  parameter Real eps = 0.4 "Void fraction [-]";
  

  //Receiver design point parameters
  parameter SI.Temperature T_i_s_HX1 = 25 +273.15 "Iron ore inlet temperature [K]";
  parameter SI.Temperature T_o_s_HX1 = 1140 + 273.15 "Iron ore outlet temperature [K]";
  parameter SI.Temperature T_i_g_HX1 = 1250 + 273.15 "Air inlet temperature [K]";
  parameter SI.Length d_p_HX1 = 7.5e-3 "Iron ore diameter [m]";
  parameter SI.Length H_HX1 = 0.05 "Thickness of heat exchanger [m]";
  parameter SI.Length W_HX1 = W_rcv "Width of heat exchanger [m] equals to W_rcv. SRC: P45 Meeting 3 Dec 2021";
  parameter SI.Length t_wall_HX1 = 0.01 "Wall thickness of heat exchanger [m]";
  
  parameter SI.Temperature T_i_s_HX2 = 1350 +273.15 "Iron ore inlet temperature [K]";
  parameter SI.Temperature T_o_s_HX2 = 200 + 273.15 "Iron ore outlet temperature [K]";
  parameter SI.Temperature T_i_g_HX2 = 25 + 273.15 "Air inlet temperature [K]";
  parameter SI.Length W_HX2 = W_rcv "Width of heat exchanger [m] equals to W_rcv. SRC: P45 Meeting 3 Dec 2021";
  parameter SI.Length d_p_HX2 = 40e-3 "Iron ore diameter [m]";
    
  //status_run to launch the ASCEND model --> collecting training data
  parameter Integer status_run(fixed=false);
  parameter Real design_point_result[3](each fixed=false);
  
  /*Design point calculation result*/
  parameter Real mdot_ore_design_point(fixed=false);
  parameter SI.Volume V_HX1(fixed=false);
  parameter SI.Volume V_HX2(fixed=false);
  
  /*PHX calculation*/
  parameter SI.Density rho_material_HX = 7850 "Density of carbon steel assumed material for HXs Carbon Steel ASTM A36. Source: https://amesweb.info/Materials/Density_of_Steel.aspx";
  parameter SI.Mass M_HX = (V_HX1 + V_HX2) * rho_material_HX "Total weight of HXs in kg for CAPEX calculation";
 
  //Specific cost of components
  parameter Real pri_tower = 725.9 "USD/kWth";
  parameter Real pri_secondary_mirror = 100 "USD/m2";
  parameter Real pri_field = 75 "USD/m2";
  parameter Real pri_CPC = 300 "USD/m2";
  parameter Real pri_land = 2.47105163015276 "USD/m2 based on Gen3 Topic 1 Downselect Criteria rev_1 Chapter 3.1.3";
     
  //Financial parameters
  parameter Real r_disc = 0.0401;  
  parameter Integer t_life = 30;
  parameter Integer t_cons = 0;
  parameter Real r_contg = 0.1;
  parameter Real r_cons = 0.06;
  
  //O&M cost
  parameter Real C_year = 0.05 * C_cap;
  parameter Real C_prod = 0;
    
  //Cost calculation
  parameter Real C_tower = pri_tower * Q_in_rcv/1e3;
  parameter Real C_secondary_mirror = pri_secondary_mirror * A_secref; //=====> Ask C secondary mirror to clotilde
  parameter Real C_field = pri_field * n_h * A_h;
  parameter Real C_CPC = pri_CPC * A_cpc; //=====> Ask clotilde about CPC area
  parameter Real C_trussed_framework = 0.84 * 1e6 "USD"; 
  parameter Real C_reactor = 0;
  parameter Real C_HX = Modelica.Math.exp(
                8.9552-0.233 * Modelica.Math.log(M_HX)+ 
                      0.04333*(Modelica.Math.log(M_HX)^2)
  ); 
  parameter Real C_land = pri_land * A_land;
  
  parameter Real C_equipment = C_tower + C_secondary_mirror + C_field + C_CPC + C_trussed_framework;
  parameter Real C_direct = (1 + r_contg) * C_equipment;
  parameter Real C_indirect = r_cons * C_direct + C_land;
  
  parameter Real C_cap = C_direct + C_indirect; 

  //Sun
  SolarTherm.Models.Sources.SolarModel.Sun sun(
      lon = data.lon,
      lat = data.lat,
      t_zone = data.t_zone,
      year = data.year,
      redeclare function solarPosition = SolarTherm.Models.Sources.SolarFunctions.PSA_Algorithm) annotation(
                                                                                                      Placement(transformation(extent = {{-82, 60}, {-62, 80}})));


  //Weather data
  SolarTherm.Models.Sources.DataTable.DataTable data(
      lon = lon,
      lat = lat,
      t_zone = t_zone,
      year = year,
      file = wea_file) annotation(
                                          Placement(visible = true, transformation(extent = {{-100, -50}, {-70, -22}}, rotation = 0)));

  //DNI_input
  Modelica.Blocks.Sources.RealExpression DNI_input(
      y = data.DNI) annotation(
                                  Placement(visible = true, transformation(extent = {{-102, 64}, {-82, 84}}, rotation = 0)));
  
  //Solstice beam-down
  SolarTherm.Models.CSP.CRS.HeliostatsField.Optical.SolsticeOELTBeamdown lookuptable(
      cpc_theta_deg=cpc_theta_deg,
      cpc_h_ratio=cpc_h_ratio,
      aperture_angle_x=aperture_angle_x,
      aperture_angle_y=aperture_angle_y,
      secref_offset=secref_offset,
      secref_inv_eccen=secref_inv_eccen,
      H_tower=H_tower,
      fb=fb,
      tilt_secref=tilt_secref,
      Z_rcv=Z_rcv,
      W_rcv=W_rcv,
      H_rcv=H_rcv,
      n_rays=n_rays,
      n_row_oelt=n_row_oelt,
      n_col_oelt=n_col_oelt,
      Q_in_rcv=Q_in_rcv,
      R1=R1,
      W_helio=W_helio,
      H_helio=H_helio,
      Z_helio=Z_helio,
      slope_error_bd=slope_error_bd,
      rho_secref=rho_secref,
      rho_cpc=rho_cpc,
      cpc_nfaces=cpc_nfaces,
      n_H_rcv=n_H_rcv,
      psave=casefolder,
      hra=sun.solar.hra,
      dec=sun.solar.dec,
      lat=lat
  );
  
  //Variable for optical
  Real opt_eff;
  Real opt_ann_eff "annual optical efficiency";
  
  //Inputs to interpolation
  nSI.Angle_deg declination_inDeg;
  nSI.Angle_deg sun_hour_angle_inDeg;
  Real flux_multiple_off;
  SI.Mass M_ore "mass of ore accummulated thru out the year [kg]";
  
  //Analysis
  SI.Energy E_sun;
  SI.Energy E_rcv;
  SI.HeatFlowRate Q_sun;
  SI.HeatFlowRate Q_rcv;

initial equation
  /*Call Solstice to generate OELT*/
  opt_file = lookuptable.tablefile;
  
  /*Call mdot ore design point*/
  design_point_result = SolarTherm.Utilities.RunSinteringThermalModelDesignPoint(
      ppath_sintering, 
      pname_sintering, 
      "run_thermalSinteringModelDesignPoint", 
      SolarTherm_path, 
      modelica_wd, 
      thermal_model_name_parameters, 
      thermal_model_parameters, 
      19, 
      iron_sample, 
      opt_file
  );
  
  mdot_ore_design_point = design_point_result[1]; 
  V_HX1 = design_point_result[2]; 
  V_HX2 = design_point_result[3];
  
  /*Initialisation of the model*/
  if Q_in_rcv_from_OELT > Q_in_rcv then
      Modelica.Utilities.Streams.print("Heat duty delivered by heliostat field is enough\n\n");
      status_run = SolarTherm.Utilities.RunSinteringThermalModel(ppath_sintering, pname_sintering, SolarTherm_path, modelica_wd, thermal_model_name_parameters, thermal_model_parameters, opt_file, iron_sample);
  else
      Modelica.Utilities.Streams.print("Heat duty delivered by heliostat field is NOT enough\n\n");
      status_run = -1000;
  end if;

equation
  declination_inDeg = Modelica.SIunits.Conversions.to_deg(sun.dec);
  sun_hour_angle_inDeg = Modelica.SIunits.Conversions.to_deg(sun.hra);
  flux_multiple_off = data.DNI/1000;
  
  if status_run > 0 then
	  /*If heliostat field gives the adeuqate amount of heat at design point then the system is eligible to run*/
	  if flux_multiple_off < 0.7 then
		  der(M_ore) = 0;
	  else
		  der(M_ore) = SolarTherm.Utilities.InterpolateSinteringThermalModel(
		        ppath_sintering, pname_sintering, 
		        pfunc_sintering, 
		        modelica_wd, declination_inDeg, 
		        sun_hour_angle_inDeg, flux_multiple_off
		  );
	  end if;
  
  else
	  /*If heliostat field could not provide the requested heat, then the yield is forced to be zero to cut computational time*/
	  der(M_ore) = 0;
  end if;
  
  opt_eff=lookuptable.nu;
  Q_sun=sun.dni*n_h*A_h;
  der(E_sun)=Q_sun;

  Q_rcv=sun.dni*n_h*A_h*opt_eff;
  der(E_rcv)=Q_rcv;
  
  if time > 3.1535e7 then
      opt_ann_eff=E_rcv/E_sun;
  else
      opt_ann_eff = 0;
  end if;

  connect(DNI_input.y, sun.dni) annotation(
												Line(points = {{-119, 70}, {-102, 70}, {-102, 69.8}, {-82.6, 69.8}}, color = {0, 0, 127}, pattern = LinePattern.Dot));

  annotation(
    Icon(coordinateSystem(extent = {{-140, -120}, {160, 140}})),
    experiment(StopTime = 3.1536e+07, StartTime = 0, Tolerance = 0.0001, Interval = 3600),
    __Dymola_experimentSetupOutput,
    Documentation(revisions = "<html>
	<ul>
	<li> Y. Wang (23 Jun 2021) :<br>Released first version. </li>
	</ul>

	</html>"),
    Diagram(coordinateSystem(extent = {{-140, -120}, {160, 140}}, initialScale = 0.1)));
end AnnualOpticalBeamDown;
