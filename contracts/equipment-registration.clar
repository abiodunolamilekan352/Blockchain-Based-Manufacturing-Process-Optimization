;; Equipment Registration Contract
;; Records manufacturing assets and their specifications

(define-data-var admin principal tx-sender)

;; Data structure for equipment
(define-map equipment
  { equipment-id: (string-ascii 32) }
  {
    name: (string-ascii 100),
    type: (string-ascii 50),
    facility-id: (string-ascii 32),
    installation-date: uint,
    last-maintenance: uint,
    status: (string-ascii 20),
    specifications: (list 10 {
      key: (string-ascii 50),
      value: (string-ascii 50)
    })
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register new equipment
(define-public (register-equipment
    (equipment-id (string-ascii 32))
    (name (string-ascii 100))
    (type (string-ascii 50))
    (facility-id (string-ascii 32))
    (specifications (list 10 {
      key: (string-ascii 50),
      value: (string-ascii 50)
    }))
  )
  (begin
    (asserts! (is-admin) (err u403))
    (asserts! (is-none (map-get? equipment { equipment-id: equipment-id })) (err u100))
    (ok (map-set equipment
      { equipment-id: equipment-id }
      {
        name: name,
        type: type,
        facility-id: facility-id,
        installation-date: block-height,
        last-maintenance: block-height,
        status: "operational",
        specifications: specifications
      }
    ))
  )
)

;; Update equipment maintenance
(define-public (update-maintenance (equipment-id (string-ascii 32)))
  (let (
    (equip (unwrap! (map-get? equipment { equipment-id: equipment-id }) (err u404)))
  )
    (asserts! (is-admin) (err u403))
    (ok (map-set equipment
      { equipment-id: equipment-id }
      (merge equip {
        last-maintenance: block-height
      })
    ))
  )
)

;; Update equipment status
(define-public (update-status
    (equipment-id (string-ascii 32))
    (new-status (string-ascii 20))
  )
  (let (
    (equip (unwrap! (map-get? equipment { equipment-id: equipment-id }) (err u404)))
  )
    (asserts! (is-admin) (err u403))
    (ok (map-set equipment
      { equipment-id: equipment-id }
      (merge equip {
        status: new-status
      })
    ))
  )
)

;; Get equipment details
(define-read-only (get-equipment (equipment-id (string-ascii 32)))
  (map-get? equipment { equipment-id: equipment-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (ok (var-set admin new-admin))
  )
)
