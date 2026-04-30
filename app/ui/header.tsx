'use client';

import { useEffect, useState } from "react";
import "./styles/layout.scss"
// import { AppKitButton, useAppKitAccount } from "@reown/appkit/react";
import { Moon, Sun, Menu, X } from "lucide-react";
import Link from "next/link";
// import "../ui/styles/layout.scss"

const Header = () => {

    const [theme, setTheme] = useState<'light' | 'dark'>(
        (localStorage.getItem('theme') as 'light' | 'dark') || 'dark'
    );
    const [isMenuOpen, setIsMenuOpen] = useState(false);

    useEffect(() => {
        document.body.className = theme === 'light' ? 'light-theme' : '';
        localStorage.setItem('theme', theme);
    }, [theme]);

    const toggleTheme = () => setTheme(prev => prev === 'light' ? 'dark' : 'light');
    const shortenAddress = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`;

    return (
        <>
            <header>


                <nav
                // style={!isMenuOpen? {display:"block"}:{display:"none"}}
                >
                    {/* <ul>
                        <li>
                            <Link
                                className={"nav-item"}
                                href={"/"}

                            >
                                Home
                            </Link>
                        </li>
                        <li>
                            <Link
                                className={"nav-item"}
                                href={"/dashboard"}

                            >
                                Dashboard
                            </Link>
                        </li>
                        <li>
                            <Link
                                className={"nav-item"}
                                href={"/market-place"}

                            >
                                Marketplace
                            </Link>
                        </li>
                    </ul> */}
                </nav>
                <p>Welcome back</p>
                <div className="header-actions" style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>

                    <button
                        className="btn btn-outline"
                    // onClick={toggleTheme}
                    // style={{ width: '40px', height: '40px', padding: 0, borderRadius: '50%' }}
                    >
                        {theme === 'light' ? <Sun size={18} /> : < Moon size={18} />}
                    </button>
                    <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                        <div className="wallet-badge" style={{ cursor: 'pointer' }} title="Click to disconnect">
                            <div className="indicator" />
                        </div>
                    </div>




                    <button className="mobile-toggle " onClick={() => setIsMenuOpen(!isMenuOpen)}>
                        {isMenuOpen ? <X size={24} /> : <Menu size={24} />}
                    </button>

                </div>
            </header>

        </>
    )
}

export default Header