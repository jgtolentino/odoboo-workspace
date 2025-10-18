import { supabase } from '@/lib/supabase';
import Link from 'next/link';
import { AppCard } from '@/components/AppCard';

export default async function AppsPage({ searchParams }: { searchParams: Promise<any> }) {
  const params = await searchParams;
  const q = (params.q || '').trim();
  const cat = params.cat || 'all';

  // Get categories with app counts
  const { data: categoriesWithCounts } = await supabase
    .from('app_category')
    .select(
      `
      id,
      name,
      slug,
      app:app(count)
    `
    )
    .order('name');

  // Get installed apps for current user (placeholder user_id for now)
  const { data: installedApps } = await supabase
    .from('app_install')
    .select('app_id')
    .eq('user_id', 'demo-user-id'); // TODO: Replace with actual auth user_id

  const installedAppIds = installedApps?.map((install) => install.app_id) || [];

  let query = supabase.from('app').select('id,name,summary,icon,slug,category_id').order('name');

  if (q) query = query.ilike('name', `%${q}%`);
  if (cat !== 'all') {
    const cid = categoriesWithCounts?.find((c) => c.slug === cat)?.id;
    if (cid) query = query.eq('category_id', cid);
  }
  const { data: apps } = await query;

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-6 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Apps Catalog</h1>
          <p className="text-gray-600">Install and manage your workspace modules</p>
        </div>

        <div className="flex flex-col lg:flex-row gap-8">
          {/* sidebar */}
          <aside className="lg:w-64 flex-shrink-0">
            <div className="bg-white rounded-lg border border-gray-200 p-4 shadow-sm">
              <h2 className="text-lg font-semibold text-gray-900 mb-3">Categories</h2>
              <div className="space-y-1">
                <Link
                  href="/apps?cat=all"
                  className={`flex items-center justify-between px-3 py-2 rounded text-sm font-medium transition-colors ${
                    cat === 'all'
                      ? 'bg-purple-50 text-purple-700 border border-purple-200'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`}
                >
                  <span>All Apps</span>
                  <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-full">
                    {apps?.length || 0}
                  </span>
                </Link>
                {categoriesWithCounts?.map((c: any) => (
                  <Link
                    key={c.id}
                    href={`/apps?cat=${c.slug}`}
                    className={`flex items-center justify-between px-3 py-2 rounded text-sm font-medium transition-colors ${
                      cat === c.slug
                        ? 'bg-purple-50 text-purple-700 border border-purple-200'
                        : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                    }`}
                  >
                    <span>{c.name}</span>
                    <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-full">
                      {c.app?.[0]?.count || 0}
                    </span>
                  </Link>
                ))}
              </div>
            </div>
          </aside>

          {/* main */}
          <main className="flex-1">
            {/* Search */}
            <div className="bg-white rounded-lg border border-gray-200 p-6 shadow-sm mb-6">
              <form>
                <div className="flex gap-3">
                  <input
                    name="q"
                    placeholder="Search apps…"
                    defaultValue={q}
                    className="flex-1 rounded-lg border border-gray-300 px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                  />
                  <button
                    type="submit"
                    className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium text-sm"
                  >
                    Search
                  </button>
                </div>
              </form>
            </div>

            {/* Apps Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
              {apps?.map((a) => (
                <AppCard key={a.id} app={a} isInstalled={installedAppIds.includes(a.id)} />
              ))}
            </div>

            {apps?.length === 0 && (
              <div className="text-center py-12 bg-white rounded-lg border border-gray-200">
                <div className="text-6xl mb-4">🔍</div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">No apps found</h3>
                <p className="text-gray-600">
                  Try adjusting your search criteria or browse all categories.
                </p>
              </div>
            )}
          </main>
        </div>
      </div>
    </div>
  );
}
