import { Megaphone } from 'lucide-react'
import { LiveAnnouncements } from '@/components/LiveAnnouncements'

export default function FacultyAnnouncementsPage() {
  return <div className="mx-auto max-w-5xl space-y-7 pb-10"><div><h1 className="flex items-center gap-2 text-2xl font-black"><Megaphone className="h-6 w-6 text-primary-purple"/>Published announcements</h1><p className="mt-1 text-sm text-text-muted">Live notices currently visible across the batches you can access.</p></div><LiveAnnouncements audience="all-visible"/></div>
}
