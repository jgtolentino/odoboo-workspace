# -*- coding: utf-8 -*-
from odoo import models, fields, api, _
from odoo.exceptions import ValidationError


class ResUsers(models.Model):
    _inherit = 'res.users'

    # Allowed email domains for magic link authentication
    ALLOWED_DOMAINS = [
        'tbwa-smp.com',
        'oomc.com',
        'gmail.com',
    ]

    @api.model
    def _check_email_domain(self, email):
        """Check if email domain is allowed for magic link authentication"""
        if not email:
            return False

        domain = email.split('@')[-1].lower() if '@' in email else ''
        return domain in self.ALLOWED_DOMAINS

    @api.model
    def create_magic_link_user(self, email, name=None):
        """Create a new user for magic link authentication if they don't exist"""
        if not self._check_email_domain(email):
            raise ValidationError(
                _('Email domain not allowed. Please use @tbwa-smp.com, @oomc.com, or @gmail.com')
            )

        user = self.search([('login', '=', email)], limit=1)
        if not user:
            # Auto-create user for allowed domains
            user = self.create({
                'login': email,
                'name': name or email.split('@')[0],
                'email': email,
                'groups_id': [(6, 0, [self.env.ref('base.group_user').id])],
            })

        return user
