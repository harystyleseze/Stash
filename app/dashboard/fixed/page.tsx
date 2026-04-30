"use client"
import React, { useState } from 'react';
import { AlertTriangle, ShieldCheck, Timer, Lock } from 'lucide-react';

const Fixed = () => {
    const [duration, setDuration] = useState(90);
    const [amount, setAmount] = useState(0);

    const handleSubmit = () => {
        console.log(duration, amount)
    }

    return (
        <section className="fixed-vault">
            <div className="header-card">
                <div className="header-info">
                    <h2>Institutional Yield</h2>
                    <p>Lock your USDC to secure guaranteed premium returns. Funds are protected by institutional-grade smart contracts with multi-sig security.</p>

                    <div className="stats-row">
                        <div className="stat">
                            <span>MAXIMUM APY</span>
                            <h3>12.50%</h3>
                        </div>
                        <div className="stat">
                            <span>TOTAL VAULT VALUE</span>
                            <h3>$4.2M</h3>
                        </div>
                    </div>
                </div>

                <div className="header-security">
                    <div className="security-badge">
                        <ShieldCheck size={18} className="icon-shield" />
                        <span>ON-CHAIN SECURE</span>
                    </div>
                    <p className="security-desc">The Fixed Savings Vault utilizes non-custodial smart contracts, audited by CertiK and OpenZeppelin.</p>

                    <div className="warning-box">
                        <AlertTriangle size={24} className="icon-alert" />
                        <p>No early withdrawals - enforced by smart contract. Ensure your liquidity needs are met before locking.</p>
                    </div>
                </div>
            </div>

            <div className="panels-container">
                <form className="lock-panel">
                    <h3>Lock USDC</h3>

                    <div className="amount-input">
                        <label>Amount to Lock</label>
                        <div className="input-wrapper">
                            <input type="number" placeholder="0.00" onChange={(e) => setAmount(Number(e.target.value))} />
                            <div className="input-suffix">
                                <span>USDC</span>
                                {/* <button className="max-btn" type='button'>MAX</button> */}
                            </div>
                        </div>
                        <span className="wallet-bal">Wallet Balance: 12,450.00 USDC</span>
                    </div>

                    <div className="duration-select">
                        <label>Select Duration</label>
                        <div className="duration-options">
                            <div className={`duration-card ${duration === 30 ? 'active' : ''}`} onClick={() => setDuration(30)}>
                                <h4>30 Days</h4>
                                <span>4.5%</span>
                            </div>
                            <div className={`duration-card ${duration === 60 ? 'active' : ''}`} onClick={() => setDuration(60)}>
                                <h4>60 Days</h4>
                                <span>8.2%</span>
                            </div>
                            <div className={`duration-card ${duration === 90 ? 'active' : ''}`} onClick={() => setDuration(90)}>
                                <h4>90 Days</h4>
                                <span>12.5%</span>
                            </div>
                        </div>
                    </div>

                    <div className="summary">
                        <div className="summary-row">
                            <span>Maturity Date</span>
                            <b>Oct 14, 2024</b>
                        </div>
                        <div className="summary-row">
                            <span>Estimated Yield</span>
                            <b className="yield-val">+ 41.20 USDC</b>
                        </div>
                    </div>

                    <button type="button" className="lock-btn" onClick={() => handleSubmit()}>Lock USDC</button>
                </form>

                <div className="positions-panel">
                    <div className="panel-header">
                        <h3>Active Positions</h3>
                        <span className="badge">2 Stakes Active</span>
                    </div>

                    <div className="position-list">
                        <div className="position-card">
                            <div className="pos-icon">
                                <Timer size={20} />
                            </div>
                            <div className="pos-details">
                                <div className="pos-amount">
                                    <h4>5,000.00 USDC</h4>
                                    <p>Locked for 60 Days • <span className="apy-green">8.2% APY</span></p>
                                </div>
                                <div className="pos-maturity">
                                    <h4 className="maturity-blue">14d : 22h : 15m</h4>
                                    <p>Maturity: Aug 28, 2024</p>
                                </div>
                            </div>
                        </div>

                        <div className="position-card">
                            <div className="pos-icon lock-icon">
                                <Lock size={20} />
                            </div>
                            <div className="pos-details">
                                <div className="pos-amount">
                                    <h4>12,500.00 USDC</h4>
                                    <p>Locked for 90 Days • <span className="apy-green">12.5% APY</span></p>
                                </div>
                                <div className="pos-maturity">
                                    <h4 className="maturity-blue">78d : 04h : 32m</h4>
                                    <p>Maturity: Oct 31, 2024</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    );
};

export default Fixed;