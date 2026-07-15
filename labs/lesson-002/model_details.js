const { BedrockClient, GetFoundationModelCommand } = require("@aws-sdk/client-bedrock");

async function checkModel() {
  const modelId = process.argv[2] || "anthropic.claude-3-5-sonnet-20241022-v2:0";
  console.log(`Fetching details for model: ${modelId}...`);

  const client = new BedrockClient({ region: "us-east-1" });

  try {
    const command = new GetFoundationModelCommand({ modelIdentifier: modelId });
    const response = await client.send(command);

    const details = response.modelDetails;
    console.log("\nModel Details Summary:");
    console.log("=".repeat(50));
    console.log(`Name:         ${details.modelName}`);
    console.log(`ID:           ${details.modelId}`);
    console.log(`Provider:     ${details.providerName}`);
    console.log(`Input Types:  ${details.inputModalities.join(", ")}`);
    console.log(`Output Types: ${details.outputModalities.join(", ")}`);
    console.log(`Streaming:    ${details.responseStreamingSupported ? "Yes" : "No"}`);

  } catch (error) {
    if (error.name === "ValidationException") {
      console.log(`Error: Model ID "${modelId}" is not recognized or not available in this region.`);
    } else {
      console.error("AWS Error:", error.message || error);
    }
  }
}

checkModel();
