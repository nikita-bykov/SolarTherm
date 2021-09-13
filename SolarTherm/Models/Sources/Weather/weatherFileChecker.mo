within SolarTherm.Models.Sources.Weather;
function weatherFileChecker "Check and possibly convert weather file"
	import Modelica.Utilities.System.command;
	import Modelica.Utilities.System.getEnvironmentVariable;
	input String file;
	output String file_name;
protected
	String dir;
	String name;
	String ext;
	String SOLARTHERM_SHELL;
	Integer result;
algorithm
	// Should add parameter for whether or not to overwrite existing .motab file.
	(dir, name, ext) := Modelica.Utilities.Files.splitPathName(file);
	if ext == ".motab" then
		assert(checkVersion(file), "Selected .motab file version mismatch, "
			+ "select original source to reconvert " + file);
		file_name := file;
	else
		// use the SOLARTHERM_SHELL env var to tell us how to run 'st wea_to_mo', if available
		SOLARTHERM_SHELL := getEnvironmentVariable('SOLARTHERM_SHELL','st');
		result := command(SOLARTHERM_SHELL + " wea_to_mo " + file);
		assert(result == 0, "Failed to convert weather file " + file);
		file_name := dir + name + ".motab";
		assert(checkVersion(file_name), "Converted weather file version mismatch "
			+ file_name);
	end if;
end weatherFileChecker;
