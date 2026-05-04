'use client';

import { useWallet } from '@/app/context/WalletContext';
import { shortenAddress } from '@/lib/format';

type Variant = 'badge' | 'primary' | 'inline';

export function ConnectButton({
  label = 'Connect wallet',
  variant = 'badge',
}: {
  label?: string;
  variant?: Variant;
}) {
  const { address, isConnected, isConnecting, isWrongNetwork, connect, disconnect, switchToBaseSepolia, hasInjectedWallet } =
    useWallet();

  if (isConnecting) {
    return (
      <button type="button" className={`connect-btn connect-btn-${variant}`} disabled>
        <span className="connect-btn-spinner" />
        Connecting...
      </button>
    );
  }

  if (isConnected && address) {
    if (isWrongNetwork) {
      return (
        <button
          type="button"
          className="connect-btn connect-btn-warn"
          onClick={() => switchToBaseSepolia()}
          title="Switch to Base Sepolia"
        >
          <span className="indicator" data-warning />
          Wrong network
        </button>
      );
    }

    return (
      <div className="connect-cluster">
        <span className="wallet-badge wallet-badge-connected" title={address}>
          <span className="indicator" />
          {shortenAddress(address)}
        </span>
        <button type="button" className="connect-btn connect-btn-ghost" onClick={disconnect}>
          Disconnect
        </button>
      </div>
    );
  }

  const buttonLabel = !hasInjectedWallet ? 'Install wallet' : label;

  return (
    <button
      type="button"
      className={`connect-btn connect-btn-${variant}`}
      onClick={() => connect()}
    >
      {buttonLabel}
    </button>
  );
}
