within SolarTherm.Models.CSP.CRS.HeliostatsField.Optical;
model SolsticeOELT_3Apertures "Lookup table generated by Solstice"
extends OpticalEfficiency_3Apertures;
  import SolarTherm.Models.CSP.CRS.HeliostatsField.Optical.SolsticePyFunc;
  import SI = Modelica.SIunits;
  parameter SolarTherm.Types.Solar_angles angles=SolarTherm.Types.Solar_angles.dec_hra
  "Table angles"
      annotation (Dialog(group="Table data interpretation"));

  parameter String ppath = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/Resources/Include") "Absolute path to the Python script";
  parameter String pname = "run_solstice" "Name of the Python script";
  parameter String pfunc = "run_simul" "Name of the Python functiuon"; 

  parameter String psave = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/Resources/Include/solstice-result/demo") "the directory for saving the results"; 
  parameter String field_type = "multi-aperture" "Other options are : surround";
  parameter String rcv_type = "multi-aperture" "other options are : flat, cylinder, stl";  
  parameter String wea_file = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/Data/Weather/example_TMY3.motab"); 

  parameter Integer argc =30 "Number of variables to be passed to the C function";
  parameter Boolean set_swaying_optical_eff = true "[H&T] True if optical efficiency depends on the wind speed due to swaying effect";
  parameter Boolean optics_verbose = false "[H&T] true if to save all the optical simulation details";
  parameter Boolean optics_view_scene = false "[H&T] true if to visualise the optical simulation scene (generate vtk files)";

  //parameter Boolean single_field = true "True for single field, false for multi tower";
  //parameter Boolean concrete_tower = true "True for concrete, false for thrust tower";
  parameter Real method = 1 "method of the system deisng, 1 is design from the PB, and 2 is design from the field";
  parameter Real n_helios=1000 "Number of heliostats";
  parameter SI.HeatFlowRate Q_in_rcv = 1e6;
  parameter Integer num_aperture = 3 "number of apertures";
  parameter Real angular_range = 180 "Angular range of the multi-aperture configuration";

  parameter SI.Length H_rcv_1=10 "Receiver aperture height at level 1";
  parameter SI.Length W_rcv_1=10 "Receiver aperture width at level 1";

  parameter SI.Length H_rcv_2=10 "Receiver aperture height at level 2";
  parameter SI.Length W_rcv_2=10 "Receiver aperture width at level 2";

  parameter SI.Length H_rcv_3=10 "Receiver aperture height at level 3";
  parameter SI.Length W_rcv_3=10 "Receiver aperture width at level 3";

  parameter Real n_H_rcv=10 "num of grid in the vertical direction (for flux map)";
  parameter Real n_W_rcv=10 "num of grid in the horizontal/circumferetial direction (for flux map)";
  parameter nSI.Angle_deg tilt_rcv = 0 "tilt of receiver in degree relative to tower axis";
  parameter SI.Length W_helio = 10 "width of heliostat in m";
  parameter SI.Length H_helio = 10 "height of heliostat in m";
  parameter SI.Length H_tower = 100 "Tower height";
  parameter SI.Length R_tower = 0.01 "Tower diameter";
  parameter SI.Length R1=80 "distance between the first row heliostat and the tower";
  parameter Real fb=0.7 "factor to grow the field layout";
  parameter SI.Efficiency helio_refl = 0.9 "The effective heliostat reflectance";
  parameter SI.Angle slope_error = 1.53e-3 "slope error of heliostats, in radiance";
  parameter SI.Angle slope_error_windy = 2e-3 "a larger optical error of heliostats under windy conditions, in radiance";
  parameter Real n_row_oelt = 3 "number of rows of the look up table (simulated days in a year)";
  parameter Real n_col_oelt = 3 "number of columns of the lookup table (simulated hours per day)";
  parameter Real n_rays = 5e6 "number of rays for the optical simulation";
  parameter Real n_procs = 0 "number of processors, 0 is using maximum available num cpu, 1 is 1 CPU,i.e run in series mode";

  parameter String tablefile(fixed=false);
  parameter Integer windy_optics(fixed=false) "simulate the windy oelt or not? 1 is yes, 0 is no";
  parameter Integer verbose(fixed=false) "save all the optical simulation details or not? 1 is yes, 0 is no";
  parameter Integer gen_vtk(fixed=false) "visualise the optical simulation scene or not? 1 is yes, 0 is no";

  SI.Angle angle1;
  SI.Angle angle2;
  
  SI.Efficiency nu_1_windy;
  SI.Efficiency nu_2_windy;
  SI.Efficiency nu_3_windy; 

  Modelica.Blocks.Tables.CombiTable2D nu_table_1(
    tableOnFile=true,
    tableName="optical_efficiency_level_1",
    smoothness=Modelica.Blocks.Types.Smoothness.ContinuousDerivative,
    fileName=tablefile)
    annotation (Placement(visible = true, transformation(extent = {{16, 12}, {36, 32}}, rotation = 0)));
    
  Modelica.Blocks.Tables.CombiTable2D nu_table_2(
    tableOnFile=true,
    tableName="optical_efficiency_level_2",
    smoothness=Modelica.Blocks.Types.Smoothness.ContinuousDerivative,
    fileName=tablefile)
    annotation (Placement(visible = true, transformation(extent = {{12, 68}, {32, 88}}, rotation = 0)));

  Modelica.Blocks.Tables.CombiTable2D nu_table_3(
    tableOnFile=true,
    tableName="optical_efficiency_level_3",
    smoothness=Modelica.Blocks.Types.Smoothness.ContinuousDerivative,
    fileName=tablefile)
    annotation (Placement(visible = true, transformation(extent = {{14, -36}, {34, -16}}, rotation = 0)));
    
  Modelica.Blocks.Tables.CombiTable2D nu_table_1_windy(
    tableOnFile=true,
    tableName= if set_swaying_optical_eff then "optical_efficiency_level_1_windy" else "optical_efficiency_level_1",
    smoothness=Modelica.Blocks.Types.Smoothness.ContinuousDerivative,
    fileName=tablefile)
    annotation (Placement(visible = true, transformation(extent = {{-94, -84}, {-74, -64}}, rotation = 0)));
    
  Modelica.Blocks.Tables.CombiTable2D nu_table_2_windy(
    tableOnFile=true,
    tableName= if set_swaying_optical_eff then "optical_efficiency_level_2_windy" else "optical_efficiency_level_2",
    smoothness=Modelica.Blocks.Types.Smoothness.ContinuousDerivative,
    fileName=tablefile)
    annotation (Placement(visible = true, transformation(extent = {{-40, -86}, {-20, -66}}, rotation = 0)));
    
  Modelica.Blocks.Tables.CombiTable2D nu_table_3_windy(
    tableOnFile=true,
    tableName= if set_swaying_optical_eff then "optical_efficiency_level_3_windy" else "optical_efficiency_level_3",
    smoothness=Modelica.Blocks.Types.Smoothness.ContinuousDerivative,
    fileName=tablefile)
    annotation (Placement(visible = true, transformation(extent = {{14, -88}, {34, -68}}, rotation = 0)));
    
  Modelica.Blocks.Sources.RealExpression angle2_input(y=to_deg(angle2))
    annotation (Placement(transformation(extent={{-38,6},{-10,26}})));
    
  Modelica.Blocks.Sources.RealExpression angle1_input(y=to_deg(angle1))
    annotation (Placement(transformation(extent={{-38,22},{-10,42}})));    

initial algorithm
  if set_swaying_optical_eff then windy_optics:=1;
  else windy_optics:=0;
  end if;

  if optics_verbose then verbose:=1;
  else verbose:=0;
  end if;

  if optics_view_scene then gen_vtk:=1;
  else gen_vtk:=0;
  end if;

initial equation
  tablefile =  SolsticePyFunc(ppath, pname, pfunc, psave, field_type, rcv_type, wea_file, argc, {"method", "num_aperture", "gamma","Q_in_rcv", "n_helios", "H_rcv_1", "W_rcv_1","H_rcv_2", "W_rcv_2","H_rcv_3", "W_rcv_3","n_H_rcv", "n_W_rcv", "tilt_rcv", "W_helio", "H_helio", "H_tower", "R_tower", "R1", "fb", "helio_refl", "slope_error", "slope_error_windy", "windy_optics", "n_row_oelt", "n_col_oelt", "n_rays", "n_procs" ,"verbose", "gen_vtk"}, {method, num_aperture, angular_range, Q_in_rcv, n_helios, H_rcv_1, W_rcv_1, H_rcv_2, W_rcv_2, H_rcv_3, W_rcv_3, n_H_rcv, n_W_rcv, tilt_rcv, W_helio, H_helio, H_tower, R_tower, R1, fb, helio_refl, slope_error, slope_error_windy, windy_optics, n_row_oelt, n_col_oelt, n_rays, n_procs, verbose, gen_vtk}); 
equation
  if angles==SolarTherm.Types.Solar_angles.elo_hra then
    angle1=SolarTherm.Models.Sources.SolarFunctions.eclipticLongitude(dec);
    angle2=hra;
  elseif angles==SolarTherm.Types.Solar_angles.dec_hra then
    angle1=dec;
    angle2=hra;
  elseif angles==SolarTherm.Types.Solar_angles.ele_azi then
    angle1=SolarTherm.Models.Sources.SolarFunctions.elevationAngle(dec,hra,lat);
    angle2=SolarTherm.Models.Sources.SolarFunctions.solarAzimuth(dec,hra,lat);
  else
    angle1=SolarTherm.Models.Sources.SolarFunctions.solarZenith(dec,hra,lat);
    angle2=SolarTherm.Models.Sources.SolarFunctions.solarAzimuth(dec,hra,lat);
  end if;
  
  nu_1=max(0,nu_table_1.y);
  nu_2=max(0,nu_table_2.y);
  nu_3=max(0,nu_table_3.y);
  
  nu_1_windy = max(0,nu_table_1_windy.y);
  nu_2_windy = max(0,nu_table_2_windy.y);
  nu_3_windy = max(0,nu_table_3_windy.y);
  
 connect(angle2_input.y, nu_table_1.u2) annotation(
    Line(points = {{-8.6, 16}, {14, 16}}, color = {0, 0, 127}));
 connect(angle1_input.y, nu_table_1.u1) annotation(
    Line(points = {{-8.6, 32}, {2, 32}, {2, 28}, {14, 28}}, color = {0, 0, 127}));
 connect(angle1_input.y, nu_table_2.u1) annotation(
    Line(points = {{-8, 32}, {-6, 32}, {-6, 84}, {10, 84}, {10, 84}}, color = {0, 0, 127}));
 connect(angle2_input.y, nu_table_2.u2) annotation(
    Line(points = {{-8, 16}, {8, 16}, {8, 72}, {10, 72}}, color = {0, 0, 127}));
 connect(angle1_input.y, nu_table_3.u1) annotation(
    Line(points = {{-8, 32}, {0, 32}, {0, -20}, {12, -20}, {12, -20}}, color = {0, 0, 127}));
 connect(angle2_input.y, nu_table_3.u2) annotation(
    Line(points = {{-8, 16}, {-10, 16}, {-10, -32}, {12, -32}, {12, -32}}, color = {0, 0, 127}));
  
 connect(angle1_input.y,nu_table_1_windy.u1);
 connect(angle2_input.y,nu_table_1_windy.u2);
 connect(angle1_input.y,nu_table_2_windy.u1);
 connect(angle2_input.y,nu_table_2_windy.u2);
 connect(angle1_input.y,nu_table_3_windy.u1);
 connect(angle2_input.y,nu_table_3_windy.u2);

end SolsticeOELT_3Apertures;
