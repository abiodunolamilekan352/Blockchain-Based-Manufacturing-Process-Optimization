;; Process Parameter Contract
;; Tracks production settings and parameters

(define-data-var admin principal tx-sender)

;; Data structure for process parameters
(define-map process-parameters
  {
    process-id: (string-ascii 32),
    version: uint
  }
  {
    name: (string-ascii 100),
    equipment-id: (string-ascii 32),
    created-at: uint,
    is-active: bool,
    parameters: (list 20 {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20),
      min: (string-ascii 20),
      max: (string-ascii 20)
    })
  }
)

;; Track current version for each process
(define-map process-versions
  { process-id: (string-ascii 32) }
  { current-version: uint }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Create a new process
(define-public (create-process
    (process-id (string-ascii 32))
    (name (string-ascii 100))
    (equipment-id (string-ascii 32))
    (parameters (list 20 {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20),
      min: (string-ascii 20),
      max: (string-ascii 20)
    }))
  )
  (begin
    (asserts! (is-admin) (err u403))
    (asserts! (is-none (map-get? process-versions { process-id: process-id })) (err u100))

    ;; Set initial version
    (map-set process-versions
      { process-id: process-id }
      { current-version: u1 }
    )

    ;; Create first version of the process
    (ok (map-set process-parameters
      {
        process-id: process-id,
        version: u1
      }
      {
        name: name,
        equipment-id: equipment-id,
        created-at: block-height,
        is-active: true,
        parameters: parameters
      }
    ))
  )
)

;; Update process parameters (creates a new version)
(define-public (update-process
    (process-id (string-ascii 32))
    (name (string-ascii 100))
    (equipment-id (string-ascii 32))
    (parameters (list 20 {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20),
      min: (string-ascii 20),
      max: (string-ascii 20)
    }))
  )
  (let (
    (version-data (unwrap! (map-get? process-versions { process-id: process-id }) (err u404)))
    (new-version (+ (get current-version version-data) u1))
  )
    (asserts! (is-admin) (err u403))

    ;; Deactivate previous version
    (match (map-get? process-parameters { process-id: process-id, version: (get current-version version-data) })
      prev-data (map-set process-parameters
        { process-id: process-id, version: (get current-version version-data) }
        (merge prev-data { is-active: false })
      )
      true
    )

    ;; Update version counter
    (map-set process-versions
      { process-id: process-id }
      { current-version: new-version }
    )

    ;; Create new version
    (ok (map-set process-parameters
      {
        process-id: process-id,
        version: new-version
      }
      {
        name: name,
        equipment-id: equipment-id,
        created-at: block-height,
        is-active: true,
        parameters: parameters
      }
    ))
  )
)

;; Get current active process parameters
(define-read-only (get-current-process (process-id (string-ascii 32)))
  (match (map-get? process-versions { process-id: process-id })
    version-data (map-get? process-parameters {
      process-id: process-id,
      version: (get current-version version-data)
    })
    none
  )
)

;; Get specific version of process parameters
(define-read-only (get-process-version
    (process-id (string-ascii 32))
    (version uint)
  )
  (map-get? process-parameters { process-id: process-id, version: version })
)

;; Get current version number
(define-read-only (get-process-version-number (process-id (string-ascii 32)))
  (match (map-get? process-versions { process-id: process-id })
    version-data (get current-version version-data)
    u0
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (ok (var-set admin new-admin))
  )
)
