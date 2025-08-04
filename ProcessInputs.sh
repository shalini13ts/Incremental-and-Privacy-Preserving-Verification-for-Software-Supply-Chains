node Assets/LayoutToInt.js
mv LayoutToInt.json Assets/
node Assets/LinkMetaToInt.js
mv LinkToInt.json Assets/
node Assets/LinkHasher.js
mv LinkWithHash.json Assets/
node Assets/LayoutHasher.js
mv LayoutWithHash.json Assets/
node Assets/Merger.js Assets/LayoutWithHash.json Assets/LinkWithHash.json CircomInput.json

