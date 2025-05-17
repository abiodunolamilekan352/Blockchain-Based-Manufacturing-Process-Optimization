;; Facility Verification Contract
;; Validates production sites and their capabilities

(define-data-var admin principal tx-sender)

;; Data structure for facilities
(define-map facilities
  { facility-id: (string-ascii 32) }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    verified: bool,
    verification-date: uint,
    capabilities: (list 10 (string-ascii 50))
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new facility
(define-public (register-facility
    (facility-id (string-ascii 32))
    (name (string-ascii 100))
    (location (string-ascii 100))
    (capabilities (list 10 (string-ascii 50)))
  )
  (begin
    (asserts! (is-admin) (err u403))
    (asserts! (is-none (map-get? facilities { facility-id: facility-id })) (err u100))
    (ok (map-set facilities
      { facility-id: facility-id }
      {
        name: name,
        location: location,
        verified: false,
        verification-date: u0,
        capabilities: capabilities
      }
    ))
  )
)

;; Verify a facility
(define-public (verify-facility (facility-id (string-ascii 32)))
  (let (
    (facility (unwrap! (map-get? facilities { facility-id: facility-id }) (err u404)))
  )
    (asserts! (is-admin) (err u403))
    (ok (map-set facilities
      { facility-id: facility-id }
      (merge facility {
        verified: true,
        verification-date: block-height
      })
    ))
  )
)

;; Get facility details
(define-read-only (get-facility (facility-id (string-ascii 32)))
  (map-get? facilities { facility-id: facility-id })
)

;; Check if facility is verified
(define-read-only (is-facility-verified (facility-id (string-ascii 32)))
  (default-to false (get verified (map-get? facilities { facility-id: facility-id })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (ok (var-set admin new-admin))
  )
)
