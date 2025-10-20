# -*- coding: utf-8 -*-
import logging
from odoo import models, api

_logger = logging.getLogger(__name__)

class ResPartner(models.Model):
    _inherit = 'res.partner'
    
    @api.model
    def sync_to_supabase(self):
        """Sync all partners/customers to Supabase"""
        client = self.env['supabase.sync'].get_supabase_client()
        
        partners = self.search([])
        synced_count = 0
        
        for partner in partners:
            try:
                data = {
                    'odoo_id': partner.id,
                    'name': partner.name or '',
                    'email': partner.email or '',
                    'phone': partner.phone or '',
                    'mobile': partner.mobile or '',
                    'street': partner.street or '',
                    'city': partner.city or '',
                    'zip': partner.zip or '',
                    'country': partner.country_id.name if partner.country_id else '',
                    'is_company': partner.is_company,
                    'vat': partner.vat or '',
                    'website': partner.website or '',
                }
                
                # Upsert to Supabase
                client.table('res_partner').upsert(data, on_conflict='odoo_id').execute()
                synced_count += 1
                
            except Exception as e:
                _logger.error(f"Error syncing partner {partner.id}: {e}")
                continue
        
        _logger.info(f"Synced {synced_count}/{len(partners)} partners to Supabase")
        return synced_count
