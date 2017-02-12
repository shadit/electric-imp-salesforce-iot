# electric-imp-salesforce-iot
Build a Salesforce IoT Cloud Integration with Electric Imp

Implements an [Electric Imp Agent](https://raw.githubusercontent.com/shadit/electric-imp-salesforce-iot/master/SmartFreezer_IoT.agent.nut) for the Environmental Sensor Tail that sends events to Salesforce IoT Cloud.

In order to use the Agent, update the INPUT_CONN_URL and BEARER_KEY with values from your Input Connection.

You can use the [event](https://raw.githubusercontent.com/shadit/electric-imp-salesforce-iot/master/Freezer_Event.json) and [context](https://raw.githubusercontent.com/shadit/electric-imp-salesforce-iot/master/Freezer_Context.json) data JSON files to automatically configure IoT Cloud.

## References
* [Build an IoT Integration with Electric Imp](https://trailhead.salesforce.com/projects/workshop-electric-imp) - Salesforce Trailhead module that is the basis for this project.
* [Salesforce Smart Refridgerator](https://github.com/electricimp/Salesforce/blob/master/examples/SmartRefrigerator/README.md) - Agent and Device code for both the Explorer Kit and Environmental Sensor Tail. The IoT Cloud Agent was developed using these as a starting point.
  * Salesforce API integration and event handling code was removed (now handled by IoT Cloud)
  * IoT Cloud event sending code was added
