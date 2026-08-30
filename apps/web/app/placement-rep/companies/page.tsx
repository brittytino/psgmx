import { redirect } from 'next/navigation'

// PSGMX prepares students for placement; official drive management belongs to
// NEO PAT. Keep old bookmarks safe without maintaining a second drive system.
export default function LegacyCompaniesPage() {
  redirect('/student/interview-patterns')
}
