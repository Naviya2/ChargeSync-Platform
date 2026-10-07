/** Shared with the startup shell in index.html; shown only while content loads. */
export default function BrandLoadingScreen() {
  return (
    <div className="brand-loading" role="status" aria-live="polite" aria-busy="true" aria-label="Loading ChargeSync">
      <div className="brand-loading__content">
        <div className="brand-loading__emblem" aria-hidden="true">
          <span className="brand-loading__orbit" />
          <img src={`${import.meta.env.BASE_URL}brand/chargesync-icon.png`} alt="" width="80" height="80" />
        </div>
        <div className="brand-loading__wordmark" aria-hidden="true">Charge<span>Sync</span></div>
        <div className="brand-loading__tagline" aria-hidden="true">Powering Tomorrow</div>
        <div className="brand-loading__track" aria-hidden="true"><span /></div>
        <p className="brand-loading__message">Loading your experience</p>
      </div>
      <span className="brand-loading__signature" aria-hidden="true">Connected. Charged. Ready.</span>
    </div>
  )
}
