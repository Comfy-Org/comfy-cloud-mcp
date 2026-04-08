Generate audio using Comfy Cloud based on the user's description: $ARGUMENTS

Follow these steps exactly:

1. Use `search_templates` with queries like "audio generation", "text to audio", "music generation", or "sound effects" and set `media_type` to "audio" to find a pre-built audio workflow template. If a good template exists, use it as the base workflow instead of building from scratch.

2. If no suitable template was found, use `search_nodes` to find audio-related nodes. Search for "audio" to discover available audio generation and processing nodes. Use `search_models` to find audio models if needed.

3. Build a ComfyUI API-format workflow JSON with the appropriate audio nodes. Audio workflows vary depending on the task (music generation, sound effects, text-to-speech, etc.) and available nodes.

4. Call `submit_workflow` with the workflow JSON.

5. Poll `get_job_status` every 5 seconds until the job is completed. Show the user a brief status update while waiting. If the user asks to cancel, use `cancel_job` with the prompt_id.

6. Call `get_output` to retrieve the generated audio. Pass a short `description` parameter (e.g. "ambient forest sounds") so the saved file gets a descriptive name.

7. Tell the user where the audio file was saved and how to play it. Audio outputs are saved to disk but not previewed inline.

If any step fails, show the error clearly. Audio generation support in ComfyUI is newer than image generation, so fewer templates and models may be available.
