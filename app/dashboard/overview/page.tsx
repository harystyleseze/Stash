'use client';

import { ArrowLeftRightIcon, LockKeyhole, PlusIcon, TrendingUp } from 'lucide-react'
import { BsBank2 } from 'react-icons/bs'
import { FaArrowRightArrowLeft } from 'react-icons/fa6'
import { useRouter } from 'next/navigation'

const vaultCards = [
    {
        title: 'Flexible vault',
        tag: 'Auto compounding',
        balance: '535,000 USDC',
        firstLabel: 'Current Apy',
        firstValue: '4.5%',
        secondLabel: 'Withdrawal',
        secondValue: 'Instant',
        icon: <BsBank2 style={{ color: "#052321" }} size={14} />,
    },
    {
        title: 'Fixed vault',
        tag: '90 Days lock',
        balance: '15,000 USDC',
        firstLabel: 'Current Apy',
        firstValue: '4.5%',
        secondLabel: 'Next Unlock',
        secondValue: '12 days',
        icon: <LockKeyhole style={{ color: "#052321" }} size={14} />,
    },
    {
        title: 'Transfer rail',
        tag: 'Fast settlement',
        balance: '126 payouts',
        firstLabel: 'This week',
        firstValue: '18 sent',
        secondLabel: 'Settlement',
        secondValue: 'Near instant',
        icon: <ArrowLeftRightIcon style={{ color: "#052321" }} size={14} />,
    },
];

const Overview = () => {
    const router = useRouter()

    return (
        <section className='overview'>
            <div className="intro">
                <div className="overview-copy">
                    <h1>Institutional Overview</h1>
                    <p>Welcome back. With stash, Your assets are fully secured.</p>
                </div>
                <div className='btn'>
                    <button className='btn1'
                        onClick={() => { router.push('/dashboard/flexible') }
                        }
                    ><PlusIcon size={16} style={{ marginBottom: "-3px", marginRight: "6px" }} />Deposit</button>
                    <button className='btn2'
                        onClick={() => { router.push('/dashboard/transfer') }}
                    ><span><FaArrowRightArrowLeft size={16} style={{ marginBottom: "-3px", marginRight: "6px" }} /></span>Transfer</button>
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
                {vaultCards.map((card) => (
                    <div className='flxb-cont overview-card' key={card.title}>
                        <div className='flex'>
                            <div>
                                <span>{card.icon}</span>
                                <p>{card.title}</p>
                            </div>
                            <span className='overview-card-tag'>{card.tag}</span>
                        </div>
                        <span className='overview-card-label'>Active balance</span>
                        <h2>{card.balance}</h2>
                        <div className="apy">
                            <div>
                                <span>{card.firstLabel}</span>
                                <h2>{card.firstValue}</h2>
                            </div>
                            <div>
                                <span>{card.secondLabel}</span>
                                <h2>{card.secondValue}</h2>
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        </section>
    )
}
export default Overview
