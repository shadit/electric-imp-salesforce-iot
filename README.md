# electric-imp-salesforce-iot
### Build a Salesforce IoT Cloud Integration with Electric Imp!

Implements an [Electric Imp Agent](https://electricimp.com/docs/api/agent/) for the [Environmental Sensor Tail](https://connect.electricimp.com/partners/salesforcetrailhead) that sends events to [Salesforce IoT Cloud](https://www.salesforce.com/iot-cloud/).

When using [the IoT Cloud Agent](https://raw.githubusercontent.com/shadit/electric-imp-salesforce-iot/master/SmartFreezer_IoT.agent.nut), be sure to update the INPUT_CONN_URL and BEARER_TOKEN with values from your Input Connection.

You can use the [event](https://raw.githubusercontent.com/shadit/electric-imp-salesforce-iot/master/Freezer_Event.json) and [context](https://raw.githubusercontent.com/shadit/electric-imp-salesforce-iot/master/Freezer_Context.json) data JSON files to configure IoT Cloud.

## References
* [Build an IoT Integration with Electric Imp](https://trailhead.salesforce.com/projects/workshop-electric-imp) - Salesforce Trailhead project that provides the context and background information for this project. Shows how to implement an integration between Electric Imp and Service Cloud.
* [Salesforce Smart Refridgerator](https://github.com/electricimp/Salesforce/blob/master/examples/SmartRefrigerator/README.md) - Agent and Device code for both the Explorer Kit and Environmental Sensor Tail. The [IoT Cloud Agent](https://raw.githubusercontent.com/shadit/electric-imp-salesforce-iot/master/SmartFreezer_IoT.agent.nut) was developed using their code as a starting point.
  * Salesforce API integration and event handling code was removed (now handled by IoT Cloud)
  * IoT Cloud event sending code was added

## IoT Cloud Freezer Orchestration
![Freezer Door Orchestration](https://drive.google.com/uc?id=0B7gGv9loYAQ3blBoV1RBXzZ5Z2s)
