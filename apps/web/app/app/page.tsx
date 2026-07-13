'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Loader2 } from 'lucide-react'

export default function AppPage() {
  const router = useRouter()
  const [error, setError] = useState(false)

  useEffect(() => {
    async function checkRole() {
      try {
        const res = await fetch('/api/user/profile')
        if (!res.ok) {
          router.replace('/login')
          return
        }
        
        const data = await res.json()
        const roleLabel = data?.profile?.role_label?.toLowerCase() || 'student'
        
        if (roleLabel === 'faculty' || roleLabel === 'hod') {
          router.replace('/faculty')
        } else if (roleLabel === 'alumni') {
          router.replace('/alumni')
        } else {
          router.replace('/student')
        }
      } catch (err) {
        setError(true)
      }
    }
    
    checkRole()
  }, [router])

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-[#FDF8F3]">
      {!error ? (
        <div className="flex flex-col items-center gap-4 text-[#FF5A1F]">
          <Loader2 className="w-8 h-8 animate-spin" />
          <p className="text-sm font-semibold animate-pulse">Routing to your dashboard...</p>
        </div>
      ) : (
        <div className="text-red-500 font-semibold">Failed to route. Please try logging in again.</div>
      )}
    </div>
  )
}
