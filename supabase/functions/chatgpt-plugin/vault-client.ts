// Supabase Vault Client for Secure Secret Access
// Enables Edge Functions to read secrets from Vault with caching and error handling

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface SecretCache {
  value: string
  cachedAt: number
  ttl: number
}

class VaultClient {
  private cache: Map<string, SecretCache> = new Map()
  private supabase: any
  private cacheTTL = 300000 // 5 minutes default cache TTL

  constructor(supabaseUrl: string, serviceRoleKey: string, cacheTTL?: number) {
    this.supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    if (cacheTTL) {
      this.cacheTTL = cacheTTL
    }
  }

  /**
   * Get secret from Vault with caching
   * @param secretName Name of the secret to retrieve
   * @param forceRefresh Skip cache and fetch fresh value
   * @returns Decrypted secret value
   */
  async getSecret(secretName: string, forceRefresh = false): Promise<string> {
    // Check cache first
    if (!forceRefresh) {
      const cached = this.getCachedSecret(secretName)
      if (cached) {
        console.log(`📦 Cache hit for secret: ${secretName}`)
        return cached
      }
    }

    console.log(`🔐 Fetching secret from Vault: ${secretName}`)

    try {
      // Call RPC function to get decrypted secret
      const { data, error } = await this.supabase.rpc('get_secret', {
        secret_name: secretName
      })

      if (error) {
        console.error(`❌ Vault error for ${secretName}:`, error)

        // If secret not found in Vault, fall back to env var
        const envValue = Deno.env.get(this.secretNameToEnvVar(secretName))
        if (envValue) {
          console.warn(`⚠️  Falling back to env var for ${secretName}`)
          return envValue
        }

        throw new Error(`Secret not found: ${secretName}`)
      }

      // Cache the secret
      this.setCachedSecret(secretName, data)

      // Log access for audit
      await this.logAccess(secretName, 'read', true)

      return data
    } catch (err) {
      console.error(`❌ Failed to fetch secret ${secretName}:`, err)

      // Log failed access
      await this.logAccess(secretName, 'read', false, err.message)

      throw err
    }
  }

  /**
   * Get multiple secrets in parallel
   * @param secretNames Array of secret names to retrieve
   * @returns Object mapping secret names to values
   */
  async getSecrets(secretNames: string[]): Promise<Record<string, string>> {
    const results = await Promise.allSettled(
      secretNames.map(name => this.getSecret(name))
    )

    const secrets: Record<string, string> = {}

    secretNames.forEach((name, index) => {
      const result = results[index]
      if (result.status === 'fulfilled') {
        secrets[name] = result.value
      } else {
        console.error(`❌ Failed to fetch ${name}:`, result.reason)
        // Try env var fallback
        const envValue = Deno.env.get(this.secretNameToEnvVar(name))
        if (envValue) {
          secrets[name] = envValue
        }
      }
    })

    return secrets
  }

  /**
   * Clear cache for specific secret or all secrets
   */
  clearCache(secretName?: string): void {
    if (secretName) {
      this.cache.delete(secretName)
      console.log(`🧹 Cleared cache for: ${secretName}`)
    } else {
      this.cache.clear()
      console.log(`🧹 Cleared all secret cache`)
    }
  }

  /**
   * Get cached secret if valid
   */
  private getCachedSecret(secretName: string): string | null {
    const cached = this.cache.get(secretName)
    if (!cached) return null

    const age = Date.now() - cached.cachedAt
    if (age > cached.ttl) {
      this.cache.delete(secretName)
      return null
    }

    return cached.value
  }

  /**
   * Store secret in cache
   */
  private setCachedSecret(secretName: string, value: string): void {
    this.cache.set(secretName, {
      value,
      cachedAt: Date.now(),
      ttl: this.cacheTTL
    })
  }

  /**
   * Convert secret name to environment variable name
   */
  private secretNameToEnvVar(secretName: string): string {
    return secretName.toUpperCase().replace(/-/g, '_')
  }

  /**
   * Log secret access for audit trail
   */
  private async logAccess(
    secretName: string,
    accessType: string,
    success: boolean,
    errorMessage?: string
  ): Promise<void> {
    try {
      await this.supabase
        .from('secret_access_log')
        .insert({
          secret_name: secretName,
          accessed_by: 'edge_function_chatgpt_plugin',
          access_type: accessType,
          success,
          error_message: errorMessage || null
        })
    } catch (err) {
      // Don't fail the request if audit logging fails
      console.error('⚠️  Audit logging failed:', err)
    }
  }

  /**
   * Check if secrets are about to expire (for rotation notifications)
   */
  async checkExpiringSecrets(daysThreshold = 7): Promise<string[]> {
    try {
      const { data, error } = await this.supabase.rpc('list_secret_names')

      if (error) {
        console.error('❌ Failed to list secrets:', error)
        return []
      }

      // For now, return empty array
      // In production, you'd check against rotation schedule
      return []
    } catch (err) {
      console.error('❌ Failed to check expiring secrets:', err)
      return []
    }
  }
}

// Singleton instance with lazy initialization
let vaultClient: VaultClient | null = null

/**
 * Get or create Vault client instance
 */
export function getVaultClient(): VaultClient {
  if (!vaultClient) {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('Missing required environment variables for Vault client')
    }

    vaultClient = new VaultClient(supabaseUrl, serviceRoleKey)
    console.log('✅ Vault client initialized')
  }

  return vaultClient
}

/**
 * Convenience function to get a single secret
 */
export async function getSecret(secretName: string): Promise<string> {
  const client = getVaultClient()
  return client.getSecret(secretName)
}

/**
 * Convenience function to get multiple secrets
 */
export async function getSecrets(secretNames: string[]): Promise<Record<string, string>> {
  const client = getVaultClient()
  return client.getSecrets(secretNames)
}

/**
 * Clear secret cache
 */
export function clearSecretCache(secretName?: string): void {
  if (vaultClient) {
    vaultClient.clearCache(secretName)
  }
}
