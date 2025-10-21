# -*- coding: utf-8 -*-
import secrets
import hashlib
from datetime import datetime, timedelta
from odoo import models, fields, api, _
from odoo.exceptions import ValidationError


class MagicLinkToken(models.Model):
    _name = 'auth.magic.link.token'
    _description = 'Magic Link Authentication Token'
    _rec_name = 'user_id'

    user_id = fields.Many2one('res.users', string='User', required=True, ondelete='cascade')
    token = fields.Char(string='Token', required=True, index=True)
    expires_at = fields.Datetime(string='Expires At', required=True)
    used = fields.Boolean(string='Used', default=False)
    ip_address = fields.Char(string='IP Address')
    user_agent = fields.Char(string='User Agent')

    @api.model
    def generate_magic_link(self, email):
        """Generate a magic link for the given email address"""
        user = self.env['res.users'].search([('login', '=', email)], limit=1)
        if not user:
            raise ValidationError(_('No user found with email: %s') % email)

        # Generate secure token
        token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token.encode()).hexdigest()

        # Create token record
        expires_at = datetime.now() + timedelta(minutes=15)
        self.create({
            'user_id': user.id,
            'token': token_hash,
            'expires_at': expires_at,
        })

        # Send email with magic link
        base_url = self.env['ir.config_parameter'].sudo().get_param('web.base.url')
        magic_link = f"{base_url}/auth/magic-link/{token}"

        template = self.env.ref('auth_magic_link.magic_link_email_template')
        template.with_context(magic_link=magic_link).send_mail(user.id, force_send=True)

        return True

    @api.model
    def validate_token(self, token):
        """Validate the magic link token and return user if valid"""
        token_hash = hashlib.sha256(token.encode()).hexdigest()

        token_record = self.search([
            ('token', '=', token_hash),
            ('used', '=', False),
            ('expires_at', '>', fields.Datetime.now())
        ], limit=1)

        if not token_record:
            return False

        # Mark token as used
        token_record.write({'used': True})

        return token_record.user_id

    @api.model
    def cleanup_expired_tokens(self):
        """Cron job to clean up expired tokens"""
        expired_tokens = self.search([
            ('expires_at', '<', fields.Datetime.now())
        ])
        expired_tokens.unlink()
        return True
