const fs = require('fs');
const utils = require("ffjavascript").utils;

function processPath(path) {
    const trimmedPath = path.trim();
    const lastSlashIndex = trimmedPath.lastIndexOf('/');
    const dir = lastSlashIndex >= 0 ? trimmedPath.substring(0, lastSlashIndex + 1) : '';
    const filename = lastSlashIndex >= 0 ? trimmedPath.substring(lastSlashIndex + 1) : trimmedPath;
    return { dir, filename };
}


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
    	const rawData = fs.readFileSync('LinkMetadata.json', 'utf-8');
    	
    	// Parse the JSON
	const jsonData = JSON.parse(rawData);
	
    	// Print the entire JSON object
        //console.log("Input Json File Contents:");
        //console.log(jsonData);
        
	
	
	
	
	let dir, filename, name, extension, material = [], product = [], matDirIntVal = [], proDirIntVal = [];
	let matFileName = [], proFileName = [];
	let matHashes = [], proHashes = [];
	
	const MAX_ARTIFACTS = 5;
	const no_of_materials = jsonData.materials_Count;
	const no_of_products = jsonData.products_Count;
	
	
	
	for (let i = 0; i < no_of_materials; i++) {
		({ dir, filename } = processPath(jsonData.link_materials[i].Artifact));
		material.push({ Dir: dir, Filename: filename });
		matDirIntVal[i] = utils.leBuff2int(Buffer.from(material[i].Dir, 'utf8'));
		({ name, extension } = processFilename(material[i].Filename));
		matFileName.push({ Name: name, Extension: extension });
		matHashes[i] = utils.leBuff2int(Buffer.from(jsonData.link_materials[i].sha256, 'utf8'));
	}
	
	for (let i = no_of_materials; i < MAX_ARTIFACTS; i++) {
		matDirIntVal[i] = 0;
		matFileName.push({ Name: "0", Extension: "0" });
		matHashes[i] = "0";
	}
	
	for (let i = 0; i < no_of_products; i++) {
		({ dir, filename } = processPath(jsonData.link_products[i].Artifact));
		product.push({ Dir: dir, Filename: filename });
		proDirIntVal[i] = utils.leBuff2int(Buffer.from(product[i].Dir, 'utf8'));
		({ name, extension } = processFilename(product[i].Filename));
		proFileName.push({ Name: name, Extension: extension });
		proHashes[i] = utils.leBuff2int(Buffer.from(jsonData.link_products[i].sha256, 'utf8'));
	}
	
	for (let i = no_of_products; i < MAX_ARTIFACTS; i++) {
		proDirIntVal[i] = 0;
		proFileName.push({ Name: "0", Extension: "0" });
		proHashes[i] = "0";
	}
	
	

	const output = {
		  link_type: "1802398060",
		  link_name: "448345171302",
		  link_command: [
		      "1952802660",
		      "310460226468857111535221109522238936698792680963681856593164672904678714657507223899945748534927853856599036368585421532875942383350685373142692968"
		  ],
		  materials_Count: no_of_materials.toString(),
		  link_materials: matDirIntVal.map((dirValue, i) => [
		    dirValue.toString(),
		    matFileName[i].Name.toString(),
		    matFileName[i].Extension.toString(),
		    matHashes[i].toString()
		  ]),
		 products_Count:  no_of_products.toString(),
		 link_products: proDirIntVal.map((dirValue, i) => [
		    dirValue.toString(),
		    proFileName[i].Name.toString(),
		    proFileName[i].Extension.toString(),
		    proHashes[i].toString()
		  ])
	};

	
	fs.writeFileSync('LinkToInt.json', JSON.stringify(output, null, 2));
        console.log('Output generated successfully');
        
	
        
    } catch (err) {
        console.error("Error:", err);
        process.exit(1);
    }
}

main();
