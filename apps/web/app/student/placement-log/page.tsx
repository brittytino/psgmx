import { redirect } from 'next/navigation'

// Historical bookmarks now land on the faculty-reviewed pattern library.
// Official placement drives remain exclusively in NEO PAT.
export default function LegacyPlacementLogPage() {
  redirect('/student/interview-patterns')
}
