#!/usr/bin/env python3
"""
Odoo RPC Skill - Production-Ready Implementation
Interact with Odoo ERP system via XML-RPC and JSON-RPC
"""

import asyncio
import json
import logging
import os
import sys
import xmlrpc.client
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Any, List, Optional, Union
from urllib.parse import urljoin

import httpx

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Constants
SKILL_DIR = Path(__file__).parent
RESOURCES_DIR = SKILL_DIR / "resources"
DEFAULT_TIMEOUT = 30.0


@dataclass
class OdooConfig:
    """Odoo connection configuration"""
    url: str
    database: str
    username: str
    password: str
    protocol: str = "jsonrpc"  # xmlrpc or jsonrpc
    timeout: float = DEFAULT_TIMEOUT
    verify_ssl: bool = True

    def __post_init__(self):
        # Ensure URL has scheme
        if not self.url.startswith(("http://", "https://")):
            self.url = f"https://{self.url}"

        # Remove trailing slash
        self.url = self.url.rstrip("/")


class OdooRPCError(Exception):
    """Base exception for Odoo RPC errors"""
    pass


class OdooAuthenticationError(OdooRPCError):
    """Authentication failed"""
    pass


class OdooAccessError(OdooRPCError):
    """Access denied"""
    pass


class OdooValidationError(OdooRPCError):
    """Validation error"""
    pass


class OdooClient:
    """
    Async Odoo RPC client supporting both XML-RPC and JSON-RPC protocols
    """

    def __init__(
        self,
        url: str,
        database: str,
        username: str,
        password: str,
        protocol: str = "jsonrpc",
        timeout: float = DEFAULT_TIMEOUT,
        verify_ssl: bool = True
    ):
        self.config = OdooConfig(
            url=url,
            database=database,
            username=username,
            password=password,
            protocol=protocol,
            timeout=timeout,
            verify_ssl=verify_ssl
        )
        self.uid: Optional[int] = None
        self._session: Optional[httpx.AsyncClient] = None

    async def __aenter__(self):
        """Async context manager entry"""
        await self.authenticate()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        await self.close()

    async def authenticate(self) -> int:
        """
        Authenticate with Odoo server

        Returns:
            User ID (uid)

        Raises:
            OdooAuthenticationError: Authentication failed
        """
        try:
            logger.info(f"Authenticating to {self.config.url} as {self.config.username}")

            if self.config.protocol == "jsonrpc":
                self.uid = await self._jsonrpc_authenticate()
            else:
                self.uid = await self._xmlrpc_authenticate()

            if not self.uid:
                raise OdooAuthenticationError("Authentication failed - invalid credentials")

            logger.info(f"Authenticated successfully (uid: {self.uid})")
            return self.uid

        except Exception as e:
            logger.error(f"Authentication error: {str(e)}")
            raise OdooAuthenticationError(f"Authentication failed: {str(e)}")

    async def _jsonrpc_authenticate(self) -> int:
        """Authenticate using JSON-RPC"""
        payload = {
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
                "service": "common",
                "method": "authenticate",
                "args": [
                    self.config.database,
                    self.config.username,
                    self.config.password,
                    {}
                ]
            },
            "id": 1
        }

        url = urljoin(self.config.url, "/jsonrpc")
        async with httpx.AsyncClient(
            timeout=self.config.timeout,
            verify=self.config.verify_ssl
        ) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()

            if "error" in data:
                error = data["error"]
                raise OdooAuthenticationError(f"{error.get('data', {}).get('message', 'Unknown error')}")

            return data.get("result")

    async def _xmlrpc_authenticate(self) -> int:
        """Authenticate using XML-RPC (synchronous fallback)"""
        try:
            url = urljoin(self.config.url, "/xmlrpc/2/common")
            proxy = xmlrpc.client.ServerProxy(url)

            uid = proxy.authenticate(
                self.config.database,
                self.config.username,
                self.config.password,
                {}
            )
            return uid
        except Exception as e:
            raise OdooAuthenticationError(f"XML-RPC authentication failed: {str(e)}")

    async def search(
        self,
        model: str,
        domain: Optional[List] = None,
        offset: int = 0,
        limit: Optional[int] = None,
        order: Optional[str] = None
    ) -> List[int]:
        """
        Search for record IDs matching domain

        Args:
            model: Odoo model name (e.g., "res.partner")
            domain: Search domain in Odoo format
            offset: Number of records to skip
            limit: Maximum number of records
            order: Sort order (e.g., "name ASC")

        Returns:
            List of record IDs
        """
        if domain is None:
            domain = []

        kwargs = {"offset": offset}
        if limit is not None:
            kwargs["limit"] = limit
        if order:
            kwargs["order"] = order

        result = await self._execute(
            model,
            "search",
            [domain],
            kwargs
        )

        logger.info(f"Search {model}: found {len(result)} records")
        return result

    async def search_read(
        self,
        model: str,
        domain: Optional[List] = None,
        fields: Optional[List[str]] = None,
        offset: int = 0,
        limit: Optional[int] = None,
        order: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Search and read records in one call

        Args:
            model: Odoo model name
            domain: Search domain
            fields: List of fields to retrieve
            offset: Number of records to skip
            limit: Maximum number of records
            order: Sort order

        Returns:
            List of record dictionaries
        """
        if domain is None:
            domain = []
        if fields is None:
            fields = []

        kwargs = {"offset": offset}
        if limit is not None:
            kwargs["limit"] = limit
        if order:
            kwargs["order"] = order
        if fields:
            kwargs["fields"] = fields

        result = await self._execute(
            model,
            "search_read",
            [domain],
            kwargs
        )

        logger.info(f"Search_read {model}: retrieved {len(result)} records")
        return result

    async def read(
        self,
        model: str,
        ids: List[int],
        fields: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Read records by IDs

        Args:
            model: Odoo model name
            ids: List of record IDs
            fields: List of fields to retrieve (all if None)

        Returns:
            List of record dictionaries
        """
        kwargs = {}
        if fields:
            kwargs["fields"] = fields

        result = await self._execute(
            model,
            "read",
            [ids],
            kwargs
        )

        logger.info(f"Read {model}: retrieved {len(result)} records")
        return result

    async def create(
        self,
        model: str,
        values: Dict[str, Any]
    ) -> int:
        """
        Create new record

        Args:
            model: Odoo model name
            values: Field values dictionary

        Returns:
            New record ID
        """
        result = await self._execute(
            model,
            "create",
            [values]
        )

        logger.info(f"Created {model} record: {result}")
        return result

    async def write(
        self,
        model: str,
        ids: List[int],
        values: Dict[str, Any]
    ) -> bool:
        """
        Update existing records

        Args:
            model: Odoo model name
            ids: List of record IDs to update
            values: Field values to update

        Returns:
            True if successful
        """
        result = await self._execute(
            model,
            "write",
            [ids, values]
        )

        logger.info(f"Updated {model}: {len(ids)} records")
        return result

    async def unlink(
        self,
        model: str,
        ids: List[int]
    ) -> bool:
        """
        Delete records

        Args:
            model: Odoo model name
            ids: List of record IDs to delete

        Returns:
            True if successful
        """
        result = await self._execute(
            model,
            "unlink",
            [ids]
        )

        logger.info(f"Deleted {model}: {len(ids)} records")
        return result

    async def search_count(
        self,
        model: str,
        domain: Optional[List] = None
    ) -> int:
        """
        Count records matching domain

        Args:
            model: Odoo model name
            domain: Search domain

        Returns:
            Number of matching records
        """
        if domain is None:
            domain = []

        result = await self._execute(
            model,
            "search_count",
            [domain]
        )

        logger.info(f"Count {model}: {result} records")
        return result

    async def fields_get(
        self,
        model: str,
        fields: Optional[List[str]] = None,
        attributes: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Get model field definitions

        Args:
            model: Odoo model name
            fields: Specific fields to retrieve (all if None)
            attributes: Field attributes to include

        Returns:
            Dictionary of field definitions
        """
        args = []
        kwargs = {}

        if fields:
            args.append(fields)
        if attributes:
            kwargs["attributes"] = attributes

        result = await self._execute(
            model,
            "fields_get",
            args,
            kwargs
        )

        return result

    async def execute(
        self,
        model: str,
        method: str,
        ids: Optional[List[int]] = None,
        args: Optional[List] = None,
        kwargs: Optional[Dict] = None
    ) -> Any:
        """
        Execute arbitrary model method

        Args:
            model: Odoo model name
            method: Method name to execute
            ids: Record IDs (if applicable)
            args: Positional arguments
            kwargs: Keyword arguments

        Returns:
            Method result
        """
        if args is None:
            args = []
        if ids is not None:
            args = [ids] + list(args)

        result = await self._execute(model, method, args, kwargs or {})
        return result

    async def check_access_rights(
        self,
        model: str,
        operation: str = "read"
    ) -> bool:
        """
        Check if current user has access rights

        Args:
            model: Odoo model name
            operation: read, write, create, unlink

        Returns:
            True if user has access
        """
        try:
            result = await self._execute(
                model,
                "check_access_rights",
                [operation, False]
            )
            return result
        except OdooAccessError:
            return False

    async def _execute(
        self,
        model: str,
        method: str,
        args: Optional[List] = None,
        kwargs: Optional[Dict] = None
    ) -> Any:
        """
        Execute ORM method via RPC

        Args:
            model: Odoo model name
            method: Method name
            args: Positional arguments
            kwargs: Keyword arguments

        Returns:
            Method result

        Raises:
            OdooRPCError: RPC call failed
        """
        if not self.uid:
            raise OdooAuthenticationError("Not authenticated")

        if args is None:
            args = []
        if kwargs is None:
            kwargs = {}

        try:
            if self.config.protocol == "jsonrpc":
                return await self._jsonrpc_execute(model, method, args, kwargs)
            else:
                return await self._xmlrpc_execute(model, method, args, kwargs)
        except Exception as e:
            logger.error(f"RPC execute failed: {str(e)}")
            raise OdooRPCError(f"Execute {model}.{method} failed: {str(e)}")

    async def _jsonrpc_execute(
        self,
        model: str,
        method: str,
        args: List,
        kwargs: Dict
    ) -> Any:
        """Execute method via JSON-RPC"""
        payload = {
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
                "service": "object",
                "method": "execute_kw",
                "args": [
                    self.config.database,
                    self.uid,
                    self.config.password,
                    model,
                    method,
                    args,
                    kwargs
                ]
            },
            "id": 1
        }

        url = urljoin(self.config.url, "/jsonrpc")

        if not self._session:
            self._session = httpx.AsyncClient(
                timeout=self.config.timeout,
                verify=self.config.verify_ssl
            )

        response = await self._session.post(url, json=payload)
        response.raise_for_status()
        data = response.json()

        if "error" in data:
            error = data["error"]
            error_msg = error.get("data", {}).get("message", "Unknown error")

            if "access" in error_msg.lower():
                raise OdooAccessError(error_msg)
            elif "validation" in error_msg.lower():
                raise OdooValidationError(error_msg)
            else:
                raise OdooRPCError(error_msg)

        return data.get("result")

    async def _xmlrpc_execute(
        self,
        model: str,
        method: str,
        args: List,
        kwargs: Dict
    ) -> Any:
        """Execute method via XML-RPC (synchronous fallback)"""
        try:
            url = urljoin(self.config.url, "/xmlrpc/2/object")
            proxy = xmlrpc.client.ServerProxy(url)

            result = proxy.execute_kw(
                self.config.database,
                self.uid,
                self.config.password,
                model,
                method,
                args,
                kwargs
            )
            return result
        except xmlrpc.client.Fault as e:
            raise OdooRPCError(f"XML-RPC fault: {str(e)}")

    async def close(self):
        """Close HTTP session"""
        if self._session:
            await self._session.aclose()
            self._session = None


async def main():
    """CLI entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Odoo RPC Client")
    parser.add_argument("--url", default=os.getenv("ODOO_URL"), help="Odoo URL")
    parser.add_argument("--database", default=os.getenv("ODOO_DATABASE"), help="Database name")
    parser.add_argument("--username", default=os.getenv("ODOO_USERNAME"), help="Username")
    parser.add_argument("--password", default=os.getenv("ODOO_PASSWORD"), help="Password")
    parser.add_argument("--model", required=True, help="Model name")
    parser.add_argument("--operation", default="search", help="Operation: search, read, create, write, unlink")
    parser.add_argument("--domain", help="Search domain (JSON)")
    parser.add_argument("--fields", help="Fields to retrieve (comma-separated)")
    parser.add_argument("--limit", type=int, help="Result limit")
    parser.add_argument("--ids", help="Record IDs (comma-separated)")
    parser.add_argument("--values", help="Values for create/write (JSON)")

    args = parser.parse_args()

    # Validate required parameters
    if not all([args.url, args.database, args.username, args.password]):
        parser.error("Missing required Odoo connection parameters")

    try:
        async with OdooClient(
            url=args.url,
            database=args.database,
            username=args.username,
            password=args.password
        ) as client:

            if args.operation == "search":
                domain = json.loads(args.domain) if args.domain else []
                result = await client.search(
                    model=args.model,
                    domain=domain,
                    limit=args.limit
                )
                print(json.dumps(result, indent=2))

            elif args.operation == "search_read":
                domain = json.loads(args.domain) if args.domain else []
                fields = args.fields.split(",") if args.fields else None
                result = await client.search_read(
                    model=args.model,
                    domain=domain,
                    fields=fields,
                    limit=args.limit
                )
                print(json.dumps(result, indent=2))

            elif args.operation == "read":
                if not args.ids:
                    parser.error("--ids required for read operation")
                ids = [int(x) for x in args.ids.split(",")]
                fields = args.fields.split(",") if args.fields else None
                result = await client.read(
                    model=args.model,
                    ids=ids,
                    fields=fields
                )
                print(json.dumps(result, indent=2))

            elif args.operation == "create":
                if not args.values:
                    parser.error("--values required for create operation")
                values = json.loads(args.values)
                result = await client.create(
                    model=args.model,
                    values=values
                )
                print(f"Created record: {result}")

            elif args.operation == "write":
                if not args.ids or not args.values:
                    parser.error("--ids and --values required for write operation")
                ids = [int(x) for x in args.ids.split(",")]
                values = json.loads(args.values)
                result = await client.write(
                    model=args.model,
                    ids=ids,
                    values=values
                )
                print(f"Updated: {result}")

            elif args.operation == "unlink":
                if not args.ids:
                    parser.error("--ids required for unlink operation")
                ids = [int(x) for x in args.ids.split(",")]
                result = await client.unlink(
                    model=args.model,
                    ids=ids
                )
                print(f"Deleted: {result}")

            else:
                parser.error(f"Unknown operation: {args.operation}")

    except Exception as e:
        logger.error(f"Operation failed: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
