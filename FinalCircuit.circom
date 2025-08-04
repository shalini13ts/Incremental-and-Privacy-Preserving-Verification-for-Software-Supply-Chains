pragma circom 2.1.6;

include "circomlib/circuits/comparators.circom";
include "zkSCV-Utils.circom";
include "Rules/CREATE.circom";
include "Rules/DISALLOW.circom";
include "Rules/REQUIRE.circom";

template Main() {
    var MAX_ARTIFACTS = 5, ARTIFACT_FIELDS = 4;  // Up to 5 rows, 4 columns each
    var NO_OF_COMMANDS = 2;

    // Input signals
    signal input layout_type;
    signal input layout_name;
    signal input expected_command[NO_OF_COMMANDS];
    signal input expected_materials[3][3]; // Constant for this prototype implementtaion
    signal input expected_products[3][3];
    signal input link_type;
    signal input link_name;
    signal input link_command[NO_OF_COMMANDS];
    signal input link_materials[MAX_ARTIFACTS][ARTIFACT_FIELDS];      
    signal input materials_Count;   
    signal input link_products[MAX_ARTIFACTS][ARTIFACT_FIELDS];     
    signal input products_Count;  
    signal input LayoutHash;  
    signal input LinkHash;
    
    
    // Constants for rule IDs
    signal REQUIRE_RULE_ID <== 6;
    signal CREATE_RULE_ID <== 2;
    signal DISALLOW_RULE_ID <== 7;

    var indx = 0;
    
    // ==================   VERIFY LAYOUT HASH     ===========================
    
    component merkleTree1 = MerkleTree(6); // 2^6 = 64 leaves in total .. Pad to 64 leaves (next power of 2)
    
    merkleTree1.leaves[indx] <== layout_type; indx++;
    merkleTree1.leaves[indx] <== layout_name; indx++;
    
    for (var i = 0; i < NO_OF_COMMANDS; i++) {
    	merkleTree1.leaves[indx] <== expected_command[i]; indx++;
    }  
    
    for (var i = 0; i < 3; i++) {
    	for (var j = 0; j < 3; j++){
    		merkleTree1.leaves[indx] <== expected_materials[i][j]; indx++;
    	}
    }
    
    for (var i = 0; i < 3; i++) {
    	for (var j = 0; j < 3; j++){
    		merkleTree1.leaves[indx] <== expected_products[i][j]; indx++;
    	}
    }
    
    
    // Pad rest of the leaves with zeros
    for (var i = indx; i < 64; i++) merkleTree1.leaves[i] <== 0;
    
    // Compare computed root with given MerkleRoot which was calculated in js 
    component isEqual1 = IsEqual();
    isEqual1.in[0] <== merkleTree1.root;
    isEqual1.in[1] <== LayoutHash;
    
    signal output layouthashmatch;
    layouthashmatch <== isEqual1.out;// 1 means it's matchde else it's 0
    log("Calculated Layout Hash = ", merkleTree1.root);
    log("Layout hash matches = ", layouthashmatch);
    
    // =====================     LAYOUT HASH VERIFICATION DONE ======================
    
    
    // ==================   VERIFY LINK HASH     ===========================
    
    
    indx = 0;
    
    component merkleTree2 = MerkleTree(6); // 2^6 = 64 leaves in total .. Pad to 64 leaves (next power of 2)
    
    merkleTree2.leaves[indx] <== link_type; indx++;
    merkleTree2.leaves[indx] <== link_name; indx++;
    
    for (var i = 0; i < NO_OF_COMMANDS; i++) {
    	merkleTree2.leaves[indx] <== link_command[i]; indx++;
    }   
    
    merkleTree2.leaves[indx] <== materials_Count; indx++;

    for (var i = 0; i < MAX_ARTIFACTS; i++) {
    	for (var j = 0; j < ARTIFACT_FIELDS; j++){
    		merkleTree2.leaves[indx] <== link_materials[i][j]; indx++;
    	}
    }
    
    merkleTree2.leaves[indx] <== products_Count; indx++;
    
    for (var i = 0; i < MAX_ARTIFACTS; i++) {
    	for (var j = 0; j < ARTIFACT_FIELDS; j++){
    		merkleTree2.leaves[indx] <== link_products[i][j]; indx++;
    	}
    }
    
    // Pad rest of the leaves with zeros
    for (var i = indx; i < 64; i++) merkleTree2.leaves[i] <== 0;
    
   
    // Compare computed root with given MerkleRoot which was calculated in js 
    component isEqual2 = IsEqual();
    isEqual2.in[0] <== merkleTree2.root;
    isEqual2.in[1] <== LinkHash;
    
    signal output linkhashmatch;
    linkhashmatch <== isEqual2.out;// 1 means it's matchde else it's 0
    log("Calculated LinkHash = ", merkleTree2.root);
    log("LinkHashMatches = ", linkhashmatch);
    
    // =====================     LINK HASH VERIFICATION DONE ======================

    
    
    
    // ======================
    // Material Checks (REQUIRE only)
    // ======================
    component isMaterialRequireRule[3];
    component materialRequireChecks[3];
    signal material_results[3];
    signal materialUsedRows[3][5];        // Tracks up to 5 material rows per rule
    
    // Initialize material used rows to zero
    for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 5; j++) {
            materialUsedRows[i][j] <== 0;
        }
    }

    for (var i = 0; i < 3; i++) {
        // Check if this rule is a REQUIRE rule
        isMaterialRequireRule[i] = IsEqual();
        isMaterialRequireRule[i].in[0] <== expected_materials[i][0];
        isMaterialRequireRule[i].in[1] <== REQUIRE_RULE_ID;
        
        // REQUIRE Rule: look for expected_materials[i] in link_materials
        materialRequireChecks[i] = RequireRule(5, 3, 4, 1, 2);
        materialRequireChecks[i].expectedArtifact <== expected_materials[i];
        materialRequireChecks[i].artifacts <== link_materials;
        materialRequireChecks[i].numRows <== materials_Count;
        materialRequireChecks[i].usedRows <== materialUsedRows[i];
        
        // material_results[i] = 1 if rule applies and artifact found
        material_results[i] <==
            isMaterialRequireRule[i].out * materialRequireChecks[i].found;
    }

    // ======================
    // Product Checks (CREATE, REQUIRE, DISALLOW)
    // ======================
    signal usedProductRows[5] <== [0, 0, 0, 0, 0];
    signal usedMaterialRows[5] <== [0, 0, 0, 0, 0];
    
    component isProductCreateRule[3];
    component isProductRequireRule[3];
    component isProductDisallowRule[3];
    component productCreateChecks[3];
    component productRequireChecks[3];
    component productDisallowChecks[3];
    
    signal productCreateResults[3];
    signal productRequireResults[3];
    signal productDisallowResults[3];
    signal productFinalResults[3];
    signal tempUsedProductRows[3][5];      // Track new used rows per rule
    signal tempUsedMaterialRows[3][5];     

    for (var i = 0; i < 3; i++) {
        // Detect which rule type applies
        isProductCreateRule[i] = IsEqual();
        isProductCreateRule[i].in[0] <== expected_products[i][0];
        isProductCreateRule[i].in[1] <== CREATE_RULE_ID;
        
        isProductRequireRule[i] = IsEqual();
        isProductRequireRule[i].in[0] <== expected_products[i][0];
        isProductRequireRule[i].in[1] <== REQUIRE_RULE_ID;
        
        isProductDisallowRule[i] = IsEqual();
        isProductDisallowRule[i].in[0] <== expected_products[i][0];
        isProductDisallowRule[i].in[1] <== DISALLOW_RULE_ID;
        
        // ------ CREATE Rule ------
        productCreateChecks[i] = CreateRule(5, 3, 4, 1, 2, 5);
        productCreateChecks[i].expectedArtifact <== expected_products[i];
        productCreateChecks[i].products <== link_products;
        productCreateChecks[i].numRows <== products_Count;
        productCreateChecks[i].materials <== link_materials;
        // Use prior usedRows or global for first
        if (i == 0) {
            productCreateChecks[i].usedProductRows <== usedProductRows;
            productCreateChecks[i].usedMaterialRows <== usedMaterialRows;
        } else {
            productCreateChecks[i].usedProductRows <== tempUsedProductRows[i-1];
            productCreateChecks[i].usedMaterialRows <== tempUsedMaterialRows[i-1];
        }
        
        // ------ REQUIRE Rule ------
        productRequireChecks[i] = RequireRule(5, 3, 4, 1, 2);
        productRequireChecks[i].expectedArtifact <== expected_products[i];
        productRequireChecks[i].artifacts <== link_products;
        productRequireChecks[i].numRows <== products_Count;
        productRequireChecks[i].usedRows <== (i == 0) ? usedProductRows : tempUsedProductRows[i-1];
        
        // ------ DISALLOW Rule ------
        productDisallowChecks[i] = DisallowRule(5, 4);
        productDisallowChecks[i].artifacts <== link_products;
        productDisallowChecks[i].numRows <== products_Count;
        productDisallowChecks[i].usedRows <== (i == 0) ? usedProductRows : tempUsedProductRows[i-1];
        
        // Capture updated used rows from CREATE
        tempUsedProductRows[i] <== productCreateChecks[i].newUsedProductRows;
        tempUsedMaterialRows[i] <== productCreateChecks[i].newUsedMaterialRows;
        
        // Compute result bits
        productCreateResults[i] <== isProductCreateRule[i].out * productCreateChecks[i].result;
        productRequireResults[i] <== isProductRequireRule[i].out * productRequireChecks[i].found;
        productDisallowResults[i] <== isProductDisallowRule[i].out * productDisallowChecks[i].found;
        
        // Sum for final per-rule validity (one of them should fire)
        productFinalResults[i] <== productCreateResults[i] + productRequireResults[i] + productDisallowResults[i];
    }

    // ======================
    // Final Aggregation
    // ======================
    component andMaterial = AndReduce(3);
    component andProduct  = AndReduce(3);
    
    for (var i = 0; i < 3; i++) {
        andMaterial.in[i] <== material_results[i];
        andProduct.in[i]  <== productFinalResults[i];
    }

    // Outputs: all material & product rules must pass
    signal output materialcheck <== andMaterial.out;
    signal output productcheck  <== andProduct.out;
    signal output valid         <== andMaterial.out * andProduct.out;
    log("materialcheck = ", materialcheck);
    log("productcheck = ", productcheck);
    log("valid = ", valid);
    // valid === 1;
}

component main{public[LinkHash, LayoutHash]} = Main();


