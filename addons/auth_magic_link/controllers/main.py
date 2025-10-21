# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request
from odoo.addons.web.controllers.home import Home
import werkzeug


class MagicLinkAuth(Home):

    @http.route('/auth/request-magic-link', type='json', auth='public', methods=['POST'], csrf=False)
    def request_magic_link(self, email):
        """Request a magic link to be sent to the email address"""
        try:
            request.env['auth.magic.link.token'].sudo().generate_magic_link(email)
            return {'success': True, 'message': 'Magic link sent to your email'}
        except Exception as e:
            return {'success': False, 'message': str(e)}

    @http.route('/auth/magic-link/<string:token>', type='http', auth='public', website=True)
    def magic_link_login(self, token):
        """Authenticate user via magic link token"""
        magic_token_obj = request.env['auth.magic.link.token'].sudo()
        user = magic_token_obj.validate_token(token)

        if not user:
            return request.render('auth_magic_link.magic_link_expired', {})

        # Log the user in
        request.session.authenticate(request.env.cr.dbname, user.login, user.id)

        # Redirect to home
        return werkzeug.utils.redirect('/web')

    @http.route('/auth/magic-link-form', type='http', auth='public', website=True)
    def magic_link_form(self):
        """Display the magic link request form"""
        return request.render('auth_magic_link.magic_link_request_form', {})
