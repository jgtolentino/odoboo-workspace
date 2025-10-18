interface AppCardProps {
  app: {
    id: number;
    name: string;
    summary: string;
    icon: string;
    slug: string;
    category_id: number;
  };
  isInstalled: boolean;
}

export function AppCard({ app, isInstalled }: AppCardProps) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6 shadow-sm hover:shadow-md transition-shadow h-full flex flex-col">
      <div className="flex items-start justify-between mb-4">
        <div className="text-4xl">{app.icon || '🧩'}</div>
      </div>
      <h3 className="text-lg font-semibold text-gray-900 mb-2">{app.name}</h3>
      <p className="text-gray-600 text-sm mb-4 flex-grow">{app.summary}</p>
      {isInstalled ? (
        <button
          className="w-full rounded-lg bg-gray-600 px-4 py-3 text-white font-medium hover:bg-gray-700 transition-colors mt-auto text-sm"
          disabled
        >
          Open
        </button>
      ) : (
        <form action={`/api/install`} method="post" className="mt-auto">
          <input type="hidden" name="app_id" value={app.id} />
          <button className="w-full rounded-lg bg-purple-600 px-4 py-3 text-white font-medium hover:bg-purple-700 transition-colors text-sm">
            Install
          </button>
        </form>
      )}
    </div>
  );
}
