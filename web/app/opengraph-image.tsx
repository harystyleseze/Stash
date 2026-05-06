import { ImageResponse } from 'next/og';

export const size = {
    width: 1200,
    height: 630,
};

export const contentType = 'image/png';

export default function Image() {
    return new ImageResponse(
        (
            <div
                style={{
                    background: '#2563EB',
                    width: '100%',
                    height: '100%',
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center',
                    alignItems: 'center',
                    color: 'white',
                    fontFamily: 'sans-serif',
                }}
            >
                <div
                    style={{
                        width: 120,
                        height: 120,
                        borderRadius: 32,
                        background: 'white',
                        marginBottom: 30,
                    }}
                />
                <h1 style={{ fontSize: 72, margin: 0 }}>Stash</h1>
                <p style={{ fontSize: 32, opacity: 0.9 }}>
                    Stablecoin banking
                </p>
            </div>
        ),
        size
    );
}