const fs = require("fs");
const path = require("path");

function mergeJSONFiles(filePaths, outputFilePath = "merged.json") {
    const mergedData = {};

    filePaths.forEach((filePath) => {
        try {
            const content = fs.readFileSync(filePath, "utf-8");
            const json = JSON.parse(content);

            // Merge keys (shallow merge)
            Object.assign(mergedData, json);
        } catch (err) {
            console.error(`❌ Failed to process ${filePath}: ${err.message}`);
        }
    });

    // Write merged data
    fs.writeFileSync(outputFilePath, JSON.stringify(mergedData, null, 2));
    console.log(`✅ Merged JSON saved to ${outputFilePath}`);
}

// Read command line arguments
const args = process.argv.slice(2);

if (args.length < 2) {
    console.error("Usage: node merge-json.js <input1.json> <input2.json> ... <output.json>");
    process.exit(1);
}

const inputFiles = args.slice(0, -1);
const outputFile = args[args.length - 1];

mergeJSONFiles(inputFiles, outputFile);

