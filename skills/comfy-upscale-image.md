Upscale an image using Comfy Cloud: $ARGUMENTS

Follow these steps exactly:

1. Use `search_templates` with queries like "upscale", "super resolution", or "image upscaler" to find a pre-built upscaling workflow template. If a good template exists, use it as the base workflow instead of building from scratch.

2. If no suitable template was found, use `search_models` with type "upscale_models" to find an appropriate upscaler model. Popular options: 4x-UltraSharp (general purpose), RealESRGAN_x4plus (photorealistic), RealESRGAN_x4plus_anime_6B (anime/illustration), 4x_NMKD-Siax_200k (balanced). For 2x upscale, look for 2x models.

3. The user must provide an input image. Use `upload_file` to upload it to Comfy Cloud. Use the returned filename in a LoadImage node.

4. Build a ComfyUI API-format workflow JSON for upscaling. A standard upscale workflow uses: LoadImage → UpscaleModelLoader → ImageUpscaleWithModel → SaveImage. For higher quality results with more control, you can use a two-pass approach: upscale first, then run through img2img with a checkpoint at low denoise (0.2-0.4) to add detail.

5. Call `submit_workflow` with the workflow JSON.

6. Poll `get_job_status` every 3 seconds until the job is completed. Show the user a brief status update while waiting. If the user asks to cancel, use `cancel_job` with the prompt_id.

7. Call `get_output` to retrieve the upscaled image. Pass a short `description` parameter (e.g. "upscaled-photo") so the saved file gets a descriptive name, and set `auto_open: true`.

8. Display the result to the user. Mention the output resolution compared to the input if known.

If any step fails, show the error clearly. Common issues: input image too large for GPU memory (suggest downscaling first or using a tile-based upscaler like UltimateSDUpscale).
