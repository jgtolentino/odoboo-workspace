# Design Tokens Skill

Extract and analyze design tokens from websites for design system documentation and consistency.

## Capability

- CSS variable extraction
- Tailwind config parsing
- Design token normalization
- Token comparison across sites

## Parameters

- `url` (string): Target website URL
- `categories` (list): Token categories to extract (colors, spacing, typography)
- `output_format` (string): json, css, scss (default: json)

## Usage

```python
from extract_tokens import DesignTokenExtractor

async with DesignTokenExtractor() as extractor:
    tokens = await extractor.extract(
        url="https://example.com",
        categories=["colors", "spacing"]
    )
    print(tokens['colors'])
```

## Dependencies

- playwright
- beautifulsoup4
- cssutils
