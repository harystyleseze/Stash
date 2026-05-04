'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useWallet } from '@/app/context/WalletContext';

export function AutoRedirectOnConnect({ to }: { to: string }) {
  const router = useRouter();
  const { isConnected } = useWallet();

  useEffect(() => {
    if (isConnected) router.push(to);
  }, [isConnected, router, to]);

  return null;
}
