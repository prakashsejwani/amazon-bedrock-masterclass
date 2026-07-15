# Quiz - Lesson 007: Bedrock Runtime API (`InvokeModel` & Streaming)

1. **Which API is used to stream model completions word-by-word?**
   - A) `InvokeModel`
   - B) `InvokeModelWithResponseStream`
   - C) `Converse`
   - D) `GetModelStream`

2. **Why is it important to disable buffering (e.g. `X-Accel-Buffering: no`) in your reverse proxy when streaming SSE?**
   - A) Buffering increases encryption strength
   - B) Buffering stores tokens on disk, causing latency
   - C) Buffering blocks immediate chunk transfers, forcing the client to receive the response all at once
   - D) Buffering is incompatible with HTTPS

3. **What header must be present on a rails response to initiate an SSE connection?**
   - A) `Content-Type: application/json`
   - B) `Content-Type: text/event-stream`
   - C) `Content-Type: text/html`
   - D) `Content-Type: multipart/form-data`

## Answer Key

1: B, 2: C, 3: B

---
