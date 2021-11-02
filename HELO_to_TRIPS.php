<?php
/* ==========================================================
        File: MM2DB.php
        Author: Grant McKenzie
        Date: October, 2020
        Description: Move JSON files to PostGreSQL database
========================================================== */

// A city name (folder) is necessary here
if (!isset($argv[1])) {
        "Provide a city name.\n";
        exit;
}

$city = $argv[1];
$cnt = 0;
$fout = fopen('bixi_trips.csv','w');

$bikes = array();

// Start time for running the script
$start = gmmktime();


$files = scandir($city);
//sort($files, SORT_NUMERIC);

foreach($files as $filei) {
        if (strpos($filei, ".json") !== false) {
                getContents($filei);
        }
}

fclose($fout);


function getContents($filei) {
    global $city;
    global $bikes;
    global $fout;

    $contents = json_decode(file_get_contents($city."/".$filei), false);
     //$gg = explode("/",$filei);
    $filename = str_replace(".json","",$filei);
    if ($contents && property_exists($contents, 'features')) {
    	echo $filename . "\n";
        foreach($contents->features as $station) {
            $lat = $station->geometry->coordinates[1];
            $lng = $station->geometry->coordinates[0];
            $stationid = $station->properties->station->name;
            $vehicles = $station->properties->bikes;
            //echo $filename . "\n";
            foreach($vehicles as $v) {
                //echo $v->id . ", " . $filename . ", ". $v->charge . ", " . $lat . ", " . $lng . "\n";
                if(!isset($bikes[$v->id])) {
                    $bikes[$v->id] = (Object)array('stationid'=>$stationid,'lat'=>$lat, 'lng'=>$lng,'ts'=>intval($filename), 'charge'=>$v->charge);
                } else {
                    $diff_time = intval($filename) - $bikes[$v->id]->ts;
                    $diff_dist = haversine($bikes[$v->id]->lat,$bikes[$v->id]->lng, $lat, $lng);
                    if ($diff_dist > 0) {
                            $content = $v->id . "," . $bikes[$v->id]->stationid . "," . $stationid . "," . $bikes[$v->id]->charge . "," . $v->charge . "," . $bikes[$v->id]->ts . "," . $diff_time . "," . $diff_dist . "\n";
                            fwrite($fout, $content);
                    }

                    $bikes[$v->id] = (Object)array('stationid'=>$stationid,'lat'=>$lat, 'lng'=>$lng,'ts'=>intval($filename), 'charge'=>$v->charge);
                }
            }
        }
    } else {
    	echo "error\t" . $filename . "\n";
    }
}

function getDirContents($dir, &$results = array()) {
    $files = scandir($dir);

    foreach ($files as $key => $value) {
        $path = realpath($dir . DIRECTORY_SEPARATOR . $value);
        if (!is_dir($path)) {
            $results[] = $path;
        } else if ($value != "." && $value != "..") {
            getDirContents($path, $results);
            $results[] = $path;
        }
    }

    return $results;
}

function haversine($latitudeFrom, $longitudeFrom, $latitudeTo, $longitudeTo, $earthRadius = 6371000) {
          // convert from degrees to radians
          $latFrom = deg2rad($latitudeFrom);
          $lonFrom = deg2rad($longitudeFrom);
          $latTo = deg2rad($latitudeTo);
          $lonTo = deg2rad($longitudeTo);

          $latDelta = $latTo - $latFrom;
          $lonDelta = $lonTo - $lonFrom;

          $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));
          return $angle * $earthRadius;
        }


?>
