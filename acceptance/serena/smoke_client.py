#!/usr/bin/env python3

import asyncio
import os
import sys
from pathlib import Path

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


REQUIRED_TOOLS = {
    "get_symbols_overview",
    "find_symbol",
    "find_referencing_symbols",
}


def text_from_result(result) -> str:
    parts = []

    for block in result.content:
        text = getattr(block, "text", None)
        if text:
            parts.append(text)

    return "\n".join(parts)


async def call_checked(session, name: str, arguments: dict):
    result = await session.call_tool(name, arguments=arguments)

    if getattr(result, "isError", False) or getattr(result, "is_error", False):
        raise RuntimeError(
            f"{name} returned an MCP error:\n{text_from_result(result)}"
        )

    return result


async def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: smoke_client.py <serena-executable> <project-root>",
            file=sys.stderr,
        )
        return 2

    serena = Path(sys.argv[1]).resolve()
    project = Path(sys.argv[2]).resolve()

    if not serena.is_file():
        raise RuntimeError(f"Serena executable not found: {serena}")

    if not project.is_dir():
        raise RuntimeError(f"Acceptance project not found: {project}")

    server_env = os.environ.copy()

    params = StdioServerParameters(
        command=str(serena),
        args=[
            "start-mcp-server",
            "--context",
            "ide",
            "--project",
            str(project),
            "--enable-web-dashboard",
            "false",
            "--open-web-dashboard",
            "false",
        ],
        env=server_env,
    )

    print("=== MCP connection ===")

    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()

            print("[PASS] MCP session initialized")

            tools_response = await session.list_tools()
            tools = {tool.name: tool for tool in tools_response.tools}

            missing = REQUIRED_TOOLS - set(tools)

            if missing:
                raise RuntimeError(
                    "Missing required Serena tools: "
                    + ", ".join(sorted(missing))
                )

            print(
                "[PASS] Required semantic tools exposed: "
                + ", ".join(sorted(REQUIRED_TOOLS))
            )

            print()
            print("=== Tool schemas ===")

            for name in sorted(REQUIRED_TOOLS):
                tool = tools[name]
                print(f"{name}: {tool.inputSchema}")

            print()
            print("=== Symbol overview ===")

            overview = await call_checked(
                session,
                "get_symbols_overview",
                {
                    "relative_path": "calculator.py",
                    "depth": 1,
                },
            )

            overview_text = text_from_result(overview)
            print(overview_text)

            if "Calculator" not in overview_text:
                raise RuntimeError(
                    "get_symbols_overview did not discover Calculator"
                )

            print("[PASS] Calculator discovered by symbol overview")

            print()
            print("=== Symbol lookup ===")

            symbol = await call_checked(
                session,
                "find_symbol",
                {
                    "name_path_pattern": "Calculator/add",
                    "relative_path": "calculator.py",
                    "include_body": True,
                },
            )

            symbol_text = text_from_result(symbol)
            print(symbol_text)

            if "add" not in symbol_text:
                raise RuntimeError(
                    "find_symbol did not return Calculator/add"
                )

            if "return left + right" not in symbol_text:
                raise RuntimeError(
                    "find_symbol did not return the expected method body"
                )

            print("[PASS] Calculator/add resolved semantically")

            print()
            print("=== Reference lookup ===")

            references = await call_checked(
                session,
                "find_referencing_symbols",
                {
                    "name_path": "Calculator/add",
                    "relative_path": "calculator.py",
                },
            )

            references_text = text_from_result(references)
            print(references_text)

            if "service.py" not in references_text:
                raise RuntimeError(
                    "find_referencing_symbols did not discover service.py"
                )

            print("[PASS] Cross-file reference discovered")

    print()
    print("SERENA_MCP_ACCEPTANCE=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
