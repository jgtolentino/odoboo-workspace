"""Migration tool functions for Odoo → NestJS + Next.js transformation"""

import asyncio
import os
import tempfile
import zipfile
from pathlib import Path
from typing import Dict, Any, List
import httpx
import git
from bs4 import BeautifulSoup
from PIL import Image
import numpy as np
from skimage.metrics import structural_similarity as ssim
import hashlib


async def repo_fetch(repo: str, ref: str = "main") -> Dict[str, Any]:
    """
    Clone and extract Odoo module source code

    Args:
        repo: GitHub repository URL or path
        ref: Branch, tag, or commit SHA

    Returns:
        {
            "archive_url": "https://storage.url/archive.zip",
            "metadata": {
                "repo": "odoo/odoo",
                "ref": "18.0",
                "modules": ["base", "web", "account"],
                "file_count": 1234
            }
        }
    """
    try:
        # Create temporary directory
        temp_dir = tempfile.mkdtemp()

        # Clone repository
        if repo.startswith("http"):
            git_repo = git.Repo.clone_from(repo, temp_dir, branch=ref, depth=1)
        else:
            git_repo = git.Repo(repo)
            git_repo.git.checkout(ref)

        # Detect Odoo modules
        modules = []
        file_count = 0
        for root, dirs, files in os.walk(temp_dir):
            if "__manifest__.py" in files or "__openerp__.py" in files:
                module_name = Path(root).name
                modules.append(module_name)
            file_count += len(files)

        # Create archive
        archive_path = f"{temp_dir}/source.zip"
        with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(temp_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, temp_dir)
                    zipf.write(file_path, arcname)

        # TODO: Upload to storage (Supabase Storage or DO Spaces)
        # For now, return local path
        archive_url = f"file://{archive_path}"

        return {
            "archive_url": archive_url,
            "metadata": {
                "repo": repo,
                "ref": ref,
                "modules": modules,
                "file_count": file_count
            }
        }
    except Exception as e:
        raise Exception(f"repo_fetch failed: {str(e)}")


async def qweb_to_tsx(archive_url: str, theme_hint: str = None) -> Dict[str, Any]:
    """
    Convert QWeb templates to React/TSX components

    Args:
        archive_url: Source archive URL from repo_fetch
        theme_hint: Theme name for style extraction

    Returns:
        {
            "tokens_url": "https://storage.url/tokens.json",
            "pieces": [
                {
                    "type": "component",
                    "name": "KanbanView",
                    "path": "apps/web/src/components/KanbanView.tsx",
                    "size": 2048
                }
            ]
        }
    """
    try:
        # Extract archive
        temp_dir = tempfile.mkdtemp()
        archive_path = archive_url.replace("file://", "")
        with zipfile.ZipFile(archive_path, "r") as zipf:
            zipf.extractall(temp_dir)

        # Find QWeb templates
        qweb_files = []
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                if file.endswith(".xml"):
                    file_path = os.path.join(root, file)
                    with open(file_path, "r") as f:
                        content = f.read()
                        if 't-name' in content or 't-extend' in content:
                            qweb_files.append(file_path)

        # Convert QWeb directives to React
        pieces = []
        for qweb_file in qweb_files:
            with open(qweb_file, "r") as f:
                soup = BeautifulSoup(f.read(), "xml")

            # Find template name
            template = soup.find("t", {"t-name": True})
            if not template:
                continue

            template_name = template.get("t-name")

            # Convert to TSX
            tsx_content = _qweb_to_react(template)

            # Create component file
            component_name = _to_pascal_case(template_name)
            output_path = f"{temp_dir}/tsx/{component_name}.tsx"
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, "w") as f:
                f.write(tsx_content)

            pieces.append({
                "type": "component",
                "name": component_name,
                "path": f"apps/web/src/components/{component_name}.tsx",
                "size": len(tsx_content)
            })

        # Extract design tokens from SCSS
        tokens = _extract_design_tokens(temp_dir, theme_hint)
        tokens_path = f"{temp_dir}/tokens.json"
        import json
        with open(tokens_path, "w") as f:
            json.dump(tokens, f, indent=2)

        # TODO: Upload to storage
        tokens_url = f"file://{tokens_path}"

        return {
            "tokens_url": tokens_url,
            "pieces": pieces
        }
    except Exception as e:
        raise Exception(f"qweb_to_tsx failed: {str(e)}")


async def odoo_model_to_prisma(archive_url: str) -> Dict[str, Any]:
    """
    Convert Odoo Python models to Prisma schema

    Args:
        archive_url: Source archive URL

    Returns:
        {
            "prisma_url": "https://storage.url/schema.prisma",
            "models": ["User", "Partner", "Invoice"]
        }
    """
    try:
        # Extract archive
        temp_dir = tempfile.mkdtemp()
        archive_path = archive_url.replace("file://", "")
        with zipfile.ZipFile(archive_path, "r") as zipf:
            zipf.extractall(temp_dir)

        # Find Python models
        model_files = []
        for root, dirs, files in os.walk(temp_dir):
            if "models" in root:
                for file in files:
                    if file.endswith(".py"):
                        model_files.append(os.path.join(root, file))

        # Parse models and convert to Prisma
        prisma_models = []
        for model_file in model_files:
            with open(model_file, "r") as f:
                content = f.read()

            # Simple regex-based parsing (production would use AST)
            if "models.Model" in content or "_inherit" in content:
                model_name = _extract_model_name(content)
                if model_name:
                    prisma_model = _python_model_to_prisma(content, model_name)
                    prisma_models.append(prisma_model)

        # Generate Prisma schema
        prisma_schema = _generate_prisma_schema(prisma_models)
        schema_path = f"{temp_dir}/schema.prisma"
        with open(schema_path, "w") as f:
            f.write(prisma_schema)

        # TODO: Upload to storage
        prisma_url = f"file://{schema_path}"

        return {
            "prisma_url": prisma_url,
            "models": [m["name"] for m in prisma_models]
        }
    except Exception as e:
        raise Exception(f"odoo_model_to_prisma failed: {str(e)}")


async def nest_scaffold(prisma_schema: str) -> Dict[str, Any]:
    """
    Generate NestJS controllers from Prisma schema

    Args:
        prisma_schema: Prisma schema content

    Returns:
        {
            "bundle_url": "https://storage.url/nest-api.zip",
            "files": ["users.controller.ts", "users.service.ts", "users.module.ts"]
        }
    """
    try:
        temp_dir = tempfile.mkdtemp()

        # Parse Prisma schema
        models = _parse_prisma_schema(prisma_schema)

        # Generate NestJS files for each model
        generated_files = []
        for model in models:
            model_name = model["name"]
            model_lower = model_name.lower()

            # Generate controller
            controller = _generate_controller(model)
            controller_path = f"{temp_dir}/src/{model_lower}/{model_lower}.controller.ts"
            os.makedirs(os.path.dirname(controller_path), exist_ok=True)
            with open(controller_path, "w") as f:
                f.write(controller)
            generated_files.append(f"{model_lower}.controller.ts")

            # Generate service
            service = _generate_service(model)
            service_path = f"{temp_dir}/src/{model_lower}/{model_lower}.service.ts"
            with open(service_path, "w") as f:
                f.write(service)
            generated_files.append(f"{model_lower}.service.ts")

            # Generate module
            module = _generate_module(model)
            module_path = f"{temp_dir}/src/{model_lower}/{model_lower}.module.ts"
            with open(module_path, "w") as f:
                f.write(module)
            generated_files.append(f"{model_lower}.module.ts")

        # Create bundle
        bundle_path = f"{temp_dir}/nest-api.zip"
        with zipfile.ZipFile(bundle_path, "w", zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(f"{temp_dir}/src"):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, temp_dir)
                    zipf.write(file_path, arcname)

        # TODO: Upload to storage
        bundle_url = f"file://{bundle_path}"

        return {
            "bundle_url": bundle_url,
            "files": generated_files
        }
    except Exception as e:
        raise Exception(f"nest_scaffold failed: {str(e)}")


async def asset_migrator(archive_url: str) -> Dict[str, Any]:
    """
    Migrate static assets with path mapping

    Args:
        archive_url: Source archive URL

    Returns:
        {
            "asset_map_url": "https://storage.url/asset-map.json",
            "assets": [
                {
                    "source": "/static/src/img/logo.png",
                    "target": "/public/images/logo.png",
                    "size": 4096
                }
            ]
        }
    """
    try:
        # Extract archive
        temp_dir = tempfile.mkdtemp()
        archive_path = archive_url.replace("file://", "")
        with zipfile.ZipFile(archive_path, "r") as zipf:
            zipf.extractall(temp_dir)

        # Find static assets
        assets = []
        asset_extensions = {".png", ".jpg", ".jpeg", ".svg", ".gif", ".ico", ".css", ".js", ".woff", ".woff2", ".ttf"}

        for root, dirs, files in os.walk(temp_dir):
            if "static" in root:
                for file in files:
                    ext = os.path.splitext(file)[1].lower()
                    if ext in asset_extensions:
                        source_path = os.path.join(root, file)
                        rel_path = os.path.relpath(source_path, temp_dir)

                        # Map to target path
                        if "img" in rel_path or ext in {".png", ".jpg", ".jpeg", ".svg", ".gif", ".ico"}:
                            target_path = f"/public/images/{file}"
                        elif ext == ".css":
                            target_path = f"/public/styles/{file}"
                        elif ext == ".js":
                            target_path = f"/public/scripts/{file}"
                        else:
                            target_path = f"/public/fonts/{file}"

                        file_size = os.path.getsize(source_path)

                        assets.append({
                            "source": rel_path,
                            "target": target_path,
                            "size": file_size
                        })

        # Create asset map
        asset_map_path = f"{temp_dir}/asset-map.json"
        import json
        with open(asset_map_path, "w") as f:
            json.dump(assets, f, indent=2)

        # TODO: Upload to storage
        asset_map_url = f"file://{asset_map_path}"

        return {
            "asset_map_url": asset_map_url,
            "assets": assets
        }
    except Exception as e:
        raise Exception(f"asset_migrator failed: {str(e)}")


async def visual_diff(baseline_url: str, candidate_url: str) -> Dict[str, Any]:
    """
    Compare screenshots for visual parity validation

    Args:
        baseline_url: Original Odoo UI screenshot
        candidate_url: Migrated UI screenshot

    Returns:
        {
            "ssim": 0.985,
            "lpips": 0.015,
            "passes": true,
            "diff_url": "https://storage.url/diff.png"
        }
    """
    try:
        # Download images
        async with httpx.AsyncClient() as client:
            baseline_response = await client.get(baseline_url)
            candidate_response = await client.get(candidate_url)

        # Save to temp files
        temp_dir = tempfile.mkdtemp()
        baseline_path = f"{temp_dir}/baseline.png"
        candidate_path = f"{temp_dir}/candidate.png"

        with open(baseline_path, "wb") as f:
            f.write(baseline_response.content)
        with open(candidate_path, "wb") as f:
            f.write(candidate_response.content)

        # Load images
        baseline_img = Image.open(baseline_path).convert("RGB")
        candidate_img = Image.open(candidate_path).convert("RGB")

        # Resize to same dimensions
        if baseline_img.size != candidate_img.size:
            candidate_img = candidate_img.resize(baseline_img.size)

        # Convert to numpy arrays
        baseline_array = np.array(baseline_img)
        candidate_array = np.array(candidate_img)

        # Calculate SSIM
        ssim_score = ssim(
            baseline_array,
            candidate_array,
            channel_axis=2,
            data_range=255
        )

        # TODO: Calculate LPIPS (requires PyTorch + lpips library)
        lpips_score = 1.0 - ssim_score  # Placeholder

        # Check if passes threshold
        passes = ssim_score >= 0.98 and lpips_score <= 0.02

        # Generate diff image
        diff_array = np.abs(baseline_array.astype(float) - candidate_array.astype(float)).astype(np.uint8)
        diff_img = Image.fromarray(diff_array)
        diff_path = f"{temp_dir}/diff.png"
        diff_img.save(diff_path)

        # TODO: Upload to storage
        diff_url = f"file://{diff_path}"

        return {
            "ssim": round(ssim_score, 3),
            "lpips": round(lpips_score, 3),
            "passes": passes,
            "diff_url": diff_url
        }
    except Exception as e:
        raise Exception(f"visual_diff failed: {str(e)}")


async def bundle_emit(pieces: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Package all generated code into deployable bundle

    Args:
        pieces: Collection of generated components

    Returns:
        {
            "bundle_url": "https://storage.url/bundle.zip",
            "report": {
                "total_files": 42,
                "total_size": 102400,
                "components": 15,
                "services": 8
            }
        }
    """
    try:
        temp_dir = tempfile.mkdtemp()
        bundle_dir = f"{temp_dir}/bundle"
        os.makedirs(bundle_dir, exist_ok=True)

        # Organize pieces by type
        total_files = 0
        total_size = 0
        component_count = 0
        service_count = 0

        for piece in pieces:
            piece_type = piece.get("type", "unknown")
            piece_path = piece.get("path", "")
            piece_size = piece.get("size", 0)

            # Create directory structure
            target_path = os.path.join(bundle_dir, piece_path)
            os.makedirs(os.path.dirname(target_path), exist_ok=True)

            # Copy file (in real implementation, fetch from storage)
            # For now, create placeholder
            with open(target_path, "w") as f:
                f.write(f"// {piece.get('name', 'Component')}\n")

            total_files += 1
            total_size += piece_size

            if piece_type == "component":
                component_count += 1
            elif piece_type == "service":
                service_count += 1

        # Add package.json for monorepo
        package_json = {
            "name": "odoo-migration",
            "version": "1.0.0",
            "private": True,
            "workspaces": ["apps/*", "packages/*"]
        }
        import json
        with open(f"{bundle_dir}/package.json", "w") as f:
            json.dump(package_json, f, indent=2)

        # Create README
        readme = """# Odoo Migration Bundle

Generated by odoobo-expert agent.

## Structure
- `apps/api/` - NestJS backend
- `apps/web/` - Next.js frontend
- `packages/ui/` - Shared UI components

## Setup
1. Extract bundle: `unzip bundle.zip`
2. Install dependencies: `npm install`
3. Configure env: Copy `.env.example` to `.env`
4. Run migrations: `npx prisma migrate dev`
5. Start dev: `npm run dev`
"""
        with open(f"{bundle_dir}/README.md", "w") as f:
            f.write(readme)

        # Create ZIP bundle
        bundle_path = f"{temp_dir}/bundle.zip"
        with zipfile.ZipFile(bundle_path, "w", zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(bundle_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, bundle_dir)
                    zipf.write(file_path, arcname)

        # TODO: Upload to storage
        bundle_url = f"file://{bundle_path}"

        return {
            "bundle_url": bundle_url,
            "report": {
                "total_files": total_files,
                "total_size": total_size,
                "components": component_count,
                "services": service_count
            }
        }
    except Exception as e:
        raise Exception(f"bundle_emit failed: {str(e)}")


# Helper functions

def _qweb_to_react(template) -> str:
    """Convert QWeb template to React TSX"""
    # Simplified conversion (production would use proper XML parser)
    return """import React from 'react';

export const Component: React.FC = () => {
  return (
    <div className="odoo-component">
      {/* Converted from QWeb */}
    </div>
  );
};
"""


def _to_pascal_case(s: str) -> str:
    """Convert string to PascalCase"""
    return "".join(word.capitalize() for word in s.replace("_", " ").replace(".", " ").split())


def _extract_design_tokens(path: str, theme_hint: str = None) -> Dict[str, Any]:
    """Extract SCSS variables to design tokens"""
    # Simplified extraction (production would use sass parser)
    return {
        "colors": {
            "primary": "#714B67",
            "secondary": "#8f7a88"
        },
        "spacing": {
            "base": "8px",
            "sm": "4px",
            "lg": "16px"
        }
    }


def _extract_model_name(content: str) -> str:
    """Extract model name from Python code"""
    # Simplified extraction
    if "_name = " in content:
        start = content.find("_name = ") + 8
        end = content.find("\n", start)
        return content[start:end].strip().strip('"').strip("'")
    return None


def _python_model_to_prisma(content: str, model_name: str) -> Dict[str, Any]:
    """Convert Python model to Prisma model dict"""
    # Simplified conversion
    return {
        "name": _to_pascal_case(model_name),
        "fields": [
            {"name": "id", "type": "Int", "attributes": ["@id", "@default(autoincrement())"]},
            {"name": "name", "type": "String"},
            {"name": "createdAt", "type": "DateTime", "attributes": ["@default(now())"]}
        ]
    }


def _generate_prisma_schema(models: List[Dict[str, Any]]) -> str:
    """Generate complete Prisma schema"""
    schema = """generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

"""
    for model in models:
        schema += f"model {model['name']} {{\n"
        for field in model["fields"]:
            attrs = " " + " ".join(field.get("attributes", [])) if field.get("attributes") else ""
            schema += f"  {field['name']} {field['type']}{attrs}\n"
        schema += "}\n\n"

    return schema


def _parse_prisma_schema(schema: str) -> List[Dict[str, Any]]:
    """Parse Prisma schema to model dicts"""
    # Simplified parsing
    models = []
    for line in schema.split("\n"):
        if line.startswith("model "):
            model_name = line.split()[1]
            models.append({"name": model_name})
    return models


def _generate_controller(model: Dict[str, Any]) -> str:
    """Generate NestJS controller"""
    model_name = model["name"]
    model_lower = model_name.lower()
    return f"""import {{ Controller, Get, Post, Body, Param }} from '@nestjs/common';
import {{ {model_name}Service }} from './{model_lower}.service';

@Controller('{model_lower}')
export class {model_name}Controller {{
  constructor(private readonly {model_lower}Service: {model_name}Service) {{}}

  @Get()
  findAll() {{
    return this.{model_lower}Service.findAll();
  }}

  @Get(':id')
  findOne(@Param('id') id: string) {{
    return this.{model_lower}Service.findOne(+id);
  }}

  @Post()
  create(@Body() data: any) {{
    return this.{model_lower}Service.create(data);
  }}
}}
"""


def _generate_service(model: Dict[str, Any]) -> str:
    """Generate NestJS service"""
    model_name = model["name"]
    model_lower = model_name.lower()
    return f"""import {{ Injectable }} from '@nestjs/common';
import {{ PrismaService }} from '../prisma/prisma.service';

@Injectable()
export class {model_name}Service {{
  constructor(private prisma: PrismaService) {{}}

  async findAll() {{
    return this.prisma.{model_lower}.findMany();
  }}

  async findOne(id: number) {{
    return this.prisma.{model_lower}.findUnique({{ where: {{ id }} }});
  }}

  async create(data: any) {{
    return this.prisma.{model_lower}.create({{ data }});
  }}
}}
"""


def _generate_module(model: Dict[str, Any]) -> str:
    """Generate NestJS module"""
    model_name = model["name"]
    model_lower = model_name.lower()
    return f"""import {{ Module }} from '@nestjs/common';
import {{ {model_name}Controller }} from './{model_lower}.controller';
import {{ {model_name}Service }} from './{model_lower}.service';

@Module({{
  controllers: [{model_name}Controller],
  providers: [{model_name}Service],
  exports: [{model_name}Service],
}})
export class {model_name}Module {{}}
"""
