import { ArrowLeftRightIcon, ArrowUpRightSquareIcon, LockKeyhole, PlusIcon, TrendingUp } from 'lucide-react'
import React from 'react'
import { BsBank2 } from 'react-icons/bs'
import { FaArrowRightArrowLeft } from 'react-icons/fa6'
import { GiPadlock } from 'react-icons/gi'

const Overview = () => {
    return (
        // <div>Overview</div>
        <section className='overview'>
            <div className="intro">
                <div>
                    <h1>Institutional Overview</h1>
                    <p>Welcome back. With stash, Your assets are fully secured.</p>
                </div>
                <div className='btn'>
                    <button className='btn1'><span><PlusIcon size={14} /></span> Deposit</button>
                    <button className='btn2'><span><FaArrowRightArrowLeft size={14} /></span>Transfer</button>
                </div>
            </div>

            <div className="net">
                <div className="balCont">
                    <div className="balL">
                        <div className='bal'>
                            <b>Total Net worth</b>
                            <div className='totalBal'>
                                <h2>$10 </h2>
                                <span>USDC</span>
                            </div>
                        </div>
                        <span className='trend'><TrendingUp size={14} /> +4.2% (24h)</span>
                    </div>
                    <div className="chart"></div>
                </div>
                <div className='Ayield'>
                    <b>Accrued yield</b>
                    <h3>+$5432.57</h3>
                    <span style={{ fontSize: "14px", color: "#3e3d3d" }}>Yield gnerated this month</span>

                    <button className="yield-an">Yield Analytic</button>
                </div>
            </div>
            <div className="cont">
                <div className='flxb-cont'>
                    <div className='flex'>
                        <div>
                            <span><BsBank2 style={{ color: "#052321" }} size={14} /></span>
                            <p>Flexible vault</p>
                        </div>
                        <span style={{ color: "#052321", borderRadius: "20px", padding: "0 6px", backgroundColor: "rgba(8, 84, 78,0.3)" }}>Auto compounding</span>
                    </div>
                    {/* <div> */}
                    <span>Active balance</span>
                    <h2>535,000 USDC</h2>
                    <div className="apy">
                        <div>
                            <span>Current Apy</span>
                            <h2>4.5%</h2>
                        </div>
                        <div>
                            <span>Withdrawal</span>
                            <h2>Instant</h2>
                        </div>
                    </div>
                    {/* </div> */}
                </div>

                {/* fixed */}
                <div className='flxb-cont'>
                    <div className='flex'>
                        <div>
                            <span><LockKeyhole style={{ color: "#052321" }} size={14} /></span>
                            <p>Fixed vault</p>
                        </div>
                        <span style={{ color: "#052321", borderRadius: "20px", padding: "0 6px", backgroundColor: "rgba(8, 84, 78,0.3)" }}>90 Days lock</span>
                    </div>
                    {/* <div> */}
                    <span>Active balance</span>
                    <h2>15000 USDC</h2>
                    <div className="apy">
                        <div>
                            <span>Current Apy</span>
                            <h2>4.5%</h2>
                        </div>
                        <div>
                            <span>Next Unlock</span>
                            <h2>12 days</h2>
                        </div>
                    </div>
                    {/* </div> */}
                </div>

                <div className='flxb-cont'>

                </div>
                <div></div>

            </div>
        </section>
    )
}
export default Overview