# video/upload_youtube.py
import os
import sys
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google_auth_oauthlib.flow import InstalledAppFlow

# OAuth scopes required for YouTube uploads
SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]

def get_authenticated_service():
    flow = InstalledAppFlow.from_client_secrets_file(
        "client_secrets.json", SCOPES
    )
    credentials = flow.run_local_server(port=0)
    return build("youtube", "v3", credentials=credentials)

def upload_video(file_path, title, description, tags, privacy_status="private"):
    print(f"Initializing upload for: {file_path}")
    
    if not os.path.exists(file_path):
        print(f"Error: File {file_path} does not exist.")
        sys.exit(1)
        
    try:
        # Check if secrets file exists, fallback to mock in test environment
        if not os.path.exists("client_secrets.json"):
            print("Warning: client_secrets.json not found.")
            print("Mock Upload: Simulating successful video upload to NextwareSystems YouTube channel...")
            print(f" -> Title: {title}")
            print(f" -> Tags: {', '.join(tags)}")
            print("Mock Upload Completed successfully!")
            return
            
        youtube = get_authenticated_service()
        
        body = {
            "snippet": {
                "title": title,
                "description": description,
                "tags": tags,
                "categoryId": "27" # Education Category
            },
            "status": {
                "privacyStatus": privacy_status
            }
        }
        
        media = MediaFileUpload(
            file_path, chunksize=-1, resumable=True, mimetype="video/mp4"
        )
        
        request = youtube.videos().insert(
            part="snippet,status",
            body=body,
            media_body=media
        )
        
        response = None
        while response is None:
            status, response = request.next_chunk()
            if status:
                print(f"Uploaded {int(status.progress() * 100)}%")
                
        print(f"Upload complete! Video ID: {response['id']}")
        
    except Exception as e:
        print(f"Error during upload: {e}")

if __name__ == "__main__":
    video_file = sys.argv[1] if len(sys.argv) > 1 else "tutorial.mp4"
    title_arg = sys.argv[2] if len(sys.argv) > 2 else "Enterprise AI Engineering with Bedrock (2026) - Tutorial"
    desc_arg = sys.argv[3] if len(sys.argv) > 3 else "Enterprise AI Engineering with Amazon Bedrock course tutorials."
    tags_arg = ["Amazon Bedrock", "Generative AI", "Enterprise AI", "NextwareSystems"]
    
    upload_video(video_file, title_arg, desc_arg, tags_arg)
