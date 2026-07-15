#!/bin/bash
# video/stitch.sh

# Exit immediately if a command exits with a non-zero status
set -e

echo "Stitching video frames and audio track using FFmpeg..."

FRAMES_DIR="frames"
AUDIO_FILE="voiceover.mp3"
OUTPUT_FILE="tutorial.mp4"

# Check if frames exist
if [ ! -d "$FRAMES_DIR" ] || [ -z "$(ls -A "$FRAMES_DIR")" ]; then
  echo "Error: No frames found in video/frames/ directory. Run node screencast.js first."
  exit 1
fi

# Check if audio exists
if [ ! -f "$AUDIO_FILE" ]; then
  echo "Error: Audio file $AUDIO_FILE not found. Run python voiceover.py first."
  exit 1
fi

# Run FFmpeg stitch
# -framerate 10: 10 frames per second
# -i frames/frame_%03d.png: input image sequence
# -i voiceover.mp3: input audio track
# -c:v libx264: H.264 video codec
# -pix_fmt yuv420p: Pixel format required for wide player compatibility
# -c:a aac: AAC audio codec
# -shortest: Terminate encoding when the shortest input ends
ffmpeg -y -framerate 10 -i "$FRAMES_DIR/frame_%03d.png" -i "$AUDIO_FILE" -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest "$OUTPUT_FILE"

echo "Stitching completed successfully! Video file saved to video/$OUTPUT_FILE"
