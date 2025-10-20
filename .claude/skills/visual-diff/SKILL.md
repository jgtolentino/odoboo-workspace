# Visual Diff Skill

Visual regression testing and SSIM-based screenshot comparison for UI validation.

## Capability

- Screenshot capture (Playwright)
- Visual comparison (SSIM algorithm)
- Baseline management
- Regression detection

## Parameters

- `base_url` (string): Application URL
- `routes` (list): Routes to capture
- `baseline_id` (string): Baseline reference
- `threshold` (float): SSIM threshold (0.97 mobile, 0.98 desktop)

## Usage

```python
from percy_client import VisualDiffClient

async with VisualDiffClient() as client:
    result = await client.compare_screenshots(
        base_url="http://localhost:4173",
        routes=["/expenses", "/tasks"],
        threshold=0.98
    )
    print(f"SSIM: {result['ssim_score']}")
```

## Dependencies

- playwright
- pillow
- scikit-image
