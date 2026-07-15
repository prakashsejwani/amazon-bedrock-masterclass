const { BedrockClient, ListFoundationModelsCommand } = require("@aws-sdk/client-bedrock");

async function listModels() {
  console.log("Initializing Amazon Bedrock control-plane client...");
  const client = new BedrockClient({ region: "us-east-1" });

  try {
    const command = new ListFoundationModelsCommand({});
    const response = await client.send(command);

    console.log("\nAvailable Foundation Models (First 15):");
    console.log("=".repeat(80));
    
    const limit = response.modelSummaries.slice(0, 15);
    limit.forEach(model => {
      console.log(`- ${model.modelName} (ID: ${model.modelId}) [Provider: ${model.providerName}]`);
    });

  } catch (error) {
    if (error.code === "MODULE_NOT_FOUND") {
      console.log("Error: @aws-sdk/client-bedrock is not installed.");
      console.log("Please run: npm install @aws-sdk/client-bedrock");
    } else {
      console.error("AWS API Error:", error.message || error);
    }
  }
}

listModels();
