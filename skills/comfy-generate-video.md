Generate a video using Comfy Cloud based on the user's description: $ARGUMENTS

Follow these steps exactly:

1. Use `search_templates` with relevant queries like "text to video", "image to video", or "video generation" to find a pre-built video workflow template. Filter by tag "video" if the text search returns too many image results. If a good template exists, use it as the base workflow instead of building from scratch.

2. If no suitable template was found, use `search_models` to find an appropriate video model. Common video models include: LTX-Video, Wan Video, HunyuanVideo, AnimateDiff, CogVideoX. Pick the best match based on the user's description.

3. If the user provides an input image (for image-to-video), use `upload_file` to upload it first. Use the returned filename in a LoadImage node.

4. Build a ComfyUI API-format workflow JSON with the appropriate video nodes. Video workflows typically use specialized loader nodes (e.g. LTXVLoader, WanVideoModelLoader), video-specific samplers, and video output nodes (e.g. VHS_VideoCombine). If using a template, modify the prompt and settings as needed.

5. Call `submit_workflow` with the workflow JSON. Note: video generation typically takes longer than image generation (30s-2min+).

6. Poll `get_job_status` every 5 seconds until the job is completed. Show the user a brief status update while waiting. Mention that video generation takes longer than images. If the user asks to cancel, use `cancel_job` with the prompt_id.

7. Call `get_output` to retrieve the generated video. Pass a short `description` parameter (e.g. "cat running through field") so the saved file gets a descriptive name.

8. Tell the user where the video file was saved and how to view it. Video outputs are saved to disk but not previewed inline.

If any step fails, show the error clearly. Common video generation issues: model not available on cloud, insufficient GPU memory for long videos, unsupported video length.
