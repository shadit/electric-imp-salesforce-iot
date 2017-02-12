#require "Salesforce.class.nut:1.1.0"
#require "Rocky.class.nut:1.2.3"

#require "bullwinkle.class.nut:2.3.0"
#require "promise.class.nut:3.0.0"

/***************************************************************************************
 * SmartFrigDataManager Class:
 *      Handle incoming device readings
 *      Set sensor threshold values
 *      Set callback handlers for events and streaming data
 *      Check for temperature, humidity, and door events
 *      Average temperature and humidity readings
 **************************************************************************************/
class SmartFrigDataManager {

    // Default settings
    static DEFAULT_LX_THRESHOLD = 50; // LX level indicating door open
    static DEFAULT_TEMP_THRESHOLD = 11;
    static DEFAULT_HUMID_THRESHOLD = 70;

    // IoT Cloud settings - TODO: update with values from your configuration
    static INPUT_CONN_URL = "";
    static BEARER_KEY = "";

    // Class variables
    _bull = null;

    // Threshold
    _tempThreshold = null;
    _humidThreshold = null;
    _lxThreshold = null;
    _thresholdsUpdated = null;

    /***************************************************************************************
     * Constructor
     * Returns: null
     * Parameters:
     *      bullwinkle : instance - of Bullwinkle class
     **************************************************************************************/
    constructor(bullwinkle) {
        _bull = bullwinkle;
        setThresholds(DEFAULT_TEMP_THRESHOLD, DEFAULT_HUMID_THRESHOLD, DEFAULT_LX_THRESHOLD);
        openListeners();
    }

     /***************************************************************************************
     * openListeners
     * Returns: this
     * Parameters: none
     **************************************************************************************/
    function openListeners() {
        _bull.on("readings", _readingsHandler.bindenv(this));
        _bull.on("lxThreshold", _lxThresholdHandler.bindenv(this));
        return this;
    }

    /***************************************************************************************
     * setThresholds
     * Returns: null
     * Parameters:
     *      temp : integer - new tempertature threshold value
     *      humid : integer - new humid threshold value
     *      lx : integer - new light level door  value
     **************************************************************************************/
    function setThresholds(temp, humid, lx) {
        _tempThreshold = temp;
        _humidThreshold = humid;
        _lxThreshold = lx;
        _thresholdsUpdated = true;
    }

    /***************************************************************************************
     * _lxThresholdHandler
     * Returns: null
     * Parameters:
     *      message : table - message received from bullwinkle listener
     *      reply: function that sends a reply to bullwinle message sender
     **************************************************************************************/
    function _lxThresholdHandler(message, reply) {
        if (_thresholdsUpdated) {
            reply(_lxThreshold);
            _thresholdsUpdated = false;
        } else {
            reply(null);
        }
    }

    /***************************************************************************************
     * _eventToIoT
     * Returns: null
     * Parameters:
     *      iotEvent : table - message received from bullwinkle listener
     **************************************************************************************/
    function _eventToIoT(iotEvent) {
        // Build the request
        local headers = { "Content-Type": "application/json",
                          "Authorization": "Bearer " + BEARER_KEY};

        local iotBody = http.jsonencode(iotEvent);
        server.log("iotBody=" + iotBody);

        http.post(INPUT_CONN_URL, headers, iotBody).sendasync(function(resp) {
            local respData = http.jsondecode(resp.body);
            local err = null;

            // If there was an error, set the error code
            if (resp.statuscode != 200) {
                err = data.message;
                server.log("err=" + err);
            }
        });
    }

    /***************************************************************************************
     * _readingsHandler
     * Returns: null
     * Parameters:
     *      message : table - message received from bullwinkle listener
     *      reply: function that sends a reply to bullwinle message sender
     **************************************************************************************/
    function _readingsHandler(message, reply) {
        // grab readings array from message
        local readings = message.data;

        // set up variables for calculating reading average
        local tempAvg = 0;
        local humidAvg = 0
        local numReadings = 0;

        // set up variables for door event
        local doorOpen = null;
        local ts = null;

        // process readings
        // reading table keys : "brightness", "humidity", "temperature", "ts"
        foreach(reading in readings) {
            // calculate temperature and humidity totals
            if ("temperature" in reading && "humidity" in reading) {
                numReadings++;
                tempAvg += reading.temperature;
                humidAvg += reading.humidity;
            }

            // get time stamp of reading
            ts = reading.ts;

            // determine door status
            if ("brightness" in reading) doorOpen = _checkDoorEvent(ts, reading.brightness);
        }

        if (numReadings != 0) {
            // average the temperature and humidity readings
            tempAvg = tempAvg/numReadings;
            humidAvg = humidAvg/numReadings;
        }

        // send ack to device (device erases this set of readings when ack received)
        reply("OK");

        // Shad - send event to IoT Cloud
        local tempAvgFahrenheit = (tempAvg * 1.8) + 32;
        local iotEvent = {"device_id" : imp.configparams.deviceid, "tempC" : tempAvg, "tempF" : tempAvgFahrenheit, "humidity" : humidAvg, "door" : doorOpen};
        _eventToIoT(iotEvent);
    }

    /***************************************************************************************
     * _checkDoorEvent
     * Returns: sting - door status
     * Parameters:
     *      lxLevel : float - a light reading
     *      readingTS : integer - the timestamp of the reading
     **************************************************************************************/
    function _checkDoorEvent(readingTS, lxLevel = null) {
        // Boolean if door open event occurred
        local doorOpen = (lxLevel == null || lxLevel > _lxThreshold);
        return (doorOpen) ? "open" : "closed";
    }
}

// APPLICATION CLASS TO SEND DATA/ALERTS TO IOT CLOUD
// ----------------------------------------------------------
class Application {
    _dm = null;
    _deviceID = null;

    constructor() {
        _deviceID = imp.configparams.deviceid.tostring();
        local _bull = Bullwinkle();
        _dm = SmartFrigDataManager(_bull);
    }
}

// RUNTIME
// ---------------------------------------------------------------------------------
Application();