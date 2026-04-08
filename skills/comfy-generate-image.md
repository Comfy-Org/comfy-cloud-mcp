Generate an image using Comfy Cloud based on the user's description: $ARGUMENTS

Follow these steps exactly:

1. Use `search_templates` to find a pre-built workflow template that matches the request (e.g. "text to image", "image to video", "style transfer", "inpainting"). If a good template exists, use it as the base workflow instead of building from scratch.

2. If no suitable template was found, use `search_models` to find an appropriate checkpoint model for the request. Pick the best match based on the user's description (e.g. realistic photo -> realistic checkpoint, anime -> anime checkpoint, SDXL for high quality).

3. If the user provides an input image (for img2img, style transfer, upscaling, etc.), use `upload_file` to upload it to Comfy Cloud first. Use the returned filename in a LoadImage node.

4. Build a ComfyUI API-format workflow JSON with the appropriate nodes (or use the template workflow). A standard text-to-image workflow uses: CheckpointLoaderSimple, CLIPTextEncode (positive and negative prompts), EmptyLatentImage, KSampler, VAEDecode, SaveImage. For img2img, replace EmptyLatentImage with LoadImage + VAEEncode.

5. Call `submit_workflow` with the workflow JSON.

6. Poll `get_job_status` every 3 seconds until the job is completed. Show the user a brief status update while waiting. If the user asks to cancel, use `cancel_job` with the prompt_id.

7. Call `get_output` to retrieve the generated image. Pass a short `description` parameter (e.g. "cat astronaut in space") so the output gets a descriptive name.

8. Display the image to the user:
   - In **GUI environments** (Claude Desktop): the response includes an `ARTIFACT_HTML:` block — create an HTML artifact using that exact HTML so the image appears in the side panel. The file is also saved to disk.
   - In **CLI/terminal environments** (Claude Code, Cursor): the response contains a temporary signed GCS download URL, a suggested save path, and a ready-to-run `curl` command on its own line. **Execute that `curl` command verbatim** via your shell/Bash tool — do not reconstruct it from the raw URL, and do not re-quote, re-encode, or strip any query parameters. The signature lives in the query string (`X-Goog-Signature=` and related params), and any modification will invalidate the link and the download will fail. After the file is saved, open it with `open` (macOS), `xdg-open` (Linux), or `start` (Windows).

If any step fails, show the error clearly and suggest what might have gone wrong (wrong model, invalid node configuration, etc.).
