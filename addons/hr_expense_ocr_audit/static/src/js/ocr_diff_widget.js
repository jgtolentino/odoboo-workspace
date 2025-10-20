/** @odoo-module **/

import { Component } from "@odoo/owl";
import { registry } from "@web/core/registry";

export class OCRDiffWidget extends Component {
    setup() {
        this.diffData = this.props.value ? JSON.parse(this.props.value) : {};
    }

    renderDiff() {
        // Render JSON diff with highlighted changes
        const diffHtml = [];

        for (const [key, change] of Object.entries(this.diffData)) {
            if (change.old !== change.new) {
                diffHtml.push(`
                    <div class="diff-row">
                        <div class="diff-field"><strong>${key}</strong></div>
                        <div class="diff-old"><span class="badge badge-danger">Old:</span> ${change.old}</div>
                        <div class="diff-new"><span class="badge badge-success">New:</span> ${change.new}</div>
                    </div>
                `);
            }
        }

        return diffHtml.join('');
    }
}

OCRDiffWidget.template = "hr_expense_ocr_audit.OCRDiffWidget";

registry.category("fields").add("ocr_diff_viewer", OCRDiffWidget);
