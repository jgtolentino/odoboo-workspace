# -*- coding: utf-8 -*-
from odoo import models, api, _
from odoo.exceptions import AccessDenied


class ResUsers(models.Model):
    _inherit = 'res.users'

    ALLOWED_GOOGLE_DOMAINS = [
        'gmail.com',
    ]

    @api.model
    def _auth_oauth_validate(self, provider, access_token):
        """Override to validate allowed domains for Google OAuth"""
        validation = super(ResUsers, self)._auth_oauth_validate(provider, access_token)

        if provider == 'google' and validation.get('email'):
            email = validation.get('email')
            domain = email.split('@')[-1].lower() if '@' in email else ''

            if domain not in self.ALLOWED_GOOGLE_DOMAINS:
                raise AccessDenied(
                    _('Only @gmail.com is allowed for Google sign-in. For @tbwa-smp.com or @oomc.com, please use Magic Link authentication.')
                )

        return validation

    @api.model
    def _generate_signup_values(self, provider, validation, params):
        """Auto-create users for allowed Google OAuth domains"""
        values = super(ResUsers, self)._generate_signup_values(provider, validation, params)

        if provider == 'google':
            # Set default groups for new OAuth users
            values['groups_id'] = [(6, 0, [self.env.ref('base.group_user').id])]

        return values
