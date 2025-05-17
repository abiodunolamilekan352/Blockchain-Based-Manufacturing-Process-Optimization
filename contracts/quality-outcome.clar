;; Quality Outcome Contract
;; Records product specifications and quality metrics

(define-data-var admin principal tx-sender)

;; Data structure for quality outcomes
(define-map quality-outcomes
  { batch-id: (string-ascii 32) }
  {
    process-id: (string-ascii 32),
    process-version: uint,
    production-date: uint,
    metrics: (list 20 {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20),
      target: (string-ascii 20),
      tolerance: (string-ascii 20)
    }),
    passed-quality: bool,
    inspector: principal
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Record quality outcome for a batch
(define-public (record-quality
    (batch-id (string-ascii 32))
    (process-id (string-ascii 32))
    (process-version uint)
    (metrics (list 20 {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20),
      target: (string-ascii 20),
      tolerance: (string-ascii 20)
    }))
    (passed-quality bool)
  )
  (begin
    (asserts! (is-admin) (err u403))
    (asserts! (is-none (map-get? quality-outcomes { batch-id: batch-id })) (err u100))
    (ok (map-set quality-outcomes
      { batch-id: batch-id }
      {
        process-id: process-id,
        process-version: process-version,
        production-date: block-height,
        metrics: metrics,
        passed-quality: passed-quality,
        inspector: tx-sender
      }
    ))
  )
)

;; Update quality status
(define-public (update-quality-status
    (batch-id (string-ascii 32))
    (passed-quality bool)
  )
  (let (
    (quality-data (unwrap! (map-get? quality-outcomes { batch-id: batch-id }) (err u404)))
  )
    (asserts! (is-admin) (err u403))
    (ok (map-set quality-outcomes
      { batch-id: batch-id }
      (merge quality-data {
        passed-quality: passed-quality,
        inspector: tx-sender
      })
    ))
  )
)

;; Get quality outcome for a batch
(define-read-only (get-quality-outcome (batch-id (string-ascii 32)))
  (map-get? quality-outcomes { batch-id: batch-id })
)

;; Check if batch passed quality check
(define-read-only (has-passed-quality (batch-id (string-ascii 32)))
  (default-to false (get passed-quality (map-get? quality-outcomes { batch-id: batch-id })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (ok (var-set admin new-admin))
  )
)
