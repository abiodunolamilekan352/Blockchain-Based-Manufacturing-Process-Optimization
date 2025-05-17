;; Optimization Contract
;; Manages continuous improvement and process optimization

(define-data-var admin principal tx-sender)

;; Data structure for optimization proposals
(define-map optimization-proposals
  { proposal-id: (string-ascii 32) }
  {
    process-id: (string-ascii 32),
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposed-by: principal,
    proposed-at: uint,
    status: (string-ascii 20),
    votes: uint,
    implemented: bool,
    implementation-date: uint,
    expected-improvements: (list 10 {
      metric: (string-ascii 50),
      current: (string-ascii 20),
      target: (string-ascii 20),
      unit: (string-ascii 20)
    })
  }
)

;; Track votes on proposals
(define-map proposal-votes
  {
    proposal-id: (string-ascii 32),
    voter: principal
  }
  { voted: bool }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Create a new optimization proposal
(define-public (create-proposal
    (proposal-id (string-ascii 32))
    (process-id (string-ascii 32))
    (title (string-ascii 100))
    (description (string-ascii 500))
    (expected-improvements (list 10 {
      metric: (string-ascii 50),
      current: (string-ascii 20),
      target: (string-ascii 20),
      unit: (string-ascii 20)
    }))
  )
  (begin
    (asserts! (is-none (map-get? optimization-proposals { proposal-id: proposal-id })) (err u100))
    (ok (map-set optimization-proposals
      { proposal-id: proposal-id }
      {
        process-id: process-id,
        title: title,
        description: description,
        proposed-by: tx-sender,
        proposed-at: block-height,
        status: "pending",
        votes: u0,
        implemented: false,
        implementation-date: u0,
        expected-improvements: expected-improvements
      }
    ))
  )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id (string-ascii 32)))
  (let (
    (proposal (unwrap! (map-get? optimization-proposals { proposal-id: proposal-id }) (err u404)))
    (has-voted (default-to { voted: false } (map-get? proposal-votes { proposal-id: proposal-id, voter: tx-sender })))
  )
    (asserts! (not (get voted has-voted)) (err u401))
    (asserts! (is-eq (get status proposal) "pending") (err u403))

    ;; Record the vote
    (map-set proposal-votes
      { proposal-id: proposal-id, voter: tx-sender }
      { voted: true }
    )

    ;; Update vote count
    (ok (map-set optimization-proposals
      { proposal-id: proposal-id }
      (merge proposal {
        votes: (+ (get votes proposal) u1)
      })
    ))
  )
)

;; Approve a proposal (admin only)
(define-public (approve-proposal (proposal-id (string-ascii 32)))
  (let (
    (proposal (unwrap! (map-get? optimization-proposals { proposal-id: proposal-id }) (err u404)))
  )
    (asserts! (is-admin) (err u403))
    (asserts! (is-eq (get status proposal) "pending") (err u400))

    (ok (map-set optimization-proposals
      { proposal-id: proposal-id }
      (merge proposal {
        status: "approved"
      })
    ))
  )
)

;; Reject a proposal (admin only)
(define-public (reject-proposal (proposal-id (string-ascii 32)))
  (let (
    (proposal (unwrap! (map-get? optimization-proposals { proposal-id: proposal-id }) (err u404)))
  )
    (asserts! (is-admin) (err u403))
    (asserts! (is-eq (get status proposal) "pending") (err u400))

    (ok (map-set optimization-proposals
      { proposal-id: proposal-id }
      (merge proposal {
        status: "rejected"
      })
    ))
  )
)

;; Mark proposal as implemented (admin only)
(define-public (implement-proposal (proposal-id (string-ascii 32)))
  (let (
    (proposal (unwrap! (map-get? optimization-proposals { proposal-id: proposal-id }) (err u404)))
  )
    (asserts! (is-admin) (err u403))
    (asserts! (is-eq (get status proposal) "approved") (err u400))

    (ok (map-set optimization-proposals
      { proposal-id: proposal-id }
      (merge proposal {
        status: "implemented",
        implemented: true,
        implementation-date: block-height
      })
    ))
  )
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id (string-ascii 32)))
  (map-get? optimization-proposals { proposal-id: proposal-id })
)

;; Check if user has voted on a proposal
(define-read-only (has-voted
    (proposal-id (string-ascii 32))
    (voter principal)
  )
  (default-to false (get voted (map-get? proposal-votes { proposal-id: proposal-id, voter: voter })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (ok (var-set admin new-admin))
  )
)
