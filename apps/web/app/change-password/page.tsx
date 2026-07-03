import { Suspense } from 'react';
import ChangePasswordClient from '@/components/basic/change-password-client';

export const metadata = {
  title: 'Set Your Password — PSGMX',
};

export default function ChangePasswordPage() {
  return (
    <Suspense>
      <ChangePasswordClient />
    </Suspense>
  );
}
