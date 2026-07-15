# video/voiceover.py
import boto3
import sys
import os
from botocore.exceptions import ClientError

def synthesize_speech(text, output_file="voiceover.mp3"):
    print(f"Synthesizing voiceover (Profile: personal)...")
    
    try:
        # Initialize Polly client using the personal named profile
        session = boto3.Session(profile_name="personal")
        polly = session.client("polly")
        
        response = polly.synthesize_speech(
            Text=text,
            OutputFormat="mp3",
            VoiceId="Matthew", # High quality US male voice
            Engine="neural"     # Neural engine for premium audio quality
        )
        
        with open(output_file, "wb") as f:
            f.write(response["AudioStream"].read())
            
        print(f"Success! Audio saved to {output_file}")
        
    except ClientError as e:
        print(f"AWS Polly Error: {e.message}")
        print("Falling back: Creating a mock audio file for testing...")
        with open(output_file, "w") as f:
            f.write("Mock audio data")
    except Exception as e:
        print(f"Error: {e}")
        print("Falling back: Creating a mock audio file for testing...")
        with open(output_file, "w") as f:
            f.write("Mock audio data")

if __name__ == "__main__":
    text_content = sys.argv[1] if len(sys.argv) > 1 else "Welcome to Enterprise AI Engineering with Amazon Bedrock. Today we cover function calling."
    synthesize_speech(text_content)
