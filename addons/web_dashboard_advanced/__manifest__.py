# Copyright 2025 Your Name
# License AGPL-3.0 or later (http://www.gnu.org/licenses/agpl).

{
    "name": "Advanced Web Dashboard",
    "version": "18.0.1.0.0",
    "category": "Reporting",
    "summary": "Draxlr-style interactive dashboards with drag-and-drop builder",
    "author": "Your Name, Odoo Community Association (OCA)",
    "website": "https://github.com/OCA/web",
    "license": "AGPL-3",
    "depends": [
        "web",
        "mail",
    ],
    "data": [
        "security/ir.model.access.csv",
        "views/dashboard_views.xml",
        "views/menu_views.xml",
    ],
    "installable": True,
    "application": True,
    "auto_install": False,
    "external_dependencies": {
        "python": [],
    },
}
