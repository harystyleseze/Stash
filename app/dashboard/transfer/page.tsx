'use client'

import React, { ChangeEvent, FormEvent, useState } from 'react'
import { ArrowRight } from 'lucide-react'
import { BiCheckCircle } from 'react-icons/bi'
import { MdSend, MdVerified } from 'react-icons/md'

type FormData = {
    recipient: string
    amount: string
}

const P2P = () => {
    const [formData, setFormData] = useState<FormData>({
        recipient: '',
        amount: '',
    })

    const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target

        setFormData((prev) => ({
            ...prev,
            [name]: value,
        }))
    }

    const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
        e.preventDefault()

        console.log(formData)
    }

    return (
        <>
            <section className="transfer">
                <form onSubmit={handleSubmit}>
                    <h3>New Transfer</h3>

                    <div className="item">
                        <label htmlFor="receiver">Recipient</label>
                        <input
                            type="text"
                            name="recipient"
                            placeholder="Wallet Address"
                            value={formData.recipient}
                            onChange={handleChange}
                            required
                        />
                    </div>

                    <div className="balance">
                        <label htmlFor="amount">Amount (USDC)</label>
                        <div>
                            <span>Balance:</span>
                            <b>$535,000 USDC</b>
                        </div>
                    </div>

                    <div className="item item2">
                        <input
                            type="text"
                            name="amount"
                            placeholder="0.00"
                            value={formData.amount}
                            onChange={handleChange}
                            required
                        />
                        <div>
                            <button type="button">Max</button>
                            <span>USDC</span>
                        </div>
                    </div>

                    <div className="fee">
                        <div className="network">
                            <span>Network fee</span>
                            <span>0</span>
                        </div>

                        <div>
                            <span>Total to send</span>
                            <span>0</span>
                        </div>
                    </div>

                    <button type="submit">
                        <MdSend size={16} style={{ marginBottom: '-3px' }} />
                        Confirm transfer
                    </button>
                </form>

                <div className="txComplete">
                    <div className="finalized">
                        <div>
                            <p
                                style={{
                                    color: 'green',
                                    fontWeight: 600,
                                    margin: '10px 0',
                                }}
                            >
                                <MdVerified
                                    size={18}
                                    style={{
                                        marginRight: '10px',
                                        marginBottom: '-3px',
                                    }}
                                />
                                Transaction finalized
                            </p>

                            <div
                                style={{
                                    display: 'flex',
                                    flexDirection: 'row',
                                    justifyContent: 'space-between',
                                    width: '100%',
                                }}
                            >
                                <span style={{ width: '85%' }}>
                                    Your $10,000 has been successfully settled onchain via base.
                                </span>
                                <span style={{ width: '12%' }}>
                                    <BiCheckCircle size={30} />
                                </span>
                            </div>
                        </div>

                        <div className="view">
                            <button className="btnn1">View explorer</button>
                            <button className="btnn2">Download receipt</button>
                        </div>
                    </div>

                    <div className="s-about">
                        <p>
                            Stash is a non-custodial USDC savings app built on Base — no bank
                            account required, no counterparty holding your funds
                        </p>

                        <p style={{ fontWeight: 600, marginTop: '20px' }}>
                            +2k Active users
                        </p>
                    </div>
                </div>
            </section>
            {/* 
            <div>
                <h3>Recent recipients</h3>
                <div>
                    <div>
                        <div>
                            <p>halima@gmail.com</p>
                            <span>0x23312..re8</span>
                        </div>
                        <ArrowRight />

                    </div>
                </div>
            </div> */}
        </>
    )
}

export default P2P
