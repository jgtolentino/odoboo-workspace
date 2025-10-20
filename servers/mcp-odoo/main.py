#!/usr/bin/env python3

"""
MCP Server: Odoo RPC

Provides tools for querying and managing Odoo via XML-RPC
Works natively in Claude Desktop/Cursor via MCP protocol
"""

import os
import sys
import json
import xmlrpc.client
from typing import Any, Dict, List

# Environment variables
ODOO_URL = os.getenv("ODOO_URL", "https://insightpulseai.net")
ODOO_DB = os.getenv("ODOO_DB", "odoboo_prod")
ODOO_USER = os.getenv("ODOO_USER")
ODOO_PWD = os.getenv("ODOO_PWD")

# Initialize Odoo connection
common = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common")
uid = None


def authenticate():
    """Authenticate with Odoo"""
    global uid
    if uid is None:
        uid = common.authenticate(ODOO_DB, ODOO_USER, ODOO_PWD, {})
        if not uid:
            raise Exception("Odoo authentication failed")
    return uid


def search_read(model: str, domain: List, fields: List[str], limit: int = 80) -> List[Dict]:
    """Search and read records from Odoo model"""
    authenticate()
    models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object")
    result = models.execute_kw(
        ODOO_DB, uid, ODOO_PWD,
        model, 'search_read',
        [domain],
        {'fields': fields, 'limit': limit}
    )
    return result


def call_kw(model: str, method: str, args: List = None, kwargs: Dict = None) -> Any:
    """Call any Odoo model method"""
    authenticate()
    models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object")
    args = args or []
    kwargs = kwargs or {}
    result = models.execute_kw(
        ODOO_DB, uid, ODOO_PWD,
        model, method,
        args, kwargs
    )
    return result


def list_tools():
    """List available MCP tools"""
    return {
        "tools": [
            {
                "name": "search_read",
                "description": "Search and read records from any Odoo model",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "model": {
                            "type": "string",
                            "description": "Odoo model name (e.g., 'res.partner', 'hr.expense', 'project.task')"
                        },
                        "domain": {
                            "type": "array",
                            "description": "Search domain (e.g., [['name', 'ilike', 'test']])",
                            "items": {"type": "array"}
                        },
                        "fields": {
                            "type": "array",
                            "description": "Fields to return (e.g., ['id', 'name', 'email'])",
                            "items": {"type": "string"}
                        },
                        "limit": {
                            "type": "integer",
                            "description": "Maximum number of records (default: 80)",
                            "default": 80
                        }
                    },
                    "required": ["model", "domain", "fields"]
                }
            },
            {
                "name": "call_kw",
                "description": "Call any Odoo model method (write operations require admin token)",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "model": {
                            "type": "string",
                            "description": "Odoo model name"
                        },
                        "method": {
                            "type": "string",
                            "description": "Method name (e.g., 'create', 'write', 'unlink', custom methods)"
                        },
                        "args": {
                            "type": "array",
                            "description": "Positional arguments for the method",
                            "items": {}
                        },
                        "kwargs": {
                            "type": "object",
                            "description": "Keyword arguments for the method"
                        }
                    },
                    "required": ["model", "method"]
                }
            },
            {
                "name": "get_model_fields",
                "description": "Get field definitions for an Odoo model",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "model": {
                            "type": "string",
                            "description": "Odoo model name"
                        }
                    },
                    "required": ["model"]
                }
            }
        ]
    }


def call_tool(name: str, arguments: Dict) -> Dict:
    """Handle MCP tool call"""
    try:
        if name == "search_read":
            model = arguments.get("model")
            domain = arguments.get("domain", [])
            fields = arguments.get("fields", ["id", "name"])
            limit = arguments.get("limit", 80)

            result = search_read(model, domain, fields, limit)

            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(result, indent=2, default=str)
                    }
                ]
            }

        elif name == "call_kw":
            model = arguments.get("model")
            method = arguments.get("method")
            args = arguments.get("args", [])
            kwargs = arguments.get("kwargs", {})

            result = call_kw(model, method, args, kwargs)

            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(result, indent=2, default=str)
                    }
                ]
            }

        elif name == "get_model_fields":
            model = arguments.get("model")

            result = call_kw("ir.model.fields", "search_read", [
                [("model", "=", model)]
            ], {
                "fields": ["name", "field_description", "ttype", "required", "readonly"]
            })

            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(result, indent=2, default=str)
                    }
                ]
            }

        else:
            raise Exception(f"Unknown tool: {name}")

    except Exception as e:
        return {
            "content": [
                {
                    "type": "text",
                    "text": f"Error: {str(e)}"
                }
            ],
            "isError": True
        }


def main():
    """MCP stdio protocol handler"""
    for line in sys.stdin:
        try:
            request = json.loads(line)
            method = request.get("method")
            params = request.get("params", {})

            if method == "tools/list":
                response = list_tools()
            elif method == "tools/call":
                name = params.get("name")
                arguments = params.get("arguments", {})
                response = call_tool(name, arguments)
            else:
                response = {"error": f"Unknown method: {method}"}

            print(json.dumps(response), flush=True)

        except Exception as e:
            print(json.dumps({"error": str(e)}), flush=True)


if __name__ == "__main__":
    # Check required environment variables
    if not ODOO_USER or not ODOO_PWD:
        print("Error: ODOO_USER and ODOO_PWD environment variables required", file=sys.stderr)
        sys.exit(1)

    print(f"Odoo MCP server starting (URL: {ODOO_URL}, DB: {ODOO_DB})", file=sys.stderr)
    main()
