'use client';

import { BrowserProvider, JsonRpcSigner } from 'ethers';
import {
  ReactNode,
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import { BASE_SEPOLIA_CHAIN_ID_HEX, BASE_SEPOLIA_CHAIN_ID } from '@/lib/contracts';

const STORAGE_KEY = 'stash_connected';

type EthereumRequestArguments = {
  method: string;
  params?: unknown[];
};

type EthereumEvent = 'accountsChanged' | 'chainChanged' | 'disconnect';
type EthereumListener = (...args: unknown[]) => void;

type EthereumProvider = {
  request: (args: EthereumRequestArguments) => Promise<unknown>;
  on: (event: EthereumEvent, listener: EthereumListener) => void;
  removeListener?: (event: EthereumEvent, listener: EthereumListener) => void;
  isMetaMask?: boolean;
};

declare global {
  interface Window {
    ethereum?: EthereumProvider;
  }
}

type ProviderError = {
  code?: number;
};

const isProviderError = (error: unknown): error is ProviderError =>
  typeof error === 'object' && error !== null && 'code' in error;

interface WalletContextType {
  address: string | null;
  signer: JsonRpcSigner | null;
  provider: BrowserProvider | null;
  isConnected: boolean;
  isConnecting: boolean;
  isWrongNetwork: boolean;
  chainId: string | null;
  hasInjectedWallet: boolean;
  connect: () => Promise<void>;
  disconnect: () => void;
  switchToBaseSepolia: () => Promise<void>;
}

const defaultContext: WalletContextType = {
  address: null,
  signer: null,
  provider: null,
  isConnected: false,
  isConnecting: false,
  isWrongNetwork: false,
  chainId: null,
  hasInjectedWallet: false,
  connect: async () => {},
  disconnect: () => {},
  switchToBaseSepolia: async () => {},
};

const WalletContext = createContext<WalletContextType>(defaultContext);

export function WalletProvider({ children }: { children: ReactNode }) {
  const [address, setAddress] = useState<string | null>(null);
  const [signer, setSigner] = useState<JsonRpcSigner | null>(null);
  const [provider, setProvider] = useState<BrowserProvider | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [chainId, setChainId] = useState<string | null>(null);
  const [hasInjectedWallet, setHasInjectedWallet] = useState(false);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setHasInjectedWallet(typeof window !== 'undefined' && !!window.ethereum);
  }, []);

  const switchToBaseSepolia = useCallback(async () => {
    const ethereum = window.ethereum;
    if (!ethereum) return;

    try {
      await ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: BASE_SEPOLIA_CHAIN_ID_HEX }],
      });
    } catch (error: unknown) {
      // 4902 = chain not added in wallet — request to add it.
      if (isProviderError(error) && error.code === 4902) {
        await ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [
            {
              chainId: BASE_SEPOLIA_CHAIN_ID_HEX,
              chainName: 'Base Sepolia',
              nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 },
              rpcUrls: ['https://sepolia.base.org'],
              blockExplorerUrls: ['https://sepolia.basescan.org'],
            },
          ],
        });
      } else {
        throw error;
      }
    }
  }, []);

  const refreshFromProvider = useCallback(async () => {
    const ethereum = window.ethereum;
    if (!ethereum) return;

    const nextProvider = new BrowserProvider(ethereum);
    const accounts = (await nextProvider.send('eth_accounts', [])) as string[];
    if (!accounts || accounts.length === 0) {
      setProvider(null);
      setSigner(null);
      setAddress(null);
      setChainId(null);
      return;
    }

    const nextSigner = await nextProvider.getSigner();
    const nextAddress = await nextSigner.getAddress();
    const network = await nextProvider.getNetwork();
    const nextChainId = `0x${network.chainId.toString(16)}`;

    setProvider(nextProvider);
    setSigner(nextSigner);
    setAddress(nextAddress);
    setChainId(nextChainId);
  }, []);

  const connect = useCallback(async () => {
    const ethereum = window.ethereum;

    if (!ethereum) {
      window.open('https://metamask.io/download/', '_blank', 'noopener,noreferrer');
      return;
    }

    setIsConnecting(true);

    try {
      const nextProvider = new BrowserProvider(ethereum);
      await nextProvider.send('eth_requestAccounts', []);

      const nextSigner = await nextProvider.getSigner();
      const nextAddress = await nextSigner.getAddress();
      const network = await nextProvider.getNetwork();
      const nextChainId = `0x${network.chainId.toString(16)}`;

      setProvider(nextProvider);
      setSigner(nextSigner);
      setAddress(nextAddress);
      setChainId(nextChainId);

      if (nextChainId !== BASE_SEPOLIA_CHAIN_ID_HEX) {
        try {
          await switchToBaseSepolia();
          // Refresh after the wallet emits chainChanged
        } catch {
          // user may decline — keep partially-connected state with isWrongNetwork true
        }
      }

      window.localStorage.setItem(STORAGE_KEY, 'true');
    } catch (error) {
      console.error('Connection failed:', error);
    } finally {
      setIsConnecting(false);
    }
  }, [switchToBaseSepolia]);

  const disconnect = useCallback(() => {
    setAddress(null);
    setSigner(null);
    setProvider(null);
    setChainId(null);
    window.localStorage.removeItem(STORAGE_KEY);
  }, []);

  // Auto-reconnect on mount + listen for wallet events
  useEffect(() => {
    const ethereum = window.ethereum;
    if (!ethereum) return;

    const reconnectTimer = window.setTimeout(() => {
      if (window.localStorage.getItem(STORAGE_KEY) === 'true') {
        void refreshFromProvider();
      }
    }, 0);

    const handleAccountsChanged: EthereumListener = (accounts) => {
      if (!Array.isArray(accounts) || accounts.length === 0) {
        disconnect();
        return;
      }
      void refreshFromProvider();
    };

    const handleChainChanged: EthereumListener = () => {
      void refreshFromProvider();
    };

    ethereum.on('accountsChanged', handleAccountsChanged);
    ethereum.on('chainChanged', handleChainChanged);

    return () => {
      window.clearTimeout(reconnectTimer);
      ethereum.removeListener?.('accountsChanged', handleAccountsChanged);
      ethereum.removeListener?.('chainChanged', handleChainChanged);
    };
  }, [refreshFromProvider, disconnect]);

  const isWrongNetwork = useMemo(() => {
    if (!chainId) return false;
    try {
      return parseInt(chainId, 16) !== BASE_SEPOLIA_CHAIN_ID;
    } catch {
      return true;
    }
  }, [chainId]);

  const value = useMemo<WalletContextType>(
    () => ({
      address,
      signer,
      provider,
      isConnected: Boolean(address),
      isConnecting,
      isWrongNetwork,
      chainId,
      hasInjectedWallet,
      connect,
      disconnect,
      switchToBaseSepolia,
    }),
    [
      address,
      signer,
      provider,
      isConnecting,
      isWrongNetwork,
      chainId,
      hasInjectedWallet,
      connect,
      disconnect,
      switchToBaseSepolia,
    ],
  );

  return <WalletContext.Provider value={value}>{children}</WalletContext.Provider>;
}

export const useWallet = () => useContext(WalletContext);
