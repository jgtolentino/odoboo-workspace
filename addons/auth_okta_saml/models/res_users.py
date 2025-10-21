# -*- coding: utf-8 -*-
from odoo import models, api, _
from odoo.exceptions import AccessDenied


class ResUsers(models.Model):
    _inherit = 'res.users'

    ALLOWED_OKTA_DOMAINS = [
        'tbwa-smp.com',
        'oomc.com',
    ]

    @api.model
    def _auth_saml_validate(self, provider_id, saml_response):
        """Override to validate allowed domains for Okta SAML"""
        validation = super(ResUsers, self)._auth_saml_validate(provider_id, saml_response)

        if validation.get('user_email'):
            email = validation.get('user_email')
            domain = email.split('@')[-1].lower() if '@' in email else ''

            if domain not in self.ALLOWED_OKTA_DOMAINS:
                raise AccessDenied(
                    _('Your email domain (@%s) is not allowed for Okta SSO. Allowed: @tbwa-smp.com, @oomc.com') % domain
                )

        return validation

    @api.model
    def _auth_saml_signin(self, provider_id, saml_response, validation):
        """Auto-create users from Okta for allowed domains"""
        email = validation.get('user_email')
        login = validation.get('user_login', email)

        user = self.search([('login', '=', login)], limit=1)

        if not user:
            # Auto-create user from Okta
            user_values = {
                'login': login,
                'name': validation.get('user_name', email.split('@')[0]),
                'email': email,
                'groups_id': [(6, 0, [self.env.ref('base.group_user').id])],
            }

            # Add optional attributes from SAML response
            if validation.get('user_phone'):
                user_values['phone'] = validation.get('user_phone')

            user = self.create(user_values)

        return user
