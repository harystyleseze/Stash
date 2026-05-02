"use client";

import { useState } from "react";
import Link from "next/link";
import { Menu, X } from "lucide-react";
import styles from "../page.module.css";

export default function LandingHeader() {
    const [isOpen, setIsOpen] = useState(false);

    return (
        <header className={styles.navbar}>
            <Link href="/" className={styles.brand}>
                <span className={styles.brandMark}>S</span>
                <span>stash</span>
            </Link>

            <button
                className={styles.mobileMenuToggle}
                onClick={() => setIsOpen(!isOpen)}
                aria-label="Toggle menu"
            >
                {isOpen ? <X size={24} /> : <Menu size={24} />}
            </button>

            <div className={`${styles.navActions} ${isOpen ? styles.navActionsOpen : ''}`}>
                <Link href="/dashboard/overview" className={styles.navLink} onClick={() => setIsOpen(false)}>
                    Dashboard
                </Link>
                <Link href="/dashboard/flexible" className={styles.navButton} onClick={() => setIsOpen(false)}>
                    Start saving
                </Link>
            </div>

            {isOpen && (
                <div className={styles.mobileOverlay} onClick={() => setIsOpen(false)} />
            )}
        </header>
    );
}
