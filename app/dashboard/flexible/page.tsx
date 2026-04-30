import React from 'react'
import { ChevronDown, TrendingUp, ArrowUpRight, ArrowDownLeft } from 'lucide-react'
import '../../ui/styles/flexible.css'

const Flexible = () => {
    return (
        <section className='flexible-section'>
            {/* Header */}
            <div className='flexible-header'>
                <div className='header-content'>
                    <h1 className='header-title'>Flexible Savings Vault</h1>
                    <p className='header-subtitle'>Optimize your idle capital with our institutional-grade liquid wrapper, withdraw any time with zero slippage.</p>
                </div>
                <div className='apy-display'>
                    <span className='apy-label'>CURRENT APY</span>
                    <div className='apy-value'>
                        <span className='apy-percentage'>8.42%</span>
                        <TrendingUp size={20} className='apy-arrow' />
                    </div>
                </div>
            </div>

            {/* Summary Card */}
            <div className='summary-card'>
                <div className='summary-item'>
                    <span className='summary-label'>TOTAL STAKED</span>
                    <p className='summary-value'>$42,850.00</p>
                </div>
                <div className='summary-item'>
                    <span className='summary-label'>CURRENT APY</span>
                    <p className='summary-value positive'>5.42%</p>
                </div>
            </div>

            {/* Action Buttons */}
            <div className='action-buttons'>
                <button className='btn-primary'>Deposit</button>
                <button className='btn-secondary'>Withdraw</button>
            </div>

            {/* Main Content */}
            <div className='flexible-content'>
                {/* Left Section - Input and Balance */}
                <div className='left-section'>
                    {/* Select Asset */}
                    <div className='select-asset-group'>
                        <label className='form-label'>Select Asset</label>
                        <div className='select-dropdown'>
                            <div className='asset-selected'>
                                <div className='asset-icon'>◎</div>
                                <span>USDC</span>
                            </div>
                            <ChevronDown size={18} />
                        </div>
                    </div>

                    {/* Amount Input */}
                    <div className='amount-group'>
                        <label className='form-label'>Amount</label>
                        <div className='amount-input-group'>
                            <input
                                type='text'
                                className='amount-input'
                                placeholder='0.00'
                            />
                            <button className='max-button'>Max</button>
                        </div>
                        <div className='max-display'>
                            Wallet: <span>42,450.00</span>
                        </div>
                    </div>

                    {/* Your Total Balance */}
                    <div className='balance-card'>
                        <label className='balance-label'>YOUR TOTAL BALANCE</label>
                        <div className='balance-amount'>5,250.32 USDC</div>
                    </div>

                    {/* Yield and Share Price */}
                    <div className='stats-grid'>
                        <div className='stat-card'>
                            <span className='stat-label'>TOTAL YIELD EARNED</span>
                            <h3 className='stat-value'>+$1,452.12</h3>
                        </div>
                        <div className='stat-card'>
                            <span className='stat-label'>SHARE PRICE</span>
                            <h3 className='stat-value'>1,084 sUJSDC</h3>
                        </div>
                    </div>

                    {/* Confirm Deposit Button */}
                    <button className='btn-confirm-deposit'>Confirm Deposit</button>
                </div>

                {/* Right Section - Info Cards */}
                <div className='right-section'>
                    <div className='info-card'>
                        <div className='info-row'>
                            <span className='info-label'>Vault token accrued</span>
                            <span className='info-value'>+0.80 sUJSDC</span>
                        </div>
                        <div className='info-row'>
                            <span className='info-label'>APR + daily compounding</span>
                            <span className='info-value'>4.40%</span>
                        </div>
                    </div>

                    <div className='info-card'>
                        <div className='info-row'>
                            <span className='info-label'>Vault stake contract</span>
                            <span className='info-value contract'>8x8z</span>
                        </div>
                        <div className='info-row'>
                            <span className='info-label'>Vault contract</span>
                            <span className='info-value contract'>Ax8</span>
                        </div>
                    </div>
                </div>
            </div>

            {/* Recent Transactions */}
            <div className='recent-transactions'>
                <div className='transactions-header'>
                    <h2>Recent Transactions</h2>
                    <a href='#' className='export-link'>See All</a>
                </div>

                <div className='transactions-table'>
                    <table>
                        <thead>
                            <tr>
                                <th>TYPE</th>
                                <th>AMO + PNK</th>
                                <th>sXAU+ aXAU/S +b</th>
                                <th>+Blamy</th>
                                <th>VALUE</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>
                                    <span className='tx-type deposit'>
                                        <ArrowDownLeft size={14} /> Deposit
                                    </span>
                                </td>
                                <td>5 + 4333</td>
                                <td>100000</td>
                                <td>2h ago</td>
                                <td><span className='tx-value positive'>+5000</span></td>
                            </tr>
                            <tr>
                                <td>
                                    <span className='tx-type withdraw'>
                                        <ArrowUpRight size={14} /> Withdraw
                                    </span>
                                </td>
                                <td>- 1,000.00 USDC</td>
                                <td>USDT - 0000</td>
                                <td>1d ago</td>
                                <td><span className='tx-value'>-1600 null</span></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>
    )
}
export default Flexible