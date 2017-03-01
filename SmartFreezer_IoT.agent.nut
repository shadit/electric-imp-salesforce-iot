#require "Rocky.class.nut:1.2.3"
#require "bullwinkle.class.nut:2.3.0"
#require "promise.class.nut:3.0.0"

/***************************************************************************************
 * SmartFreezerDataManager Class:
 *      Handle incoming device readings
 *      Set sensor threshold values
 *      Send events to Salesforce IoT Cloud
 **************************************************************************************/
class SmartFreezerDataManager {
    // IoT Cloud settings - TODO: update with values from your configuration
    static INPUT_CONN_URL = "UPDATE ME";
    static BEARER_TOKEN = "UPDATE ME";

    // LX level indicating door open
    static DEFAULT_LX_THRESHOLD = 50;

    // Threshold handling
    _lxThreshold = null;
    _thresholdsUpdated = null;
    _prevDoorState = null;

    // Instance of Bullwinkle class
    _bull = null;

    /***************************************************************************************
     * Constructor
     * Returns: null
     * Parameters:
     *      bullwinkle : instance - of Bullwinkle class
     **************************************************************************************/
    constructor() {
        _bull = Bullwinkle();
        setThresholds(DEFAULT_LX_THRESHOLD);
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
     *      lx : integer - new light level door  value
     **************************************************************************************/
    function setThresholds(lx) {
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
     *      iotEvent : table - message received from _readingsHandler
     **************************************************************************************/
    function _eventToIoT(iotEvent) {
        // Build the request
        local headers = { "Content-Type": "application/json",
                          "Authorization": "Bearer " + BEARER_TOKEN};

        local iotBody = http.jsonencode(iotEvent);
        server.log("Sending event to IoT Cloud. iotBody=" + iotBody);

        http.post(INPUT_CONN_URL, headers, iotBody).sendasync(function(resp) {
            if (resp.statuscode != 200) {
                server.log("ERROR! statuscode=" + resp.statuscode);
                server.log("Ensure INPUT_CONN_URL and BEARER_TOKEN are configured correctly.");
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

        // reading table keys : "brightness", "humidity", "temperature"
        foreach(reading in readings) {
            // calculate temperature and humidity totals
            if ("temperature" in reading && "humidity" in reading) {
                numReadings++;
                tempAvg += reading.temperature;
                humidAvg += reading.humidity;
            }

            // determine door status
            if ("brightness" in reading) doorOpen = _checkDoorEvent(reading.brightness);
        }

        if (numReadings != 0 && doorOpen != _prevDoorState) {
            // average the temperature and humidity readings
            tempAvg = tempAvg/numReadings;
            humidAvg = humidAvg/numReadings;

            // Record the door state
            _prevDoorState = doorOpen;

            // Send event to IoT Cloud
            local tempAvgFahrenheit = (tempAvg * 1.8) + 32;
            _eventToIoT({"device_id" : imp.configparams.deviceid,
                         "tempC"     : tempAvg,
                         "tempF"     : tempAvgFahrenheit,
                         "humidity"  : humidAvg,
                         "door"      : doorOpen});
        }
        else if (doorOpen == _prevDoorState) {
            server.log("Door state unchanged. Not sending IoT event. doorOpen=" + doorOpen);
        }

        // send ack to device (device erases this set of readings when ack received)
        reply("OK");
    }

    /***************************************************************************************
     * _checkDoorEvent
     * Returns: string - door status
     * Parameters:
     *      lxLevel : float - a light reading
     **************************************************************************************/
    function _checkDoorEvent(lxLevel = null) {
        // Boolean if door open event occurred
        local doorOpen = (lxLevel == null || lxLevel > _lxThreshold);
        return (doorOpen) ? "open" : "closed";
    }
}

// RUNTIME
SmartFreezerDataManager();
