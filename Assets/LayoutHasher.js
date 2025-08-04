const circomlibjs = require("circomlibjs");
const fs = require("fs").promises;

const FIELD_PRIME = BigInt("21888242871839275222246405745257275088548364400416034343698204186575808495617");


//  Maps each integer to Cirom's modular domian Zp
function modField(x) {
  return ((BigInt(x) % FIELD_PRIME) + FIELD_PRIME) % FIELD_PRIME;
}

(async () => {
    try {
        // Initialize Poseidon once
        const poseidon = await circomlibjs.buildPoseidon();
        
        // Read and process input file
        const input = JSON.parse(await fs.readFile("./Assets/LayoutToInt.json", "utf8"));
        
        
        const leaves = [
            modField(BigInt(input.layout_type)),
            modField(BigInt(input.layout_name)),
            ...input.expected_command.map(modField),
            ...input.expected_materials.flat().map(modField),
            ...input.expected_products.flat().map(modField)
        ];
        
         
	console.log("No. of Leaves:", leaves.length);
        while (leaves.length < 64) leaves.push(0n);//Pad to 50 leaves
	console.log("Flattened Array:", leaves); 
	
        // Compute Merkle root
        let currentLevel = leaves.map(leaf => leaf.toString());
        while (currentLevel.length > 1) {
            const nextLevel = [];
            for (let i = 0; i < currentLevel.length; i += 2) {
                const hash = poseidon.F.toString(poseidon([
                    BigInt(currentLevel[i]), 
                    BigInt(currentLevel[i+1] || "0")
                ]));
                nextLevel.push(hash);
            }
            currentLevel = nextLevel;
        }

        const merkleRoot = currentLevel[0];
        console.log("Merkle Root:", merkleRoot);

        // Save to input.json
        await fs.writeFile(
            "LayoutWithHash.json",
            JSON.stringify({...input, LayoutHash: merkleRoot }, null, 2)
        );
        
    } catch (error) {
        console.error("Error:", error);
        process.exit(1);
    }
})();
