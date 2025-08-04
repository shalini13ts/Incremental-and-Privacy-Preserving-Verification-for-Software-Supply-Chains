const fs = require('fs');
const utils = require("ffjavascript").utils;

function processFilename(filename) {

    const lastDotIndex = filename.lastIndexOf('.');
    const name = lastDotIndex >= 0 ? filename.substring(0, lastDotIndex + 1) : '';
    const extension = lastDotIndex >= 0 ? filename.substring(lastDotIndex + 1) : filename;
    return {
        name: utils.leBuff2int(Buffer.from(name, 'utf8')),
        extension: utils.leBuff2int(Buffer.from(extension, 'utf8'))
    };
}

function processRuleName(ruleName) {
	const predefinedMap = {
	    "REQUIRE": 6,
	    "CREATE": 2,
	    "DISALLOW": 7
	  };
  	return predefinedMap[ruleName] ?? predefinedMap["default"];	
}

async function main() {
    try {
    	// Read the input json file 
    	const rawData = fs.readFileSync('Layout.json', 'utf-8');
    	
    	// Parse the JSON
	const jsonData = JSON.parse(rawData);
	
    	// Print the entire JSON object
        console.log("Input Json File Contents:");
        console.log(jsonData);
        
	
	
	let matRuleCode = [], matFileName = [];
	let proRuleCode = [], proFileName = [];
	const no_of_rules = 3;
	let name, extension;

	for (let i = 0; i < no_of_rules; i++) {
	  // Process material
	  matRuleCode[i] = processRuleName(jsonData.expected_materials[i][0]);	
	  ({ name, extension } = processFilename(jsonData.expected_materials[i][1]));
	  matFileName.push({ Name: name, Extension: extension });

	  // Process product
	  proRuleCode[i] = processRuleName(jsonData.expected_products[i][0]);	
	  ({ name, extension } = processFilename(jsonData.expected_products[i][1]));
	  proFileName.push({ Name: name, Extension: extension });
	}

	const output = {
	  layout_type: "1885697139",
	  layout_name: "448345171302",
	  expected_command: [
	    "1952802660",
	    "310460226468857111535221109522238936698792680963681856593164672904678714657507223899945748534927853856599036368585421532875942383350685373142692968"
	  ],
	  expected_materials: matRuleCode.map((code, i) => [
	    code.toString(),
	    matFileName[i].Name.toString(),
	    matFileName[i].Extension.toString()
	  ]),
	  expected_products: proRuleCode.map((code, i) => [
	    code.toString(),
	    proFileName[i].Name.toString(),
	    proFileName[i].Extension.toString()
	  ])
	};

	
	fs.writeFileSync('LayoutToInt.json', JSON.stringify(output, null, 2));
        console.log('Output generated successfully');
        
	
        
    } catch (err) {
        console.error("Error:", err);
        process.exit(1);
    }
}

main();
