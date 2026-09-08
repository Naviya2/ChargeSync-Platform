const PATHS = {
  primary: 'M0,18 Q15,22 25,14 T50,8 T75,4 T100,6',
  secondary: 'M0,19 Q20,15 35,16 T60,6 T80,12 T100,10',
  outline: 'M0,22 L30,22 L35,10 L45,10 L50,22 L70,22 L75,6 L85,6 L90,22 L100,22',
}

/**
 * 24h utilization sparkline on a station card.
 * @param {{ tone?: 'text-primary'|'text-secondary'|'text-outline' }} props
 */
export default function StationSparkline({ tone = 'text-primary' }) {
  const key = tone.replace('text-', '')
  const line = PATHS[key] ?? PATHS.primary
  const area = `${line} L100,24 L0,24 Z`

  return (
    <div className="h-10 w-full">
      <svg className={`h-full w-full ${tone}`} viewBox="0 0 100 24" preserveAspectRatio="none">
        <path d={area} fill="currentColor" fillOpacity={key === 'outline' ? 0.08 : 0.12} />
        <path
          d={line}
          fill="none"
          stroke="currentColor"
          strokeWidth={key === 'outline' ? 1.6 : 1.8}
          strokeLinecap="round"
        />
      </svg>
    </div>
  )
}
