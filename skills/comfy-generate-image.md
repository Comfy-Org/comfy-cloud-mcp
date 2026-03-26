Generate an image using Comfy Cloud based on the user's description: $ARGUMENTS

Follow these steps exactly:

1. Use `search_templates` to find a pre-built workflow template that matches the request (e.g. "text to image", "image to video", "style transfer", "inpainting"). If a good template exists, use it as the base workflow instead of building from scratch.

2. If no suitable template was found, use `search_models` to find an appropriate checkpoint model for the request. Pick the best match based on the user's description (e.g. realistic photo -> realistic checkpoint, anime -> anime checkpoint, SDXL for high quality).

3. If the user provides an input image (for img2img, style transfer, upscaling, etc.), use `upload_file` to upload it to Comfy Cloud first. Use the returned filename in a LoadImage node.

4. Build a ComfyUI API-format workflow JSON with the appropriate nodes (or use the template workflow). A standard text-to-image workflow uses: CheckpointLoaderSimple, CLIPTextEncode (positive and negative prompts), EmptyLatentImage, KSampler, VAEDecode, SaveImage. For img2img, replace EmptyLatentImage with LoadImage + VAEEncode.

5. Call `submit_workflow` with the workflow JSON.

6. Poll `get_job_status` every 3 seconds until the job is completed. Show the user a brief status update while waiting. If the user asks to cancel, use `cancel_job` with the prompt_id.

7. Call `get_output` to retrieve the generated image. Pass a short `description` parameter (e.g. "cat astronaut in space") so the saved file gets a descriptive name, and set `auto_open: true` to open the file automatically. The response includes base64 image data and a saved file path.

8. Display the image prominently to the user:
   - The `get_output` response includes an `ARTIFACT_HTML:` block with ready-to-use HTML. You MUST create an HTML artifact using that exact HTML content so the image appears in the side panel. Do not skip this step.
   - Also tell the user where the full-resolution file was saved on disk.
   - In terminal environments, open the saved file: macOS `open`, Linux `xdg-open`, Windows `start`.

If any step fails, show the error clearly and suggest what might have gone wrong (wrong model, invalid node configuration, etc.).
