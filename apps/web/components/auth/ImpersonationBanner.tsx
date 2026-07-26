// ============================================================
// ImpersonationBanner.tsx
// Displays active HOD impersonation banner and revert button.
// ============================================================
import { cookies } from 'next/headers'

export default async function ImpersonationBanner() {
  const cookieStore = await cookies()
  const impersonatedUserId = cookieStore.get('psgmx_impersonated_user_id')?.value

  if (!impersonatedUserId) {
    return null
  }

  return (
    <div className="bg-amber-500 text-slate-950 px-4 py-2 text-xs font-bold flex items-center justify-between z-50 sticky top-0">
      <span>⚠️ HOD Active Impersonation Mode (Target User ID: {impersonatedUserId})</span>
      <form action="/api/super-admin/revert" method="POST">
        <button
          type="submit"
          className="bg-slate-950 text-white px-3 py-1 rounded-md text-[11px] font-semibold hover:bg-slate-800 transition-colors"
        >
          End Impersonation
        </button>
      </form>
    </div>
  )
}
