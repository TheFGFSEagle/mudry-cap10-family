var smokeColors = [
	{
		name: "white",
		rgb: [1, 1, 1]
	},
	{
		name: "red",
		rgb: [1, 0, 0]
	},
	{
		name: "orange",
		rgb: [1, 0.5, 0]
	},
	{
		name: "yellow",
		rgb: [1, 1, 0]
	},
	{
		name: "green",
		rgb: [0, 1, 0]
	},
	{
		name: "blue",
		rgb: [0, 0, 1]
	},
	{
		name: "black",
		rgb: [0, 0, 0]
	},
];

var decodeSmokeColor = func (rootNode) {
	var color = rootNode.getValue("controls/switches/smoke-color");
	rootNode.setValue("sim/model/smoke/red", smokeColors[color]["rgb"][0] * 0.8);
	rootNode.setValue("sim/model/smoke/green", smokeColors[color]["rgb"][1] * 0.8);
	rootNode.setValue("sim/model/smoke/blue", smokeColors[color]["rgb"][2] * 0.8);
	
	return smokeColors[color]["name"];
}

