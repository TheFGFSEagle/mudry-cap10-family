#### Fichier crée par Flavien Blanc (Fly) ####
#### equipe-flightgear.forumactif.com ####

var config_dlg = gui.Dialog.new("/sim/gui/dialogs/config/dialog", getprop("/sim/aircraft-dir")~"/Dialogs/config.xml");

##########################################
# Horameter / Chrono
##########################################

props.globals.initNode("/instrumentation/horameter/elapsed-time", 0, "INT");
props.globals.initNode("/instrumentation/chrono/elapsed-time", 0, "INT");

var chrono = aircraft.timer.new("/instrumentation/chrono/elapsed-time", 1);
var horameter = aircraft.timer.new("/instrumentation/horameter/elapsed-time", 1, 1);

setlistener("/instrumentation/horameter/running", func(running){
  if(running.getBoolValue()){
    horameter.start();
  }else{
    horameter.stop();
  }
});


var floor = func(v) v < 0.0 ? -int(-v) - 1 : int(v);
var elapsedTime = 0;
var formatedTime = "";
var sec = 0;
var min = 0;
var hrs = 0;

var timeFormat = func{

  elapsedTime = getprop("/instrumentation/chrono/elapsed-time");

  hrs = floor(elapsedTime/3600);
  min = floor(elapsedTime/60);
  sec = elapsedTime;

  formatedTime = sprintf("%02d:%02d:%02d", hrs, min-(60*hrs), sec-(60*min));
  setprop("/instrumentation/chrono/formated-time", formatedTime);

}

##########################################
# Mixture/Throttle controlled by mouse
##########################################

var mousex =0;
var msx = 0;
var msxa = 0;
var mousey = 0;
var msy = 0;
var msya=0;

var mouse_accel=func{
  msx=getprop("devices/status/mice/mouse/x") or 0;
  mousex=msx-msxa;
  mousex*=0.5;
  msxa=msx;
  msy=getprop("devices/status/mice/mouse/y") or 0;
  mousey=msya-msy;
  mousey*=0.5;
  msya=msy;
#  settimer(mouse_accel, 0);
}

var set_levers = func(type,num,min,max){
  var ctrl=[];
  var cpld=-1;
  if(type == "throttle"){
    ctrl = ["controls/engines/engine[0]/throttle","controls/engines/engine[1]/throttle"];
    cpld = "controls/throttle-coupled";
  }elsif(type == "prop"){
    ctrl = ["controls/engines/engine[0]/propeller-pitch","controls/engines/engine[1]/propeller-pitch"];
    cpld = "controls/prop-coupled";
  }elsif(type == "mixture"){
    ctrl = ["controls/engines/engine[0]/mixture","controls/engines/engine[1]/mixture"];
    cpld ="controls/mixture-coupled";
  }

  var amnt =mousey* getprop("controls/movement-scale");
  var ttl = getprop(ctrl[num]) + amnt;
  if(ttl > max) ttl = max;
  if(ttl<min)ttl=min;
  setprop(ctrl[num],ttl);
  if(getprop(cpld))setprop(ctrl[1-num],ttl);
}

##########################################
# Ground Detection
##########################################

var terrain_survol = func {
  var lat = getprop("/position/latitude-deg");
  var lon = getprop("/position/longitude-deg");

  var info = geodinfo(lat, lon);
  if (info != nil) {
    if (info[1] != nil){
      if (info[1].solid !=nil)
        setprop("/environment/terrain-type",info[1].solid);
      if (info[1].load_resistance !=nil)
        setprop("/environment/terrain-load-resistance",info[1].load_resistance);
      if (info[1].friction_factor !=nil)
        setprop("/environment/terrain-friction-factor",info[1].friction_factor);
      if (info[1].bumpiness !=nil)
        setprop("/environment/terrain-bumpiness",info[1].bumpiness);
      if (info[1].rolling_friction !=nil)
        setprop("/environment/terrain-rolling-friction",info[1].rolling_friction);
      if (info[1].names !=nil)
        setprop("/environment/terrain-names",info[1].names[0]);
    }         
  }else{
    setprop("/environment/terrain",1);
    setprop("/environment/terrain-load-resistance",1e+30);
    setprop("/environment/terrain-friction-factor",1.05);
    setprop("/environment/terrain-bumpiness",0);
    setprop("/environment/terrain-rolling-friction",0.02);
  }

  if(!getprop("sim/freeze/replay-state") and !getprop("/environment/terrain-type") and getprop("/position/altitude-agl-ft") < 3.0){
    setprop("sim/messages/copilot", "You are on water !");
    setprop("sim/freeze/clock", 1);
    setprop("sim/freeze/master", 1);
    setprop("sim/crashed", 1);
  }
#  settimer(terrain_survol, 0);
}

##############################################
######### AUTOSTART / AUTOSHUTDOWN ###########
##############################################

setlistener("/sim/model/start-idling", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

var Startup = func{
  setprop("controls/fuel/selected-tank", 1);
#  setprop("controls/fuel/tank/boost-pump", 1);
  setprop("controls/engines/engine[0]/master-alt",1);
  setprop("/controls/engines/engine[0]/magnetos",3);
  setprop("controls/engines/engine[0]/mixture",1);
  setprop("/controls/gear/brake-parking",1);
#  setprop("/controls/lighting/instruments-norm",1);
  setprop("/instrumentation/comm[0]/power-btn",1);
  setprop("/instrumentation/comm[0]/volume",1);
  setprop("/instrumentation/nav[0]/power-btn",1);  
  setprop("/instrumentation/nav[0]/volume",1);
  setprop("/instrumentation/adf[0]/power-btn",1);
  setprop("/instrumentation/adf[0]/volume",1);
  setprop("/instrumentation/adf[0]/volume-norm",1);
  setprop("controls/electric/battery-switch",1);
  setprop("controls/switches/ai-switch",1);
  setprop("controls/switches/hi-switch",1);
  setprop("controls/lighting/strobe-lights", 1);
  setprop("controls/lighting/nav-lights", 1);
  setprop("sim/messages/copilot", "Now press \"s\" to start engine");
}

var Shutdown = func{
  setprop("controls/fuel/selected-tank", 0);
  setprop("controls/engines/engine[0]/master-alt",0);
  setprop("/controls/engines/engine[0]/magnetos",0);
  setprop("controls/engines/engine[0]/mixture",1);
  setprop("/engines/engine[0]/rpm",0);
  setprop("/engines/engine[0]/running",0);
  setprop("/controls/gear/brake-parking",1);
#  setprop("/controls/lighting/instruments-norm",0);
  setprop("/instrumentation/comm[0]/power-btn",0);
  setprop("/instrumentation/comm[0]/volume",0);
  setprop("/instrumentation/nav[0]/power-btn",0);
  setprop("/instrumentation/nav[0]/volume",0);
  setprop("/instrumentation/adf[0]/power-btn",0);
  setprop("/instrumentation/adf[0]/volume",0);
  setprop("/instrumentation/adf[0]/volume-norm",0);
  setprop("controls/electric/battery-switch",0);
#  setprop("controls/fuel/tank/boost-pump", 0);
  setprop("controls/switches/ai-switch",0);
  setprop("controls/switches/hi-switch",0);
  setprop("controls/lighting/strobe-lights", 0);
  setprop("controls/lighting/nav-lights", 0);
  setprop("sim/messages/copilot", "Engine is stopped");
}

############################################
# Global loop function
# If you need to run nasal as loop, add it in this function
############################################
global_system = func{

  if(getprop("/systems/electrical/outputs/starter") > 18){
    setprop("/controls/engines/engine[0]/starter",1);
  }else{
    setprop("/controls/engines/engine[0]/starter",0);
  }

#  if(getprop("fdm/jsbsim/propulsion/tank[0]/priority")){
#    setprop("fdm/jsbsim/propulsion/tank[1]/priority", 0);
#  }

  if(getprop("/systems/electrical/volts") > 3){
    setprop("/instrumentation/horameter/running", 1);
    interpolate("consumables/fuel/tank[0]/level-gal_us-pos", getprop("consumables/fuel/tank[0]/level-gal_us"), 0.5);
    interpolate("consumables/fuel/tank[1]/level-gal_us-pos", getprop("consumables/fuel/tank[1]/level-gal_us"), 0.5);
    interpolate("fdm/jsbsim/propulsion/engine/oil-pressure-psi-pos", getprop("fdm/jsbsim/propulsion/engine/oil-pressure-psi"), 0.5);
    interpolate("fdm/jsbsim/propulsion/engine/oil-temperature-degF-pos", getprop("fdm/jsbsim/propulsion/engine/oil-temperature-degF"), 0.5);
  }else{
    setprop("/instrumentation/horameter/running", 0);
    interpolate("consumables/fuel/tank[0]/level-gal_us-pos", 0, 0.5);
    interpolate("consumables/fuel/tank[1]/level-gal_us-pos", 0, 0.5);
    interpolate("fdm/jsbsim/propulsion/engine/oil-pressure-psi-pos", 0, 0.5);
    interpolate("fdm/jsbsim/propulsion/engine/oil-temperature-degF-pos", 0, 0.5);
  }

  if(getprop("/systems/electrical/outputs/ai") > 6){
    setprop("/instrumentation/attitude-indicator/spin",10);
  }else{
    setprop("/instrumentation/attitude-indicator/spin",0);
  }

  if(getprop("/systems/electrical/outputs/hi") > 6){
    setprop("/instrumentation/heading-indicator/spin",10);
  }else{
    setprop("/instrumentation/heading-indicator/spin",0);
  }

  mouse_accel();
  terrain_survol();
  timeFormat();
  cap10b.physics();

  settimer(global_system, 0);

}

############################################
# Upside down system
############################################
var timeOfNegatifG = 0;
upsideDown_system = func{

  if(getprop("fdm/jsbsim/accelerations/Nz") < -0.5){
    timeOfNegatifG += 1;
    if(timeOfNegatifG > 4){
      if(getprop("fdm/jsbsim/propulsion/tank[1]/priority") > getprop("fdm/jsbsim/propulsion/tank[0]/priority")){
        setprop("fdm/jsbsim/propulsion/tank[1]/priority", 0);
      }
      timeOfNegatifG = 0;
    }
  }else{
    timeOfNegatifG = 0;
  }
  settimer(upsideDown_system, 1);
}

##########################################
# SetListerner must be at the end of this file
##########################################
setlistener("/sim/signals/fdm-initialized", func{
  setprop("/environment/terrain-type",1);
  setprop("/environment/terrain-load-resistance",1e+30);
  setprop("/environment/terrain-friction-factor",1.05);
  setprop("/environment/terrain-bumpiness",0);
  setprop("/environment/terrain-rolling-friction",0.02);
  setprop("/instrumentation/nav[0]/power-btn",0); #force OFF
  setprop("/instrumentation/adf[0]/power-btn",0);
  setprop("/instrumentation/adf[0]/volume",0);
  setprop("/instrumentation/adf[0]/volume-norm",0);
  setprop("/controls/lighting/nav-lights", 0);
  setprop("/controls/lighting/landing-lights", 0);
  setprop("/controls/electric/battery-switch", 0);
  setprop("/instrumentation/ertical-speed-indicator/indicated-speed-fpm", 0);

  if(getprop("sim/rendering/rembrandt/enabled") == nil){
    props.globals.initNode("sim/rendering/rembrandt/enabled", 0, "BOOL");
    print("Rembrandt no available");
  }

});

var nasalInit = setlistener("/sim/signals/fdm-initialized", func{
  settimer(global_system, 2);
  settimer(upsideDown_system, 2);
  removelistener(nasalInit);
});
