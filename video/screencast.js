// video/screencast.js
const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
  console.log("Starting automated browser screencast...");
  
  // Ensure output directory exists
  const framesDir = path.join(__dirname, 'frames');
  if (!fs.existsSync(framesDir)) {
    fs.mkdirSync(framesDir);
  }

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 720 });

  // Navigate to Next.js local frontend
  console.log("Navigating to application frontend...");
  try {
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle2' });
  } catch (e) {
    console.log("Warning: Local server not running. Recording mock page interface instead.");
    // Load a basic mock UI to ensure the script runs cleanly without failure
    await page.setContent(`
      <html>
        <head>
          <style>
            body { background-color: #030712; color: white; font-family: sans-serif; display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .container { border: 1px dashed #1f2937; padding: 2rem; border-radius: 0.75rem; text-align: center; }
            h1 { color: #3b82f6; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>Enterprise AI Engineering with Amazon Bedrock (2026)</h1>
            <p>Automated Video Screencast Simulator</p>
            <p id="status">Ready...</p>
          </div>
        </body>
      </html>
    `);
  }

  // Record 30 frames (simulating an interaction sequence)
  for (let i = 1; i <= 30; i++) {
    // Update interface state text to simulate visual progress
    await page.evaluate((step) => {
      const status = document.getElementById('status');
      if (status) {
        if (step < 10) status.innerText = `Step ${step}: Sending query to model...`;
        else if (step < 20) status.innerText = `Step ${step}: Guardrail evaluated successfully.`;
        else status.innerText = `Step ${step}: Output finalized.`;
      }
    }, i);

    const framePath = path.join(framesDir, `frame_${String(i).padStart(3, '0')}.png`);
    await page.screenshot({ path: framePath });
    process.stdout.write(`Captured frame ${i}/30\r`);
    await new Promise(r => setTimeout(r, 100)); // 100ms delay
  }

  console.log("\nFrames successfully saved to video/frames/");
  await browser.close();
})();
