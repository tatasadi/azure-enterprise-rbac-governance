#!/usr/bin/env python3
"""
RBAC Change Parser for Terraform Plans

This script parses Terraform plan JSON output and highlights RBAC-related changes
including role assignments, PIM configurations, and custom role modifications.

Usage:
    python parse-rbac-changes.py <plan.json>

Output:
    - Console output with formatted RBAC changes
    - Markdown file (rbac-changes.md) for pipeline artifacts
"""

import json
import sys
from typing import Dict, List, Any
from datetime import datetime


class RBACChangeParser:
    """Parser for RBAC-related Terraform changes"""

    # Azure built-in role GUIDs
    WELL_KNOWN_ROLES = {
        "8e3af657-a8ff-443c-a75c-2fe8c4bcb635": "Owner",
        "b24988ac-6180-42a0-ab88-20f7382dd24c": "Contributor",
        "acdd72a7-3385-48ef-bd42-f606fba81ae7": "Reader",
        "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9": "User Access Administrator",
    }

    # Resource types to monitor
    RBAC_RESOURCE_TYPES = [
        "azurerm_role_assignment",
        "azuread_group",
        "azurerm_role_definition",
        "azuread_directory_role_assignment",
    ]

    def __init__(self, plan_path: str):
        """Initialize parser with plan file path"""
        self.plan_path = plan_path
        self.changes = {
            "add": [],
            "change": [],
            "remove": [],
        }
        self.summary = {
            "total_changes": 0,
            "high_risk_changes": 0,
            "role_assignments": 0,
            "custom_roles": 0,
            "groups": 0,
        }

    def parse(self) -> None:
        """Parse the Terraform plan JSON"""
        try:
            with open(self.plan_path, 'r') as f:
                plan_data = json.load(f)
        except FileNotFoundError:
            print(f"Error: Plan file not found: {self.plan_path}")
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in plan file: {e}")
            sys.exit(1)

        # Parse resource changes
        resource_changes = plan_data.get("resource_changes", [])

        for change in resource_changes:
            resource_type = change.get("type", "")

            if resource_type in self.RBAC_RESOURCE_TYPES:
                self._process_change(change)

    def _process_change(self, change: Dict[str, Any]) -> None:
        """Process a single resource change"""
        change_type = change.get("change", {})
        actions = change_type.get("actions", [])
        resource_type = change.get("type", "")
        address = change.get("address", "")

        # Determine action type
        if "create" in actions:
            action = "add"
        elif "delete" in actions:
            action = "remove"
        elif "update" in actions:
            action = "change"
        else:
            return

        # Extract relevant information based on resource type
        change_info = {
            "action": action,
            "resource_type": resource_type,
            "address": address,
            "before": change_type.get("before", {}),
            "after": change_type.get("after", {}),
        }

        # Add to appropriate list
        self.changes[action].append(change_info)
        self.summary["total_changes"] += 1

        # Update summary counters
        if resource_type == "azurerm_role_assignment":
            self.summary["role_assignments"] += 1
            if self._is_high_risk(change_info):
                self.summary["high_risk_changes"] += 1
        elif resource_type == "azurerm_role_definition":
            self.summary["custom_roles"] += 1
        elif resource_type == "azuread_group":
            self.summary["groups"] += 1

    def _is_high_risk(self, change_info: Dict[str, Any]) -> bool:
        """Determine if a change is high-risk"""
        if change_info["resource_type"] != "azurerm_role_assignment":
            return False

        after = change_info.get("after", {})
        role_def_id = after.get("role_definition_id", "") or after.get("role_definition_name", "")

        # Check for Owner role
        if "8e3af657-a8ff-443c-a75c-2fe8c4bcb635" in str(role_def_id) or "Owner" in str(role_def_id):
            return True

        # Check for User Access Administrator
        if "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9" in str(role_def_id):
            return True

        return False

    def _get_role_name(self, role_id_or_name: str) -> str:
        """Extract friendly role name from role definition ID or name"""
        if not role_id_or_name:
            return "Unknown"

        # Check if it's a well-known GUID
        for guid, name in self.WELL_KNOWN_ROLES.items():
            if guid in role_id_or_name:
                return name

        # Extract name from path if present
        if "/roleDefinitions/" in role_id_or_name:
            parts = role_id_or_name.split("/")
            return self.WELL_KNOWN_ROLES.get(parts[-1], "Custom Role")

        return role_id_or_name

    def _format_scope(self, scope: str) -> str:
        """Format scope for readability"""
        if not scope:
            return "Unknown"

        if "/managementGroups/" in scope:
            mg_name = scope.split("/")[-1]
            return f"Management Group: {mg_name}"
        elif "/subscriptions/" in scope:
            if "/resourceGroups/" in scope:
                parts = scope.split("/")
                rg_idx = parts.index("resourceGroups") + 1
                return f"Resource Group: {parts[rg_idx]}"
            else:
                sub_id = scope.split("/")[2]
                return f"Subscription: {sub_id[:8]}..."

        return scope

    def generate_console_output(self) -> None:
        """Generate formatted console output"""
        print("\n" + "=" * 80)
        print("RBAC CHANGES DETECTED")
        print("=" * 80)
        print(f"\nTotal Changes: {self.summary['total_changes']}")
        print(f"High-Risk Changes: {self.summary['high_risk_changes']}")
        print(f"Role Assignments: {self.summary['role_assignments']}")
        print(f"Custom Roles: {self.summary['custom_roles']}")
        print(f"Entra ID Groups: {self.summary['groups']}")
        print("")

        # Display additions
        if self.changes["add"]:
            print("\n" + "-" * 80)
            print(f"➕ ADDITIONS ({len(self.changes['add'])})")
            print("-" * 80)
            for change in self.changes["add"]:
                self._print_change(change, "ADD")

        # Display modifications
        if self.changes["change"]:
            print("\n" + "-" * 80)
            print(f"🔄 MODIFICATIONS ({len(self.changes['change'])})")
            print("-" * 80)
            for change in self.changes["change"]:
                self._print_change(change, "MODIFY")

        # Display removals
        if self.changes["remove"]:
            print("\n" + "-" * 80)
            print(f"➖ REMOVALS ({len(self.changes['remove'])})")
            print("-" * 80)
            for change in self.changes["remove"]:
                self._print_change(change, "REMOVE")

        print("\n" + "=" * 80 + "\n")

    def _print_change(self, change: Dict[str, Any], action: str) -> None:
        """Print a single change"""
        resource_type = change["resource_type"]
        address = change["address"]

        print(f"\n{action}: {address}")
        print(f"Type: {resource_type}")

        if resource_type == "azurerm_role_assignment":
            after = change.get("after", {})
            before = change.get("before", {})

            if action == "REMOVE":
                role = self._get_role_name(before.get("role_definition_id", ""))
                scope = self._format_scope(before.get("scope", ""))
                principal = before.get("principal_id", "Unknown")[:8]
                print(f"  Role: {role}")
                print(f"  Scope: {scope}")
                print(f"  Principal: {principal}...")
            else:
                role = self._get_role_name(after.get("role_definition_id", "") or after.get("role_definition_name", ""))
                scope = self._format_scope(after.get("scope", ""))
                principal = after.get("principal_id", "Unknown")
                if isinstance(principal, str) and len(principal) > 16:
                    principal = principal[:8] + "..."
                print(f"  Role: {role}")
                print(f"  Scope: {scope}")
                print(f"  Principal: {principal}")

                # Highlight high-risk
                if self._is_high_risk(change):
                    print(f"  ⚠️  HIGH RISK: Privileged role assignment")

        elif resource_type == "azuread_group":
            after = change.get("after", {})
            before = change.get("before", {})

            if action == "REMOVE":
                print(f"  Group: {before.get('display_name', 'Unknown')}")
            else:
                print(f"  Group: {after.get('display_name', 'Unknown')}")
                print(f"  Description: {after.get('description', 'N/A')}")

        elif resource_type == "azurerm_role_definition":
            after = change.get("after", {})
            before = change.get("before", {})

            if action == "REMOVE":
                print(f"  Role Name: {before.get('name', 'Unknown')}")
            else:
                print(f"  Role Name: {after.get('name', 'Unknown')}")
                print(f"  Description: {after.get('description', 'N/A')}")

                actions = after.get("permissions", [{}])[0].get("actions", [])
                if actions:
                    print(f"  Actions: {len(actions)} permissions")

    def generate_markdown_report(self, output_path: str = None) -> None:
        """Generate markdown report for pipeline artifacts"""
        if output_path is None:
            output_path = "rbac-changes.md"

        with open(output_path, 'w') as f:
            f.write("# RBAC Changes Report\n\n")
            f.write(f"**Generated:** {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}  \n")
            f.write(f"**Source:** `{self.plan_path}`\n\n")

            f.write("## Summary\n\n")
            f.write(f"- **Total Changes:** {self.summary['total_changes']}\n")
            f.write(f"- **High-Risk Changes:** {self.summary['high_risk_changes']}\n")
            f.write(f"- **Role Assignments:** {self.summary['role_assignments']}\n")
            f.write(f"- **Custom Roles:** {self.summary['custom_roles']}\n")
            f.write(f"- **Entra ID Groups:** {self.summary['groups']}\n\n")

            if self.summary['high_risk_changes'] > 0:
                f.write("⚠️ **WARNING:** This plan contains high-risk changes (Owner or User Access Administrator roles)\n\n")

            # Additions
            if self.changes["add"]:
                f.write(f"## ➕ Additions ({len(self.changes['add'])})\n\n")
                for change in self.changes["add"]:
                    self._write_markdown_change(f, change, "ADD")

            # Modifications
            if self.changes["change"]:
                f.write(f"## 🔄 Modifications ({len(self.changes['change'])})\n\n")
                for change in self.changes["change"]:
                    self._write_markdown_change(f, change, "MODIFY")

            # Removals
            if self.changes["remove"]:
                f.write(f"## ➖ Removals ({len(self.changes['remove'])})\n\n")
                for change in self.changes["remove"]:
                    self._write_markdown_change(f, change, "REMOVE")

            f.write("\n---\n\n")
            f.write("**Review Checklist:**\n")
            f.write("- [ ] All changes are authorized and documented\n")
            f.write("- [ ] High-risk changes have been reviewed by security team\n")
            f.write("- [ ] Change ticket number: _______________\n")
            f.write("- [ ] Approved by: _______________\n")
            f.write("- [ ] Date: _______________\n")

        print(f"\n✓ Markdown report generated: {output_path}")

    def _write_markdown_change(self, f, change: Dict[str, Any], action: str) -> None:
        """Write a single change to markdown file"""
        resource_type = change["resource_type"]
        address = change["address"]

        f.write(f"### `{address}`\n\n")
        f.write(f"**Type:** {resource_type}  \n")

        if resource_type == "azurerm_role_assignment":
            after = change.get("after", {})
            before = change.get("before", {})

            if action == "REMOVE":
                role = self._get_role_name(before.get("role_definition_id", ""))
                scope = self._format_scope(before.get("scope", ""))
                f.write(f"**Role:** {role}  \n")
                f.write(f"**Scope:** {scope}  \n")
            else:
                role = self._get_role_name(after.get("role_definition_id", "") or after.get("role_definition_name", ""))
                scope = self._format_scope(after.get("scope", ""))
                f.write(f"**Role:** {role}  \n")
                f.write(f"**Scope:** {scope}  \n")

                if self._is_high_risk(change):
                    f.write(f"\n⚠️ **HIGH RISK:** Privileged role assignment\n")

        elif resource_type == "azuread_group":
            after = change.get("after", {})
            f.write(f"**Group Name:** {after.get('display_name', 'Unknown')}  \n")
            f.write(f"**Description:** {after.get('description', 'N/A')}  \n")

        elif resource_type == "azurerm_role_definition":
            after = change.get("after", {})
            f.write(f"**Role Name:** {after.get('name', 'Unknown')}  \n")
            f.write(f"**Description:** {after.get('description', 'N/A')}  \n")

        f.write("\n")


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python parse-rbac-changes.py <plan.json>")
        sys.exit(1)

    plan_path = sys.argv[1]

    parser = RBACChangeParser(plan_path)
    parser.parse()
    parser.generate_console_output()

    # Generate markdown report in Azure DevOps artifact staging directory
    import os
    artifact_dir = os.getenv("BUILD_ARTIFACTSTAGINGDIRECTORY", ".")
    output_path = os.path.join(artifact_dir, "rbac-changes.md")
    parser.generate_markdown_report(output_path)

    # Exit with error code if high-risk changes detected (for pipeline warnings)
    if parser.summary['high_risk_changes'] > 0:
        print("\n⚠️  WARNING: High-risk changes detected. Please review carefully.")
        # Don't exit with error - just warn
        # sys.exit(1)


if __name__ == "__main__":
    main()
